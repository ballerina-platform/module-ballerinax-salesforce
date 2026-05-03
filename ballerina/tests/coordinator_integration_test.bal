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

// ==========================================================================
// ListenerCoordinator Contract — Integration Tests
// ==========================================================================
//
// Validates the three behavioural invariants that every `ListenerCoordinator`
// implementation (InMemoryCoordinator, MysqlListenerCoordinator, …) MUST
// satisfy for Active-Standby failover to work correctly.
//
// These tests run against `InMemoryCoordinator` (bundled, no external
// dependencies) so they execute in any environment without Docker.
// The same test cases serve as the acceptance criteria for any SQL-backed
// implementation: if InMemoryCoordinator passes and your SQL implementation
// also passes, the failover semantics are correct.
//
// Test cases
// ----------
//   testInitialLeaderElection  – first caller wins; second caller stays standby
//   testLeaderFailover         – stale heartbeat triggers lease theft; evicted
//                                node's renewLeadership() returns an error
//   testCheckpointMonotonicity – high-water mark never regresses; out-of-order
//                                replayIds are silently ignored
//
// Run:
//   bal test --groups coordinator-integration
//
// ==========================================================================

import ballerina/lang.runtime;
import ballerina/log;
import ballerina/test;

// ---------------------------------------------------------------------------
// Coordinator under test
//
// Non-final so @test:BeforeSuite can swap it for a freshly-constructed
// instance, giving each test run a clean slate (equivalent to
// TRUNCATE TABLE sf_listener_coordination for a SQL-backed implementation).
// ---------------------------------------------------------------------------
InMemoryCoordinator coordinator = new ();

// ---------------------------------------------------------------------------
// Simulated replica identities — deterministic UUIDs so log output is readable
// ---------------------------------------------------------------------------
const string COORD_NODE_A = "node-a-4f3a-8b1e-coord-test";
const string COORD_NODE_B = "node-b-9c2d-3e7f-coord-test";

// ---------------------------------------------------------------------------
// Unique coordination keys per test — prevents state bleed between tests
// even when the shared coordinator instance accumulates entries.
// ---------------------------------------------------------------------------
const string GROUP_ELECTION     = "/data/CoordTest_Election";
const string GROUP_FAILOVER     = "/data/CoordTest_Failover";
const string CHANNEL_CHECKPOINT = "/data/CoordTest_Checkpoint";

// ---------------------------------------------------------------------------
// @test:BeforeSuite — reset the coordinator to a clean slate
//
// For InMemoryCoordinator: re-instantiate (drops all in-memory state).
// For a SQL-backed coordinator this is where you would run:
//   TRUNCATE TABLE sf_listener_coordination;
// ---------------------------------------------------------------------------

@test:BeforeSuite
function setupCoordinator() {
    coordinator = new InMemoryCoordinator();
    log:printInfo("[CoordTest] Coordinator reset — starting with a clean slate.");
}

// ==========================================================================
// TEST 1: testInitialLeaderElection
// ==========================================================================
//
// Validates the fundamental Active / Standby split:
//
//   1. Node A calls attemptLeadership() — no prior entry exists.
//      → Must return true (Node A is now the leader).
//
//   2. Node B calls attemptLeadership() immediately for the SAME group.
//      → Node A's heartbeat is fresh; B must return false (remains standby).
//
// This is the baseline contract: exactly one replica leads at any time.
// ==========================================================================

@test:Config {
    groups: ["coordinator-integration"]
}
function testInitialLeaderElection() returns error? {
    log:printInfo("=== COORD TEST 1: Initial Leader Election (Active / Standby) ===");

    // --- Node A competes: no prior leader → must win ---
    // `check` propagates any unexpected coordinator error as a test failure,
    // removing `error` from the union so the plain `boolean` is safe to assert.
    boolean nodeAResult = check coordinator.attemptLeadership(
            GROUP_ELECTION, COORD_NODE_A, 30d);

    test:assertTrue(nodeAResult,
            "Node A must win leadership on the first attempt — got: false");
    log:printInfo("[COORD TEST 1] Node A → LEADER (true) ✓");

    // --- Node B competes immediately: Node A is healthy → must stay standby ---
    boolean nodeBResult = check coordinator.attemptLeadership(
            GROUP_ELECTION, COORD_NODE_B, 30d);

    test:assertFalse(nodeBResult,
            "Node B must remain standby while Node A holds a fresh 30-second lease — got: true");
    log:printInfo("[COORD TEST 1] Node B → STANDBY (false) ✓");

    // --- Node A renewing its own lease must always succeed ---
    check coordinator.renewLeadership(GROUP_ELECTION, COORD_NODE_A);
    log:printInfo("[COORD TEST 1] Node A lease renewal → ok ✓");

    log:printInfo("=== COORD TEST 1 PASSED ===");
}

