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
// Refresh Token Rotation (RTR) — Focused Integration Tests
// ==========================================================================
//
// Complements the concurrency suite in `token_rotation_test.bal`:
//
//   1. testInMemoryRtrWithExpiration
//      No Redis store — proves the default InMemoryTokenStore correctly
//      rotates a token when the access token expires.
//
//   2. testRedisMasterFlow
//      Uncontested Redis lock — the lone TokenManager wins `SETNX`,
//      calls Salesforce, writes to Redis, and releases the lock.
//
//   3. testRedisWorkerFlow
//      Pre-populated Redis — proves a "worker" TokenManager adopts an
//      existing valid token from Redis instead of hitting Salesforce.
//
//   4. testCachePoisoningAutoEviction
//      Pre-populated dead token + mocked `invalid_grant` — proves the
//      TokenManager auto-evicts the dead token from Redis so a restart
//      with a fresh seed token will not be poisoned by stale cache.
//
// Prerequisites:
//   - The mock Salesforce HTTP server starts automatically via
//     @test:BeforeSuite (see mock_salesforce_api.bal).
//   - The Redis Docker container is started automatically via
//     @test:BeforeSuite (see docker_lifecycle.bal). Redis-dependent tests
//     skip gracefully if Docker is unavailable.
//
// ==========================================================================

import ballerina/lang.runtime;
import ballerina/log;
import ballerina/test;
import ballerina/time;

// Dedicated client identifiers (different hashes → different Redis keys)
// so these tests don't collide with the chaos suite in token_rotation_test.bal.
const string RTR_CLIENT_ID_INMEM = "rtr_client_inmem_001";
const string RTR_CLIENT_ID_MASTER = "rtr_client_master_001";
const string RTR_CLIENT_ID_WORKER = "rtr_client_worker_001";
const string RTR_CLIENT_ID_POISON = "rtr_client_poison_001";

// ==========================================================================
// TEST A: In-Memory RTR with Simulated Token Expiration
// ==========================================================================
// Default behavior: no `TokenStore` argument → TokenManager uses its
// built-in `InMemoryTokenStore`. We simulate token expiry by explicitly
// calling `invalidateAccessToken()` between two `getAccessToken()` calls
// and assert that:
//   - First call makes 1 HTTP request to mock Salesforce
//   - Cached call makes 0 additional HTTP requests
//   - Post-expiry call makes 1 additional HTTP request (rotation succeeded)
//   - New access token differs from first access token
//   - Refresh token was rotated (no longer equals the seed)
//   - No configuration errors were thrown
// ==========================================================================

