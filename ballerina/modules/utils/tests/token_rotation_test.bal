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
// TokenStore Integration Test Suite
// ==========================================================================
//
// This suite validates that Refresh Token Rotation (RTR) is correctly
// coordinated under concurrency with both the InMemoryTokenStore and the
// Redis-backed RedisTokenStore.
//
// Three test scenarios:
//
// 1. testSingleNodeInMemory
//    Single TokenManager + InMemoryTokenStore.
//    5 concurrent workers call refreshAccessToken().
//    Expectation: Mock endpoint hit EXACTLY 1 time
//    (Ballerina `lock` blocks serialize in-process access).
//
// 2. testMultiNodeInMemoryChaos
//    3 separate TokenManagers, each with its OWN InMemoryTokenStore
//    (simulating 3 isolated K8s pods with no shared state).
//    Each triggers refreshAccessToken() concurrently.
//    Expectation: Mock endpoint hit EXACTLY 3 times.
//    THIS IS THE TOKEN REPLAY VULNERABILITY — in real Salesforce,
//    the 2nd and 3rd calls would use an already-revoked RT and get
//    invalid_grant, permanently killing the entire token family.
//
// 3. testMultiNodeRedisCoordination
//    3 separate TokenManagers, all sharing ONE RedisTokenStore.
//    Each triggers refreshAccessToken() concurrently.
//    Expectation: Mock endpoint hit EXACTLY 1 time, AND all 3
//    managers received a valid access token.
//    The Redis advisory lock ensures only 1 manager refreshes;
//    the others adopt the result from the shared store.
//
// Prerequisites:
//   docker compose up -d   (starts Redis on localhost:6379)
//   The mock Salesforce HTTP server starts automatically in-process.
//
// Run:
//   bal test --groups token_store
//
// ==========================================================================

import ballerina/lang.runtime;
import ballerina/log;
import ballerina/test;
import ballerinax/salesforce.auth;

// --- Test constants ---
const string TEST_CLIENT_ID = "test_client_id_001";
const string TEST_CLIENT_SECRET = "test_client_secret_001";
const string TEST_SEED_REFRESH_TOKEN = "RT_seed_000";
const int TEST_SESSION_TIMEOUT = 900;

// ==========================================================================
// TEST 1: Single Node — InMemoryTokenStore
// ==========================================================================
// Proves that within a single Ballerina process, multiple concurrent callers
// are serialized by the Ballerina `lock` in TokenManager. Only ONE HTTP call
// is made to the Salesforce token endpoint.
// ==========================================================================

@test:Config {
    groups: ["in-memory"]
}
function testSingleNodeInMemory() returns error? {
    log:printInfo("=== TEST 1: Single Node InMemory — 5 concurrent workers ===");

    // Reset mock counter
    resetCallCount();

    // Create ONE TokenManager with default InMemoryTokenStore (no tokenStore arg).
    TokenManager tm = check new (
        TEST_CLIENT_ID, TEST_CLIENT_SECRET,
        TEST_SEED_REFRESH_TOKEN, MOCK_TOKEN_URL,
        TEST_SESSION_TIMEOUT
    );

    // Launch 5 concurrent workers that all call refreshAccessToken().
    worker w1 returns string|error {
        return tm.refreshAccessToken();
    }

    worker w2 returns string|error {
        return tm.refreshAccessToken();
    }

    worker w3 returns string|error {
        return tm.refreshAccessToken();
    }

    worker w4 returns string|error {
        return tm.refreshAccessToken();
    }

    worker w5 returns string|error {
        return tm.refreshAccessToken();
    }

    // Collect results from all workers
    string|error r1 = wait w1;
    string|error r2 = wait w2;
    string|error r3 = wait w3;
    string|error r4 = wait w4;
    string|error r5 = wait w5;

    // All should succeed
    test:assertTrue(r1 is string, "Worker 1 failed: " + (r1 is error ? r1.message() : ""));
    test:assertTrue(r2 is string, "Worker 2 failed: " + (r2 is error ? r2.message() : ""));
    test:assertTrue(r3 is string, "Worker 3 failed: " + (r3 is error ? r3.message() : ""));
    test:assertTrue(r4 is string, "Worker 4 failed: " + (r4 is error ? r4.message() : ""));
    test:assertTrue(r5 is string, "Worker 5 failed: " + (r5 is error ? r5.message() : ""));

    // Give any in-flight async logging a moment to settle
    runtime:sleep(0.1);

    int callCount = getCallCount();
    log:printInfo(string `[TEST 1] Mock endpoint call count: ${callCount}`);

    // CRITICAL ASSERTION:
    // With InMemoryTokenStore, the Ballerina `lock` in doRefreshWithLock() serializes
    // all 5 workers. The first worker does the HTTP call and writes to the store.
    // Workers 2-5 see a valid token in the store (double-check) and skip the HTTP call.
    // Result: exactly 1 call to the mock endpoint.
    test:assertEquals(callCount, 1,
        string `Expected exactly 1 mock endpoint call (InMemory single-node), got ${callCount}`);

    // All workers should return the SAME access token (adopted from the first refresh)
    if r1 is string && r2 is string && r3 is string && r4 is string && r5 is string {
        test:assertEquals(r2, r1, "Worker 2 got a different token than Worker 1");
        test:assertEquals(r3, r1, "Worker 3 got a different token than Worker 1");
        test:assertEquals(r4, r1, "Worker 4 got a different token than Worker 1");
        test:assertEquals(r5, r1, "Worker 5 got a different token than Worker 1");
        log:printInfo("[TEST 1] All 5 workers received the same access token — PASS");
    }

    log:printInfo("=== TEST 1 PASSED ===");
}

