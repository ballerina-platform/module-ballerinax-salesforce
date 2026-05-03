// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
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

import ballerina/time;

# Active-Standby leader-election and ReplayId checkpointing contract for the
# Salesforce Streaming API listener.
#
# In a horizontally-scaled deployment (multiple replicas of the same listener),
# only ONE replica should hold the CometD subscription open at a time. All
# other replicas idle in standby until the leader's lease expires, at which
# point one of them acquires the token and resumes the subscription from the
# last persisted `replayId`.
public type ListenerCoordinator isolated object {

    # Attempts to become the leader for the given coordination group.
    #
    # Semantics:
    # - If no replica currently holds leadership, the caller acquires it.
    # - If the caller is already the leader, this is a no-op success.
    #   **Implementations MUST NOT refresh the heartbeat timestamp in this
    #   case.** Refreshing the heartbeat from `attemptLeadership()` would
    #   silently renew the lease even when called from `standbyTick()` after
    #   a failed `startListenerWithOAuth2()`, preventing a healthy standby
    #   from taking over. Heartbeat refresh is the exclusive responsibility
    #   of `renewLeadership()`, which is only called from `leaderTick()` while
    #   the CometD subscription is actually active.
    # - If a different replica holds leadership AND its last heartbeat is
    #   within `livenessInterval` seconds, the caller remains a standby.
    # - If a different replica holds leadership but its heartbeat is older
    #   than `livenessInterval` seconds, the caller takes over.
    #
    # The implementation MUST treat acquisition as atomic with respect to
    # concurrent callers (e.g. via `INSERT ... ON CONFLICT DO UPDATE` for
    # SQL-backed implementations).
    #
    # + groupId - Logical identity of the coordination group (typically the
    #             channel name, e.g. `/data/AccountChangeEvent`)
    # + nodeId - Unique identifier of the calling replica (per-process UUID)
    # + livenessInterval - Maximum staleness, in seconds, before the current
    #                      leader's lease is considered expired
    # + return - `true` if this replica is now the leader, `false` if it
    #            remains a standby, or an `error` on store failure
    public isolated function attemptLeadership(string groupId, string nodeId,
            decimal livenessInterval) returns boolean|error;

    # Refreshes the leader's heartbeat to keep its lease alive. Should be
    # invoked at an interval strictly less than `livenessInterval`.
    #
    # If this replica is no longer the recorded leader (e.g. another replica
    # has taken over after a missed heartbeat), implementations MUST return an
    # error so the caller can drop back to standby.
    #
    # + groupId - Logical identity of the coordination group
    # + nodeId - Unique identifier of the calling replica
    # + return - `()` on a successful renewal, an `error` if the lease was lost
    public isolated function renewLeadership(string groupId, string nodeId) returns error?;

    # Persists the latest successfully-dispatched `replayId` for a channel so
    # that the next leader can resume the subscription without re-processing
    # already-handled events.
    #
    # Called from the event-dispatch path after the user's `onEvent` handler
    # returns successfully. Implementations are encouraged (but not required)
    # to batch writes — the contract is "the most recent replayId observed
    # here MUST be readable by `getCheckpoint` after a leader handover."
    #
    # + channel - Fully-qualified Salesforce channel name (e.g. `/event/Foo__e`)
    # + replayId - The Salesforce-issued, monotonically increasing replay ID
    # + return - `()` on success, or an `error` on store failure
    public isolated function saveCheckpoint(string channel, int replayId) returns error?;

    # Reads the most recently checkpointed `replayId` for a channel. Returns
    # `()` if no checkpoint has ever been saved for this channel — in which
    # case the listener should fall back to its configured `replayFrom`.
    #
    # + channel - Fully-qualified Salesforce channel name
    # + return - The persisted `replayId`, `()` if none exists, or `error`
    public isolated function getCheckpoint(string channel) returns int|error?;

    # Immediately releases the leadership lease for the given coordination group.
    # Called on graceful shutdown so that standbys can take over at their next
    # poll tick (`heartbeatInterval` seconds) rather than waiting for the full
    # `livenessInterval` to expire.
    #
    # Semantics:
    # - If the caller is the current leader, the lease is cleared immediately
    #   (e.g. DELETE the row, or set `leader_node_id = NULL`).
    # - If the caller is NOT the current leader (already lost the lease or never
    #   held it), this MUST be a silent no-op — never return an error in that case.
    # - Implementations MUST be idempotent: calling twice for the same node has
    #   the same effect as calling once.
    #
    # + groupId - Logical identity of the coordination group
    # + nodeId - Unique identifier of the calling replica
    # + return - `()` on success, or an `error` on store failure
    public isolated function relinquishLeadership(string groupId, string nodeId) returns error?;
};