@test:Config {
    groups: ["in-memory"],
    dependsOn: [testMultiNodeInMemoryChaos]
}
function testInMemoryRtrWithExpiration() returns error? {
    log:printInfo("=== RTR TEST A: In-Memory RTR with Simulated Expiration ===");
    resetCallCount();
    disableMockFailureMode();

    // Use a short session timeout so the token actually expires during the test.
    // Effective AT validity = sessionTimeoutSeconds - clockSkewSeconds(30).
    // Setting sessionTimeout = 32 gives us a 2-second token; we then sleep 3
    // seconds to trigger a real expiration-driven rotation (both local cache
    // AND InMemoryStore entry will be past their expiry epoch).
    int shortSessionTimeout = 32;

    // Default behaviour: NO tokenStore argument — TokenManager falls back
    // to its internal InMemoryTokenStore.
    TokenManager tm = check new (
        RTR_CLIENT_ID_INMEM, TEST_CLIENT_SECRET,
        TEST_SEED_REFRESH_TOKEN, MOCK_TOKEN_URL,
        shortSessionTimeout
    );

    // --- Phase 1: First call → HTTP refresh ---
    string firstToken = check tm.getAccessToken();
    test:assertTrue(firstToken.startsWith("AT_mock_"),
            "First access token must be issued by the mock: " + firstToken);
    test:assertEquals(getCallCount(), 1,
            "First getAccessToken() must trigger exactly 1 HTTP call");

    // --- Phase 2: Cached call → no HTTP ---
    string cachedToken = check tm.getAccessToken();
    test:assertEquals(cachedToken, firstToken,
            "Second call (within TTL) must return the CACHED token");
    test:assertEquals(getCallCount(), 1,
            "Cached call MUST NOT trigger a new HTTP call");

    // --- Phase 3: Simulate expiration via wall-clock sleep ---
    // The token was issued for ~2 effective seconds (32 - 30 clock skew).
    // Sleep 3 seconds to push both the local cache AND the store entry past
    // their expiry epochs. This forces a real rotation path through the code.
    log:printInfo("[TEST A] Sleeping 3s to let the access token expire naturally...");
    runtime:sleep(3);

    // --- Phase 4: Post-expiry call → fresh rotation ---
    string rotatedToken = check tm.getAccessToken();
    test:assertTrue(rotatedToken.startsWith("AT_mock_"),
            "Rotated access token must be issued by the mock: " + rotatedToken);
    test:assertNotEquals(rotatedToken, firstToken,
            "Rotated access token must differ from the first token");
    test:assertEquals(getCallCount(), 2,
            "Post-expiry call must trigger exactly 1 additional HTTP call (total 2)");

    // --- Phase 5: Verify RT rotation ---
    string currentRt = tm.getRefreshToken();
    test:assertTrue(currentRt.startsWith("RT_mock_"),
            "Refresh token must have been rotated to the mock-issued value: " + currentRt);
    test:assertNotEquals(currentRt, TEST_SEED_REFRESH_TOKEN,
            "Refresh token must no longer equal the seed value");

    log:printInfo("=== RTR TEST A PASSED ===");
}

// ==========================================================================
// TEST B: Redis Master Flow (Uncontested Lock Winner)
// ==========================================================================
// One TokenManager with a Redis-backed store, starting from an empty Redis.
// This simulates the "Master" path through the double-checked locking
// algorithm. Assertions:
//   - Exactly 1 HTTP call is made to Salesforce
//   - The new token data is persisted to Redis under the correct key
//   - The lock is released (re-acquirable) after the refresh completes
// ==========================================================================

@test:Config {
    groups: ["redis-integration"],
    dependsOn: [testMultiNodeRedisCoordination]
}
function testRedisMasterFlow() returns error? {
    log:printInfo("=== RTR TEST B: Redis Master Flow (Lock Winner) ===");
    resetCallCount();
    disableMockFailureMode();

    RedisTokenStore store = check new ();
    check store.flushAll();

    TokenManager master = check new (
        RTR_CLIENT_ID_MASTER, TEST_CLIENT_SECRET,
        TEST_SEED_REFRESH_TOKEN, MOCK_TOKEN_URL,
        TEST_SESSION_TIMEOUT,
        tokenStore = store
    );

    // --- Master refreshes (uncontested) ---
    string accessToken = check master.refreshAccessToken();
    test:assertTrue(accessToken.startsWith("AT_mock_"),
            "Master must receive a fresh token from the mock: " + accessToken);
    test:assertEquals(getCallCount(), 1,
            "Master must make EXACTLY 1 HTTP call to Salesforce");

    // --- Verify Redis persistence ---
    string storeKey = "sf_token:" + fingerprintToken(RTR_CLIENT_ID_MASTER);
    TokenData? persistedData = check store.getTokenData(storeKey);
    test:assertTrue(persistedData is TokenData,
            "Master must write token data to Redis after a successful refresh");
    if persistedData is TokenData {
        test:assertEquals(persistedData.accessToken, accessToken,
                "Redis must contain the exact AT returned to the master");
        test:assertTrue(persistedData.refreshToken.startsWith("RT_mock_"),
                "Redis must contain the rotated RT");
        test:assertTrue(persistedData.accessTokenExpiryEpoch > 0,
                "Redis must contain a positive AT expiry epoch");
    }

    // --- Verify lock was released (re-acquirable) ---
    boolean reAcquired = check store.acquireLock(storeKey, 30);
    test:assertTrue(reAcquired,
            "Master MUST release the lock after refresh — otherwise followers would deadlock");
    check store.releaseLock(storeKey);

    // Cleanup for next test
    check store.flushAll();
    check store.close();
    log:printInfo("=== RTR TEST B PASSED ===");
}