// ==========================================================================
// TEST 2: testLeaderFailover
// ==========================================================================
//
// Validates the staleness-driven failover path. This is the core correctness
// test for Active-Standby: if the leader crashes or loses connectivity, a
// standby replica MUST be able to take over after livenessInterval seconds.
//
//   1. Node A acquires leadership with livenessInterval = 2 seconds.
//   2. Sanity-check: Node B cannot steal the lease while A is live.
//   3. Sleep 3 seconds — Node A's heartbeat becomes stale (> 2 s old).
//   4. Node B re-attempts: detects stale heartbeat, takes over → true.
//   5. Node A calls renewLeadership() → MUST receive an error.
//      (This error is the signal that causes CometdStateManager to tear
//       down the CometD subscription and drop back to STANDBY state.)
//
// ==========================================================================

@test:Config {
    groups: ["coordinator-integration"],
    dependsOn: [testInitialLeaderElection]
}
function testLeaderFailover() returns error? {
    log:printInfo("=== COORD TEST 2: Leader Failover via Heartbeat Staleness ===");

    // --- Phase 1: Node A acquires a short-lived lease (2 s) ---
    boolean nodeAWon = check coordinator.attemptLeadership(
            GROUP_FAILOVER, COORD_NODE_A, 2d);

    test:assertTrue(nodeAWon,
            "Node A must win leadership for the failover group — got: false");
    log:printInfo("[COORD TEST 2] Node A acquired lease (liveness = 2 s) ✓");

    // --- Phase 2: Sanity check — B cannot steal a healthy lease ---
    boolean nodeBTooEarly = check coordinator.attemptLeadership(
            GROUP_FAILOVER, COORD_NODE_B, 2d);

    test:assertFalse(nodeBTooEarly,
            "Node B must not steal the lease while Node A is within its liveness window — got: true");
    log:printInfo("[COORD TEST 2] Node B correctly blocked while Node A is healthy ✓");

    // --- Phase 3: Let Node A's heartbeat expire ---
    log:printInfo("[COORD TEST 2] Sleeping 3 s to expire Node A's 2-second liveness window...");
    runtime:sleep(3);

    // --- Phase 4: Node B retries — heartbeat is now stale — must win ---
    boolean nodeBStole = check coordinator.attemptLeadership(
            GROUP_FAILOVER, COORD_NODE_B, 2d);

    test:assertTrue(nodeBStole,
            "Node B MUST take over leadership after Node A's lease expired — " +
            "this is the core failover correctness test. Got: false");
    log:printInfo("[COORD TEST 2] Node B stole leadership from stale Node A ✓");

    // --- Phase 5: Node A tries to renew — must be rejected ---
    // This error is what CometdStateManager.leaderTick() uses to trigger
    // stopListener() and drop back to STANDBY so the new leader (Node B)
    // can safely open its own CometD subscription without a dual-leader race.
    error? renewResult = coordinator.renewLeadership(GROUP_FAILOVER, COORD_NODE_A);

    test:assertTrue(renewResult is error,
            "Node A's renewLeadership() MUST return an error after losing the lease — " +
            "without this rejection, the old leader would continue holding CometD open " +
            "alongside the new leader, causing duplicate event delivery.");
    if renewResult is error {
        log:printInfo("[COORD TEST 2] Node A correctly rejected on renewal: " +
                renewResult.message() + " ✓");
    }

    // --- Verify Node B can still renew (it is the new owner) ---
    check coordinator.renewLeadership(GROUP_FAILOVER, COORD_NODE_B);
    log:printInfo("[COORD TEST 2] Node B lease renewal → ok ✓");

    log:printInfo("=== COORD TEST 2 PASSED ===");
}