# Internal heartbeat record tracked by `InMemoryCoordinator`.
type LeaderEntry record {|
    string nodeId;
    int lastHeartbeatEpochMillis;
|};

# Default in-process coordinator. Suitable for single-replica deployments and
# for unit tests where a distributed coordinator is not available.
#
# All shared state is guarded by `lock` blocks, so it is safe to use from
# concurrent strands. Liveness checks use `livenessInterval` against the
# wall-clock millisecond delta — this is consistent with the cross-replica
# semantics, even though contention is not realistic in a single process.
public isolated class InMemoryCoordinator {
    *ListenerCoordinator;

    private map<LeaderEntry> leaders = {};
    private map<int> checkpoints = {};

    public isolated function attemptLeadership(string groupId, string nodeId,
            decimal livenessInterval) returns boolean|error {
        int nowMillis = currentEpochMillis();
        int livenessMillis = <int>(livenessInterval * 1000d);
        lock {
            LeaderEntry? current = self.leaders[groupId];
            if current is () {
                self.leaders[groupId] = {nodeId, lastHeartbeatEpochMillis: nowMillis};
                return true;
            }
            if current.nodeId == nodeId {
                // The caller is already the recorded leader — return success
                // WITHOUT refreshing the heartbeat. Refreshing here would
                // silently renew the lease on every standbyTick() call that
                // follows a failed startListenerWithOAuth2(), blocking other
                // replicas from taking over indefinitely. Only renewLeadership()
                // (called from leaderTick() while CometD is active) may reset
                // the heartbeat timestamp. This matches the contract comment:
                // "if the caller is already the leader, this is a no-op success."
                return true;
            }
            int staleness = nowMillis - current.lastHeartbeatEpochMillis;
            if staleness > livenessMillis {
                // Existing leader's heartbeat is stale — take over.
                self.leaders[groupId] = {nodeId, lastHeartbeatEpochMillis: nowMillis};
                return true;
            }
            return false;
        }
    }

    public isolated function renewLeadership(string groupId, string nodeId) returns error? {
        int nowMillis = currentEpochMillis();
        lock {
            LeaderEntry? current = self.leaders[groupId];
            if current is () || current.nodeId != nodeId {
                return error(string `Leadership lost for group '${groupId}': ` +
                        string `caller '${nodeId}' is no longer the recorded leader.`);
            }
            self.leaders[groupId] = {nodeId, lastHeartbeatEpochMillis: nowMillis};
            return;
        }
    }

    public isolated function saveCheckpoint(string channel, int replayId) returns error? {
        lock {
            int? existing = self.checkpoints[channel];
            // Monotonicity guard: never let a checkpoint go backwards. Salesforce
            // delivers replayIds in increasing order per channel, so a regression
            // means either a replay-from-earliest restart or a bug. Either way
            // we keep the higher watermark.
            if existing is int && existing >= replayId {
                return;
            }
            self.checkpoints[channel] = replayId;
            return;
        }
    }

    public isolated function getCheckpoint(string channel) returns int|error? {
        lock {
            return self.checkpoints[channel];
        }
    }

    public isolated function relinquishLeadership(string groupId, string nodeId) returns error? {
        lock {
            LeaderEntry? current = self.leaders[groupId];
            // Only clear the entry if this node is still the recorded leader.
            // If another replica already took over, leave its entry untouched.
            if current is LeaderEntry && current.nodeId == nodeId {
                _ = self.leaders.remove(groupId);
            }
        }
    }
}

# Returns the current wall-clock time in epoch milliseconds. Used by the
# in-memory coordinator for heartbeat staleness calculations.
isolated function currentEpochMillis() returns int {
    time:Utc utc = time:utcNow();
    return utc[0] * 1000 + <int>(utc[1] * 1000d);
}