// ==========================================================================
// TEST C: Redis Worker Flow (Adopt-from-Store, Skip HTTP)
// ==========================================================================
// Pre-populate Redis with a VALID (non-expired) token to simulate a state
// where a previous master has already refreshed. A new "worker" TokenManager
// that starts up should detect the valid token in Redis and adopt it into
// its local memory WITHOUT calling Salesforce.
//
// This proves the double-checked locking "short-circuit" path: even if the
// worker wins the lock (because it's uncontested), the double-check read
// finds a valid token and skips the HTTP call entirely.
// ==========================================================================

@test:Config {
    groups: ["redis-integration"],
    dependsOn: [testRedisMasterFlow]
}
function testRedisWorkerFlow() returns error? {
    log:printInfo("=== RTR TEST C: Redis Worker Flow (Adopt From Store) ===");
    resetCallCount();
    disableMockFailureMode();

    RedisTokenStore store = check new ();
    check store.flushAll();

    // --- Pre-populate Redis with a valid token (as if a master just wrote it) ---
    string storeKey = "sf_token:" + fingerprintToken(RTR_CLIENT_ID_WORKER);
    [int, decimal] now = time:utcNow();
    TokenData prePopulated = {
        accessToken: "AT_prepopulated_by_master_xyz",
        refreshToken: "RT_prepopulated_by_master_xyz",
        accessTokenExpiryEpoch: now[0] + 600, // 10 more minutes of validity
        issuedAtEpoch: now[0],
        lastRefreshedAtEpoch: now[0]
    };
    check store.setTokenData(storeKey, prePopulated);

    // --- Worker starts up with an empty local cache ---
    // It will call refreshAccessToken(), acquire the (uncontested) lock,
    // read the store (double-check), find the valid token, and adopt it
    // instead of hitting Salesforce.
    TokenManager workerTm = check new (
        RTR_CLIENT_ID_WORKER, TEST_CLIENT_SECRET,
        TEST_SEED_REFRESH_TOKEN, MOCK_TOKEN_URL,
        TEST_SESSION_TIMEOUT,
        tokenStore = store
    );

    string adoptedToken = check workerTm.refreshAccessToken();

    // --- Assertions ---
    test:assertEquals(adoptedToken, "AT_prepopulated_by_master_xyz",
            "Worker must adopt the pre-populated token from Redis byte-for-byte");
    test:assertEquals(getCallCount(), 0,
            "Worker MUST NOT call Salesforce — a valid token already exists in Redis");

    // Subsequent getAccessToken() should also return the same token from the local cache
    string cachedAfterAdopt = check workerTm.getAccessToken();
    test:assertEquals(cachedAfterAdopt, "AT_prepopulated_by_master_xyz",
            "Post-adoption cache read must return the adopted token");
    test:assertEquals(getCallCount(), 0,
            "Still no HTTP call — token remains valid and cached");

    check store.flushAll();
    check store.close();
    log:printInfo("=== RTR TEST C PASSED ===");
}

// ==========================================================================
// TEST D: Cache-Poisoning Auto-Eviction on invalid_grant
// ==========================================================================
// Simulates the production disaster scenario:
//   1. Redis contains a dead token family (e.g., from an absolute session
//      timeout that silently revoked the entire RT chain).
//   2. A replica boots up, reads the dead token from Redis, and tries to
//      use it → Salesforce returns 400 invalid_grant.
//   3. Without auto-eviction, the dead token remains in Redis and the
//      replica crash-loops on every restart.
//
// The fix: on invalid_grant, the TokenManager must call
// `clearTokenStore()` which evicts both the data key and the lock key
// from the store. On the next restart, Redis is clean and the replica
// uses the fresh seed token from config.
//
// Assertions:
//   - refreshAccessToken() returns an error mentioning invalid_grant / 400
//   - clearTokenStore() succeeds
//   - Redis `data:` key is gone (getTokenData returns nil)
//   - Redis `lock:` key is gone (acquireLock returns true on clean slate)
// ==========================================================================