// ==========================================================================
// TEST 2: Multi-Node InMemory — Token Replay Chaos
// ==========================================================================
// Simulates 3 isolated Kubernetes pods, each with its own TokenManager and
// InMemoryTokenStore. They share NO state. All 3 try to refresh concurrently
// using the SAME seed refresh token.
//
// This test PROVES the Token Replay Attack vulnerability:
// In production, Salesforce would revoke the entire token family after the
// 2nd pod uses the already-rotated RT. Here, our mock server is permissive
// (it always returns 200), so all 3 succeed — but the call count of 3
// proves that 3 separate HTTP calls were made, which is the vulnerability.
// ==========================================================================

@test:Config {
    groups: ["in-memory"],
    dependsOn: [testSingleNodeInMemory]
}
function testMultiNodeInMemoryChaos() returns error? {
    log:printInfo("=== TEST 2: Multi-Node InMemory Chaos — 3 isolated pods ===");

    // Reset mock counter
    resetCallCount();

    // Create 3 SEPARATE TokenManagers with SEPARATE InMemoryTokenStores.
    // This simulates 3 isolated K8s pods — no shared memory.
    TokenManager pod1 = check new (
        TEST_CLIENT_ID, TEST_CLIENT_SECRET,
        TEST_SEED_REFRESH_TOKEN, MOCK_TOKEN_URL,
        TEST_SESSION_TIMEOUT
    );
    TokenManager pod2 = check new (
        TEST_CLIENT_ID, TEST_CLIENT_SECRET,
        TEST_SEED_REFRESH_TOKEN, MOCK_TOKEN_URL,
        TEST_SESSION_TIMEOUT
    );
    TokenManager pod3 = check new (
        TEST_CLIENT_ID, TEST_CLIENT_SECRET,
        TEST_SEED_REFRESH_TOKEN, MOCK_TOKEN_URL,
        TEST_SESSION_TIMEOUT
    );

    // All 3 pods refresh concurrently — each using the same seed RT.
    worker pod1Worker returns string|error {
        return pod1.refreshAccessToken();
    }

    worker pod2Worker returns string|error {
        return pod2.refreshAccessToken();
    }

    worker pod3Worker returns string|error {
        return pod3.refreshAccessToken();
    }

    string|error r1 = wait pod1Worker;
    string|error r2 = wait pod2Worker;
    string|error r3 = wait pod3Worker;

    // All should succeed (mock is permissive)
    test:assertTrue(r1 is string, "Pod 1 failed: " + (r1 is error ? r1.message() : ""));
    test:assertTrue(r2 is string, "Pod 2 failed: " + (r2 is error ? r2.message() : ""));
    test:assertTrue(r3 is string, "Pod 3 failed: " + (r3 is error ? r3.message() : ""));

    runtime:sleep(0.1);

    int callCount = getCallCount();
    log:printInfo(string `[TEST 2] Mock endpoint call count: ${callCount}`);

    // CRITICAL ASSERTION:
    // With separate InMemoryTokenStores, there is NO cross-pod coordination.
    // Each pod independently calls the Salesforce token endpoint.
    // Result: exactly 3 calls — THIS IS THE VULNERABILITY.
    //
    // In a real Salesforce org with RTR enabled:
    //   Pod 1: sends RT_seed → gets AT_1 + RT_1 (RT_seed is now revoked)
    //   Pod 2: sends RT_seed → INVALID_GRANT (RT_seed was already used!)
    //   Pod 3: sends RT_seed → INVALID_GRANT (entire token family revoked!)
    test:assertEquals(callCount, 3,
        string `Expected exactly 3 mock endpoint calls (multi-node chaos), got ${callCount}`);

    // Each pod got a DIFFERENT access token (no shared state)
    if r1 is string && r2 is string && r3 is string {
        test:assertNotEquals(r1, r2, "Pod 1 and Pod 2 should have different tokens");
        test:assertNotEquals(r1, r3, "Pod 1 and Pod 3 should have different tokens");
        log:printInfo("[TEST 2] All 3 pods got DIFFERENT tokens (no coordination) — VULNERABILITY PROVEN");
    }

    log:printInfo("=== TEST 2 PASSED (vulnerability demonstrated) ===");
}

