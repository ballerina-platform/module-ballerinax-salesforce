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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

// Issue #8807 - TokenRefreshJob reconnect must resume from the latest replayId.
//
// Drives the production checkpoint-resume code path offline (no live
// Salesforce). A real OAuth2 Listener is constructed with a Bearer token (so no
// TokenManager / network is needed) and a real InMemoryCoordinator. We seed a
// checkpoint, invoke the exact production method that TokenRefreshJob.execute()
// calls - Listener.applyCheckpointReplayFrom() - and read back the native
// EFFECTIVE_REPLAY_FROM that the next CometD subscribe would consume.
//
// Run: bal test --groups issue-8807

import ballerina/jballerina.java;
import ballerina/test;

// Test-only native observability hook (see ListenerUtil.getEffectiveReplayFrom).
// Returns the effective replayId override the next subscribe would use, or -1
// if absent (would fall back to the init-time REPLAY_FROM).
isolated function getEffectiveReplayFrom(Listener instance) returns int = @java:Method {
    'class: "io.ballerinax.salesforce.ListenerUtil"
} external;

const string ISSUE_8807_CHANNEL = "/event/Issue8807__e";

isolated function makeNoopService() returns Service {
    Service noop = service object {
        remote function onMessage(PlatformEventsMessage message) returns error? {
        }
    };
    return noop;
}

isolated function makeListener(InMemoryCoordinator coordinator, int|ReplayOptions replayFrom)
        returns Listener|error {
    RestBasedListenerConfig config = {
        auth: {token: "test-bearer-token"},
        baseUrl: "https://example.my.salesforce.com",
        replayFrom: replayFrom,
        coordination: {coordinator}
    };
    Listener lis = check new Listener(config);
    check lis.attach(makeNoopService(), ISSUE_8807_CHANNEL);
    return lis;
}

// TEST 1 - EARLIEST + existing checkpoint (issue scenario: 72h duplicates).
@test:Config {
    groups: ["issue-8807"]
}
function testResumeFromCheckpointEarliest() returns error? {
    InMemoryCoordinator coordinator = new ();
    Listener lis = check makeListener(coordinator, REPLAY_FROM_EARLIEST);
    check coordinator.saveCheckpoint(ISSUE_8807_CHANNEL, 9999);
    lis.applyCheckpointReplayFrom();
    int effective = getEffectiveReplayFrom(lis);
    test:assertEquals(effective, 9999, "Must resume from checkpoint 9999, not EARLIEST");
}

// TEST 2 - TIP + existing checkpoint (issue scenario: missed window events).
@test:Config {
    groups: ["issue-8807"]
}
function testResumeFromCheckpointTip() returns error? {
    InMemoryCoordinator coordinator = new ();
    Listener lis = check makeListener(coordinator, REPLAY_FROM_TIP);
    check coordinator.saveCheckpoint(ISSUE_8807_CHANNEL, 5000);
    lis.applyCheckpointReplayFrom();
    int effective = getEffectiveReplayFrom(lis);
    test:assertEquals(effective, 5000, "Must resume from checkpoint 5000, not TIP");
}

// TEST 3 - Cold start, no checkpoint (backward compatibility: fall back).
@test:Config {
    groups: ["issue-8807"]
}
function testNoCheckpointFallsBack() returns error? {
    InMemoryCoordinator coordinator = new ();
    Listener lis = check makeListener(coordinator, REPLAY_FROM_EARLIEST);
    lis.applyCheckpointReplayFrom();
    int effective = getEffectiveReplayFrom(lis);
    test:assertTrue(effective < 0, "No checkpoint must clear override to fall back");
}

// TEST 4 - Override recomputed each call (stale override never survives).
@test:Config {
    groups: ["issue-8807"]
}
function testOverrideRecomputedEachCall() returns error? {
    InMemoryCoordinator coordinator = new ();
    Listener lis = check makeListener(coordinator, REPLAY_FROM_TIP);
    check coordinator.saveCheckpoint(ISSUE_8807_CHANNEL, 7000);
    lis.applyCheckpointReplayFrom();
    test:assertEquals(getEffectiveReplayFrom(lis), 7000, "First resolve sets 7000");

    InMemoryCoordinator freshCoordinator = new ();
    Listener freshListener = check makeListener(freshCoordinator, REPLAY_FROM_TIP);
    freshListener.applyCheckpointReplayFrom();
    test:assertTrue(getEffectiveReplayFrom(freshListener) < 0, "No checkpoint clears override");
}