@test:Config {
    groups: ["redis-integration"],
    dependsOn: [testRedisWorkerFlow]
}
function testCachePoisoningAutoEviction() returns error? {
    log:printInfo("=== RTR TEST D: Cache Poisoning Auto-Eviction ===");
    resetCallCount();

    RedisTokenStore store = check new ();
    check store.flushAll();

    // --- Pre-populate Redis with a DEAD (expired) token ---
    // This simulates the scenario where a previous run's token family
    // was revoked by Salesforce (absolute session timeout) but the dead
    // state was never cleaned up from the distributed cache.
    string storeKey = "sf_token:" + fingerprintToken(RTR_CLIENT_ID_POISON);
    [int, decimal] now = time:utcNow();
    TokenData deadToken = {
        accessToken: "AT_dead_poisoned",
        refreshToken: "RT_dead_poisoned",
        accessTokenExpiryEpoch: now[0] - 10, // already expired
        issuedAtEpoch: now[0] - 910,
        lastRefreshedAtEpoch: now[0] - 910
    };
    check store.setTokenData(storeKey, deadToken);

    // Sanity-check: the dead token is indeed in Redis before the test runs
    TokenData? beforeState = check store.getTokenData(storeKey);
    test:assertTrue(beforeState is TokenData,
            "Pre-condition: dead token must exist in Redis before the test");

    // --- Enable failure mode on the mock ---
    // The mock will now return 400 { error: "invalid_grant", ... } for
    // any POST to the token endpoint.
    enableMockFailureMode("invalid_grant");

    // --- Boot a fresh TokenManager ---
    // It will see the dead token as expired (accessTokenExpiryEpoch < now),
    // attempt to refresh using the dead RT, and receive 400 invalid_grant.
    TokenManager tm = check new (
        RTR_CLIENT_ID_POISON, TEST_CLIENT_SECRET,
        TEST_SEED_REFRESH_TOKEN, MOCK_TOKEN_URL,
        TEST_SESSION_TIMEOUT,
        tokenStore = store
    );

    string|error refreshResult = tm.refreshAccessToken();

    // --- Assert the refresh failed with invalid_grant ---
    test:assertTrue(refreshResult is error,
            "Refresh must fail when the mock returns 400 invalid_grant");
    if refreshResult is error {
        string errMsg = refreshResult.message();
        boolean mentionsInvalidGrant = errMsg.includes("invalid_grant") || errMsg.includes("400");
        test:assertTrue(mentionsInvalidGrant,
                "Refresh error must mention invalid_grant or 400: " + errMsg);
        log:printInfo("[TEST D] Observed expected error from refresh: " + errMsg);
    }

    // --- Trigger the auto-eviction ---
    // In production this is called from Listener.getOAuth2Token() when it
    // detects "invalid_grant" in the error message. Here we call it directly
    // to unit-test the eviction contract on TokenManager.
    error? clearResult = tm.clearTokenStore();
    test:assertTrue(clearResult !is error,
            "clearTokenStore() must succeed: " +
            (clearResult is error ? clearResult.message() : "<ok>"));

    // --- Assert Redis is now EMPTY for this token family ---
    TokenData? afterState = check store.getTokenData(storeKey);
    test:assertTrue(afterState is (),
            "data: key MUST be evicted from Redis after clearTokenStore() — " +
            "cache poisoning protection is broken if this fails");

    // --- Assert lock key is also gone (re-acquirable from clean slate) ---
    boolean lockReacquired = check store.acquireLock(storeKey, 30);
    test:assertTrue(lockReacquired,
            "lock: key MUST also be evicted — acquireLock should succeed cleanly");
    check store.releaseLock(storeKey);

    log:printInfo("[TEST D] Cache poisoning auto-eviction verified — Redis is clean");

    // --- Cleanup: restore mock to success mode for any future tests ---
    disableMockFailureMode();
    check store.flushAll();
    check store.close();

    log:printInfo("=== RTR TEST D PASSED ===");
}