// ==========================================================================
// TEST 3: Multi-Node Redis Coordination
// ==========================================================================
// 3 separate TokenManagers sharing ONE RedisTokenStore instance.
// The Redis advisory lock ensures only ONE pod performs the actual refresh.
// The other 2 adopt the result from the shared store.
// ==========================================================================

@test:Config {
    groups: ["redis-integration"],
    dependsOn: [testMultiNodeInMemoryChaos],
    enable: redisAvailable
}
function testMultiNodeRedisCoordination() returns error? {
    log:printInfo("=== TEST 3: Multi-Node Redis Coordination — 3 pods, 1 RedisTokenStore ===");

    // Reset mock counter
    resetCallCount();

    // Create ONE shared RedisTokenStore
    RedisTokenStore sharedStore = check new ();
    check sharedStore.flushAll();

    // Create 3 SEPARATE TokenManagers, all sharing the SAME RedisTokenStore.
    TokenManager pod1 = check new (
        TEST_CLIENT_ID, TEST_CLIENT_SECRET,
        TEST_SEED_REFRESH_TOKEN, MOCK_TOKEN_URL,
        TEST_SESSION_TIMEOUT,
        tokenStore = sharedStore
    );
    TokenManager pod2 = check new (
        TEST_CLIENT_ID, TEST_CLIENT_SECRET,
        TEST_SEED_REFRESH_TOKEN, MOCK_TOKEN_URL,
        TEST_SESSION_TIMEOUT,
        tokenStore = sharedStore
    );
    TokenManager pod3 = check new (
        TEST_CLIENT_ID, TEST_CLIENT_SECRET,
        TEST_SEED_REFRESH_TOKEN, MOCK_TOKEN_URL,
        TEST_SESSION_TIMEOUT,
        tokenStore = sharedStore
    );

    // All 3 pods refresh concurrently — only one should win the lock.
    worker pod1Worker returns string|error {
        return pod1.refreshAccessToken();
    }

    worker pod2Worker returns string|error {
        return pod2.refreshAccessToken();
    }

    worker pod3Worker returns string|error {
        return pod3.refreshAccessToken();
    }

    string|error r1 = wait pod1Worker;
    string|error r2 = wait pod2Worker;
    string|error r3 = wait pod3Worker;

    // All 3 should succeed
    test:assertTrue(r1 is string, "Pod 1 failed: " + (r1 is error ? r1.message() : ""));
    test:assertTrue(r2 is string, "Pod 2 failed: " + (r2 is error ? r2.message() : ""));
    test:assertTrue(r3 is string, "Pod 3 failed: " + (r3 is error ? r3.message() : ""));

    runtime:sleep(0.1);

    int callCount = getCallCount();
    log:printInfo(string `[TEST 3] Mock endpoint call count: ${callCount}`);

    // CRITICAL ASSERTION:
    // With RedisTokenStore, the advisory lock serializes cross-pod access.
    // One pod acquires the lock, calls the token endpoint, writes to Redis.
    // The other 2 pods find the lock held, wait, then read the valid token
    // from Redis — skipping the HTTP call entirely.
    // Result: exactly 1 call to the mock endpoint.
    test:assertEquals(callCount, 1,
        string `Expected exactly 1 mock endpoint call (Redis coordination), got ${callCount}`);

    // ALL 3 pods should have received the SAME access token
    if r1 is string && r2 is string && r3 is string {
        test:assertEquals(r2, r1, "Pod 2 should have the same token as Pod 1 (from Redis store)");
        test:assertEquals(r3, r1, "Pod 3 should have the same token as Pod 1 (from Redis store)");
        log:printInfo("[TEST 3] All 3 pods received the SAME access token from Redis — PASS");
    }

    // Verify Redis store contains the token
    auth:TokenData? storedData = check sharedStore.getTokenData("sf_token:" + fingerprintToken(TEST_CLIENT_ID));
    test:assertTrue(storedData is auth:TokenData, "Token data should be persisted in Redis");
    if storedData is auth:TokenData && r1 is string {
        test:assertEquals(storedData.accessToken, r1,
            "Redis store should contain the same access token as returned to pods");
        test:assertTrue(storedData.refreshToken.startsWith("RT_mock_"),
            "Redis store should contain the rotated refresh token");
        log:printInfo("[TEST 3] Redis store verified — token data persisted correctly");
    }

    // Cleanup
    check sharedStore.flushAll();
    check sharedStore.close();

    log:printInfo("=== TEST 3 PASSED (Redis coordination prevents Token Replay Attack) ===");
}
