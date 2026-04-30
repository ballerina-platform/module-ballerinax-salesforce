// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/jballerina.java;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/uuid;

// ---------------------------------------------------------------------------
// Leadership state constants
// ---------------------------------------------------------------------------

// "init"    – constructed, `'start()` not yet called
const string LEADER_STATE_INIT = "init";
// "standby" – loop running; this replica does NOT hold the CometD subscription
const string LEADER_STATE_STANDBY = "standby";
// "leader"  – this replica holds the CometD subscription open
const string LEADER_STATE_LEADER = "leader";
// "stopped" – `gracefulStop()`/`immediateStop()` called; loop exits on next tick
const string LEADER_STATE_STOPPED = "stopped";

// ---------------------------------------------------------------------------
// CometdStateManager — Active-Standby leadership state machine
// ---------------------------------------------------------------------------

# Owns the Active-Standby leadership loop for a single Salesforce Streaming
# API subscription. Decoupled from `Listener` so the Listener class itself
# remains a thin registration and delegation shell.
#
# All mutable state is guarded by `lock` blocks; the class is safe to use
# from multiple concurrent strands.
#
# Lifecycle (OAuth2 path):
#   init → setGroupId(channel) → activate(listenerInstance)
#       ↓ leadership loop (on dedicated strand)
#   INIT → STANDBY → (lease acquired) → LEADER ←→ (renewal) → LEADER
#                                       ↓ (lease lost)
#                                    STANDBY → …
#       ↓ gracefulStop / immediateStop
#   STOPPED (loop exits)
isolated class CometdStateManager {

    private final ListenerCoordinator coordinator;
    # Per-process unique identity. UUID v4 so restarted replicas do NOT
    # inherit the prior run's lease.
    private final string nodeId;
    # Coordination group — set to the channel name once `attach()` calls
    # `setGroupId()`. Defaults to `nodeId` as a safe placeholder.
    private string groupId;
    private final decimal livenessInterval;
    private final decimal heartbeatInterval;
    private string leadershipState = LEADER_STATE_INIT;

    isolated function init(ListenerCoordinator coordinator,
            decimal livenessInterval, decimal heartbeatInterval) {
        self.coordinator = coordinator;
        self.nodeId = uuid:createType4AsString();
        self.groupId = self.nodeId; // overridden by setGroupId() from attach()
        self.livenessInterval = livenessInterval;
        self.heartbeatInterval = heartbeatInterval;
    }

    # Binds this state manager to a CometD channel name. Called from
    # `Listener.attach()` once the channel is known. All replicas listening
    # on the same channel share a groupId, so leader-election is per-channel.
    #
    # + groupId - Fully-qualified Salesforce channel (e.g. `/event/Foo__e`)
    public isolated function setGroupId(string groupId) {
        lock {
            self.groupId = groupId;
        }
    }

    # Transitions to STANDBY and forks the leadership loop strand.
    # Returns immediately — the loop runs asynchronously for the lifetime
    # of the listener.
    #
    # Named `activate` rather than `start` because `start` is a reserved
    # keyword in Ballerina.
    #
    # + listenerInstance - The owning `Listener` instance (passed through to
    #                      CometD lifecycle calls inside the loop)
    public isolated function activate(Listener listenerInstance) {
        lock {
            self.leadershipState = LEADER_STATE_STANDBY;
        }
        // Fork the leadership loop. We do NOT wait for the future —
        // `'start()` must return so listener registration completes.
        future<()> _ = start self.leadershipLoop(listenerInstance);
    }

    # Signals the leadership loop to stop, then tears down CometD if this
    # replica held the subscription. Safe to call from any strand.
    #
    # + listenerInstance - The owning `Listener` instance
    # + return - `()` or an error from the underlying `stopListener` call
    public isolated function gracefulStop(Listener listenerInstance) returns error? {
        boolean wasLeader;
        lock {
            wasLeader = self.leadershipState == LEADER_STATE_LEADER;
            self.leadershipState = LEADER_STATE_STOPPED;
        }
        if !wasLeader {
            log:printDebug("CometD state manager stopped (was standby or init)",
                    nodeId = self.nodeId);
            return;
        }
        error? result = stopListener(listenerInstance);
        log:printDebug("CometD state manager stopped (was leader)", nodeId = self.nodeId);
        return result;
    }

    # Immediately stops the CometD subscription (if held) without waiting
    # for in-flight events to drain.
    #
    # + listenerInstance - The owning `Listener` instance
    # + return - `()` or an error from the underlying `stopListener` call
    public isolated function immediateStop(Listener listenerInstance) returns error? {
        boolean wasLeader;
        lock {
            wasLeader = self.leadershipState == LEADER_STATE_LEADER;
            self.leadershipState = LEADER_STATE_STOPPED;
        }
        if !wasLeader {
            return;
        }
        return stopListener(listenerInstance);
    }

    # Re-enters the leadership state machine after a stop or connection drop.
    # If the loop is already running (state ≠ STOPPED), this is a no-op —
    # the existing loop will continue competing for the lease.
    #
    # + listenerInstance - The owning `Listener` instance
    public isolated function reconnect(Listener listenerInstance) {
        boolean restartLoop;
        lock {
            restartLoop = self.leadershipState == LEADER_STATE_STOPPED;
            self.leadershipState = LEADER_STATE_STANDBY;
        }
        if restartLoop {
            // The previous loop exited on STOPPED; fork a fresh one.
            future<()> _ = start self.leadershipLoop(listenerInstance);
        }
    }

    # Persists the latest successfully-dispatched `replayId`. Called by
    # `Listener.recordEventDispatched()`, which is invoked from the Java
    # dispatcher after each successful user-handler execution.
    #
    # Errors are swallowed — a failed checkpoint write must never disrupt
    # event dispatch. The worst outcome is that a failover replica
    # re-delivers a handful of recent events, which is consistent with
    # Salesforce's at-least-once delivery guarantee.
    #
    # + channel - Fully-qualified Salesforce channel name
    # + replayId - The Salesforce-issued, monotonically increasing replay ID
    public isolated function saveCheckpoint(string channel, int replayId) {
        error? saved = self.coordinator.saveCheckpoint(channel, replayId);
        if saved is error {
            log:printWarn("Failed to persist replayId checkpoint; a failover " +
                    "replica may re-deliver recent events",
                    channel = channel, replayId = replayId, 'error = saved);
        }
    }

    // -----------------------------------------------------------------------
    // Private — leadership loop internals
    // -----------------------------------------------------------------------

    # Runs on a dedicated strand for the entire lifetime of the listener.
    # Exits when the state transitions to `LEADER_STATE_STOPPED`.
    isolated function leadershipLoop(Listener listenerInstance) {
        while true {
            string state;
            lock {
                state = self.leadershipState;
            }
            if state == LEADER_STATE_STOPPED {
                log:printDebug("Leadership loop exiting", nodeId = self.nodeId);
                return;
            }
            if state == LEADER_STATE_STANDBY {
                self.standbyTick(listenerInstance);
            } else if state == LEADER_STATE_LEADER {
                self.leaderTick(listenerInstance);
            }
            runtime:sleep(self.heartbeatInterval);
        }
    }

    # Standby loop body: attempts to acquire leadership. On success, loads
    # the last checkpoint for the channel and starts the CometD subscription
    # anchored at that replay position.
    isolated function standbyTick(Listener listenerInstance) {
        string groupId;
        lock {
            groupId = self.groupId;
        }

        boolean|error attempted = self.coordinator.attemptLeadership(
                groupId, self.nodeId, self.livenessInterval);
        if attempted is error {
            log:printWarn("Leadership attempt failed; remaining standby",
                    nodeId = self.nodeId, groupId = groupId, 'error = attempted);
            return;
        }
        if !attempted {
            log:printDebug("Standby — another leader is healthy",
                    nodeId = self.nodeId, groupId = groupId);
            return;
        }

        log:printInfo("Acquired leadership for Salesforce CDC channel",
                nodeId = self.nodeId, groupId = groupId);

        // Load the persisted checkpoint so the new leader resumes without
        // re-delivering already-handled events. If no checkpoint exists yet
        // (first-ever leader for this group), fall back to `replayFrom`.
        int|error? checkpoint = self.coordinator.getCheckpoint(groupId);
        if checkpoint is error {
            log:printWarn("Failed to read checkpoint; using configured replayFrom",
                    nodeId = self.nodeId, groupId = groupId, 'error = checkpoint);
        } else if checkpoint is int {
            log:printInfo("Resuming CometD from checkpointed replayId",
                    nodeId = self.nodeId, groupId = groupId, replayId = checkpoint);
            // Push the effective replayFrom into the Java layer so the next
            // `startListenerWithOAuth2` call subscribes from the checkpoint
            // rather than the init-time configured value.
            setEffectiveReplayFrom(listenerInstance, checkpoint);
        }

        error? startErr = startListenerWithOAuth2(listenerInstance);
        if startErr is error {
            log:printError("Failed to start CometD after acquiring leadership; " +
                    "dropping back to standby. The lease will expire naturally " +
                    "after livenessInterval seconds, allowing another replica to take over.",
                    nodeId = self.nodeId, groupId = groupId, 'error = startErr);
            // Do NOT renew the lease. The next replica will take over after
            // `livenessInterval` when our heartbeat goes stale.
            return;
        }

        error? scheduleErr = listenerInstance.scheduleTokenRefreshJob();
        if scheduleErr is error {
            log:printWarn("Failed to schedule proactive token refresh after leadership acquisition",
                    nodeId = self.nodeId, groupId = groupId, 'error = scheduleErr);
        }
        lock {
            self.leadershipState = LEADER_STATE_LEADER;
        }
    }

    # Leader loop body: renews the lease heartbeat. If renewal fails (lease
    # was taken over by another replica), tears down CometD and drops back
    # to STANDBY so the new leader can safely open its own subscription.
    isolated function leaderTick(Listener listenerInstance) {
        string groupId;
        lock {
            groupId = self.groupId;
        }

        error? renewed = self.coordinator.renewLeadership(groupId, self.nodeId);
        if renewed is () {
            // Lease still held — nothing to do.
            return;
        }

        log:printWarn("Lost leadership; tearing down CometD subscription",
                nodeId = self.nodeId, groupId = groupId, 'error = renewed);

        error? unscheduleErr = listenerInstance.unscheduleTokenRefreshJob();
        if unscheduleErr is error {
            log:printWarn("Failed to unschedule token refresh job during leadership loss",
                    'error = unscheduleErr);
        }
        error? stopErr = stopListener(listenerInstance);
        if stopErr is error {
            log:printWarn("Failed to stop CometD cleanly after losing leadership",
                    'error = stopErr);
        }
        lock {
            self.leadershipState = LEADER_STATE_STANDBY;
        }
    }
}

// ---------------------------------------------------------------------------
// Java native binding — effective replayFrom override
// ---------------------------------------------------------------------------

# Sets a per-start-cycle override for the CometD subscription replayFrom
# position. When a new leader reads a persisted checkpoint from the
# `ListenerCoordinator`, it calls this function before `startListenerWithOAuth2`
# so that the subscription resumes from the checkpointed position rather
# than the static value captured at `initListener` time.
#
# The value is stored as native data on the `BObject` listener and consumed
# (and cleared) by `subscribeServices` in `ListenerUtil.java`. It takes
# precedence over the init-time `REPLAY_FROM` value for exactly one
# `startListenerWithOAuth2` call.
#
# + instance - The owning `Listener` instance
# + replayFrom - The checkpoint replayId to use as the subscription start
isolated function setEffectiveReplayFrom(Listener instance, int replayFrom) =
@java:Method {
    'class: "io.ballerinax.salesforce.ListenerUtil",
    paramTypes: [
        "io.ballerina.runtime.api.values.BObject",
        "int"
    ]
} external;