// ==========================================================================
// TEST 3: testCheckpointMonotonicity
// ==========================================================================
//
// Validates that the checkpoint high-water mark is monotonically increasing.
// This prevents a failover replica from rewinding the replayId and
// re-delivering events that were already processed by a previous leader.
//
// Scenario:
//   • save(100) → get() == 100      (normal forward progress)
//   • save(50)  → get() == 100      (out-of-order write is silently ignored)
//   • save(50)  → get() == 100      (equal-or-lower write is also ignored)
//   • save(150) → get() == 150      (higher watermark advances correctly)
//
// The monotonicity guard lives in saveCheckpoint(); getCheckpoint() is a
// pure read with no side effects.
//
// ==========================================================================

@test:Config {
    groups: ["coordinator-integration"],
    dependsOn: [testLeaderFailover]
}
function testCheckpointMonotonicity() returns error? {
    log:printInfo("=== COORD TEST 3: Checkpoint Monotonicity Guard ===");

    // --- Step 1: Establish initial high-water mark ---
    check coordinator.saveCheckpoint(CHANNEL_CHECKPOINT, 100);

    // `check` strips the `error` branch from int|error?, leaving int? (= int|()).
    // int? is a subtype of `any`, so test:assertTrue / test:assertEquals accept it.
    int? cp1 = check coordinator.getCheckpoint(CHANNEL_CHECKPOINT);
    test:assertTrue(cp1 is int,
            "getCheckpoint after saveCheckpoint(100) must return an int, not nil: " +
            "(nil — no checkpoint recorded)");
    test:assertEquals(cp1, 100,
            "getCheckpoint must return 100 after saving 100: got " + cp1.toString());
    log:printInfo("[COORD TEST 3] Checkpoint after save(100) = 100 ✓");

    // --- Step 2: Attempt a backward write — must be silently ignored ---
    // Simulates a delayed or re-delivered event whose replayId is lower than
    // the current watermark. This can happen after a CometD reconnect or
    // if events arrive out of order in the dispatch path.
    check coordinator.saveCheckpoint(CHANNEL_CHECKPOINT, 50);

    int? cp2 = check coordinator.getCheckpoint(CHANNEL_CHECKPOINT);
    test:assertTrue(cp2 is int,
            "getCheckpoint after attempted rollback must still return an int");
    test:assertEquals(cp2, 100,
            "Checkpoint MUST NOT regress: saveCheckpoint(50) must be ignored " +
            "when 100 is already the high-water mark. Got: " + cp2.toString());
    log:printInfo("[COORD TEST 3] save(50) correctly ignored — checkpoint stays 100 ✓");

    // --- Step 3: Equal-value write — also a no-op ---
    check coordinator.saveCheckpoint(CHANNEL_CHECKPOINT, 100);

    int? cp3 = check coordinator.getCheckpoint(CHANNEL_CHECKPOINT);
    test:assertEquals(cp3, 100,
            "Checkpoint must remain 100 after a duplicate saveCheckpoint(100): got " +
            cp3.toString());
    log:printInfo("[COORD TEST 3] Duplicate save(100) correctly ignored — checkpoint stays 100 ✓");

    // --- Step 4: Advance the watermark ---
    check coordinator.saveCheckpoint(CHANNEL_CHECKPOINT, 150);

    int? cp4 = check coordinator.getCheckpoint(CHANNEL_CHECKPOINT);
    test:assertTrue(cp4 is int,
            "getCheckpoint after saveCheckpoint(150) must return an int");
    test:assertEquals(cp4, 150,
            "Checkpoint must advance to 150 after saveCheckpoint(150): got " + cp4.toString());
    log:printInfo("[COORD TEST 3] Checkpoint advanced to 150 ✓");

    log:printInfo("=== COORD TEST 3 PASSED ===");
}

// ==========================================================================
// @test:AfterSuite — log completion
// ==========================================================================

@test:AfterSuite
function teardownCoordinator() {
    log:printInfo("[CoordTest] All coordinator integration tests completed.");
}
