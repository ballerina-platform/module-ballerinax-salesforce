// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.org).
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

import ballerina/crypto;
import ballerina/http;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/time;
import ballerina/url;

# Represents the token data stored and shared across replicas.
# Used by `TokenStore` implementations to persist and retrieve token state.
public type TokenData record {|
    # The current access token
    string accessToken;
    # The current refresh token (may have been rotated by Salesforce)
    string refreshToken;
    # Epoch seconds when the access token expires
    int accessTokenExpiryEpoch;
    # Server-reported issuance epoch (seconds) from the `issued_at` field of the token response
    int issuedAtEpoch;
    # Epoch seconds when the token data was last written to the store
    int lastRefreshedAtEpoch;
|};

# Pluggable token store interface for coordinating token lifecycle across
# multiple replicas (e.g., in Kubernetes). Implementations must be `isolated`.
#
# The default behaviour (when no `TokenStore` is provided) is an in-memory store
# that is scoped to the current process — suitable for single-replica deployments.
#
# For multi-replica deployments, provide an implementation backed by a distributed
# store (e.g., Redis) with advisory locking to prevent Token Replay Attacks caused
# by concurrent refresh-token usage.
public type TokenStore isolated object {

    # Attempts to acquire an advisory lock for token refresh coordination.
    # Only one replica should refresh at a time to prevent Token Replay Attacks.
    #
    # + lockKey - A unique key identifying the token family (e.g., client ID hash)
    # + ttlSeconds - Maximum time in seconds to hold the lock (auto-release safety net)
    # + return - `true` if the lock was acquired, `false` if another holder has it,
    #            or an `error` if the store is unreachable
    public isolated function acquireLock(string lockKey, int ttlSeconds) returns boolean|error;

    # Releases the advisory lock after a refresh cycle completes.
    #
    # + lockKey - The same key used in `acquireLock()`
    # + return - `()` on success, or an `error` if the release fails
    public isolated function releaseLock(string lockKey) returns error?;

    # Reads the current token data from the shared store.
    #
    # + key - A unique key identifying the token family
    # + return - The stored `TokenData`, `()` if no data exists yet, or an `error`
    public isolated function getTokenData(string key) returns TokenData?|error;

    # Writes updated token data to the shared store after a successful refresh.
    #
    # + key - A unique key identifying the token family
    # + data - The new token data to persist
    # + return - `()` on success, or an `error` if the write fails
    public isolated function setTokenData(string key, TokenData data) returns error?;
};

# Default in-memory token store for single-replica deployments.
# `acquireLock()` always succeeds (no contention in a single process).
# Token data is stored in-process memory — not shared across replicas.
public isolated class InMemoryTokenStore {
    *TokenStore;

    private TokenData? tokenData = ();

    public isolated function acquireLock(string lockKey, int ttlSeconds) returns boolean|error {
        // Single-process: lock always succeeds (Ballerina `lock` blocks handle concurrency).
        return true;
    }

    public isolated function releaseLock(string lockKey) returns error? {
        // No-op for in-memory store.
    }

    public isolated function getTokenData(string key) returns TokenData?|error {
        lock {
            return self.tokenData.cloneReadOnly();
        }
    }

    public isolated function setTokenData(string key, TokenData data) returns error? {
        lock {
            self.tokenData = data.cloneReadOnly();
        }
    }
}

# Manages OAuth2 token lifecycle with support for refresh token rotation.
# When Salesforce returns a new refresh token in the token response,
# the `TokenManager` captures it in memory and uses it for subsequent refreshes.
#
# When a `TokenStore` is provided, the manager coordinates with other replicas
# using advisory locking — only one replica refreshes at a time, preventing
# Token Replay Attacks in multi-replica Kubernetes deployments.
public isolated class TokenManager {

    private string accessToken;
    private string refreshToken;
    private int accessTokenExpiryEpoch;
    // Server-reported issuance epoch (seconds) of the most recently rotated refresh
    // token, derived from the `issued_at` field of the token response. -1 until the
    // first rotation occurs.
    private int rtIssuedAtEpoch;
    // Estimated RT policy window in seconds, used by getEstimatedRtSecondsLeft().
    // Defaults to sessionTimeoutSeconds; updated on each rotation.
    private int rtWindowSeconds;
    // Generation counters for log correlation — matches AT#N / RT#N in the token flow diagram.
    // atGeneration increments on every successful token refresh (AT#1, AT#2, ...).
    // rtGeneration tracks the current RT index: 0 = seed RT, 1 = first rotation, etc.
    private int atGeneration;
    private int rtGeneration;
    private final string clientId;
    private final string clientSecret;
    private final string tokenUrl;
    private final http:Client tokenClient;
    private final int clockSkewSeconds = 30;
    // Lock TTL in seconds — safety net to auto-release if a replica crashes mid-refresh.
    private final int lockTtlSeconds = 30;
    // Salesforce does not return expires_in in token responses. This value is used
    // as the assumed session timeout for AT expiry and RT window estimation.
    // Set from ListenerConfig.sessionTimeout — configure it to match your Salesforce
    // org's Session Settings (Setup > Session Settings > Session Timeout).
    private final int sessionTimeoutSeconds;
    // Pluggable token store for multi-replica coordination.
    // When set, acquires an advisory lock before refreshing and reads/writes
    // token state from the shared store.
    private final TokenStore tokenStore;
    // Unique key for the token family, derived from the client ID.
    // Used as the lock key and store key for distributed coordination.
    private final string storeKey;

    # Initializes the TokenManager.
    #
    # + clientId - OAuth2 client ID
    # + clientSecret - OAuth2 client secret
    # + refreshToken - Initial refresh token (seed token)
    # + tokenUrl - Salesforce token endpoint URL
    # + sessionTimeoutSeconds - Salesforce session timeout in seconds (from ListenerConfig.sessionTimeout)
    # + tokenStore - Optional pluggable token store for multi-replica coordination
    # + return - An error if the HTTP client cannot be created
    public isolated function init(string clientId, string clientSecret,
            string refreshToken, string tokenUrl,
            int sessionTimeoutSeconds = 900,
            TokenStore? tokenStore = ()) returns error? {
        self.clientId = clientId;
        self.clientSecret = clientSecret;
        self.refreshToken = refreshToken;
        self.tokenUrl = tokenUrl;
        self.sessionTimeoutSeconds = sessionTimeoutSeconds;
        self.accessToken = "";
        self.accessTokenExpiryEpoch = -1;
        self.rtIssuedAtEpoch = -1;
        self.rtWindowSeconds = sessionTimeoutSeconds;
        self.atGeneration = 0;
        self.rtGeneration = 0;
        if tokenStore is TokenStore {
            self.tokenStore = tokenStore;
        } else {
            InMemoryTokenStore defaultStore = new;
            self.tokenStore = defaultStore;
        }
        self.storeKey = "sf_token:" + fingerprintToken(clientId);
        self.tokenClient = check new (tokenUrl);
    }

    # Returns a valid access token, refreshing proactively if expired or about to expire.
    #
    # + return - The access token string or an error
    public isolated function getAccessToken() returns string|error {
        lock {
            [int, decimal] currentTime = time:utcNow();
            if self.accessToken != "" && currentTime[0] < self.accessTokenExpiryEpoch {
                return self.accessToken;
            }
        }
        return self.refreshAccessToken();
    }

    # Refreshes the access token by calling the Salesforce token endpoint.
    # Captures the rotated refresh token if present in the response.
    #
    # When a `TokenStore` is configured, uses distributed double-checked locking:
    # 1. Acquire advisory lock (prevents concurrent refreshes across replicas)
    # 2. Check store for a recently refreshed token (another replica may have refreshed)
    # 3. If store token is still valid, adopt it (skip HTTP call)
    # 4. Otherwise, call Salesforce token endpoint and write result to store
    # 5. Release advisory lock
    #
    # + return - The new access token or an error
    public isolated function refreshAccessToken() returns string|error {
        string storeKey;
        lock {
            storeKey = self.storeKey;
        }

        // --- Phase 1: Acquire advisory lock ---
        boolean acquired = check self.tokenStore.acquireLock(storeKey, self.lockTtlSeconds);
        if !acquired {
            // Another replica holds the lock — poll the store with exponential backoff.
            // The holder is expected to finish within a few hundred milliseconds
            // (HTTP call to Salesforce + Redis write). We poll up to ~10 seconds
            // before giving up and attempting to acquire the lock ourselves.
            log:printInfo("Token refresh lock held by another replica — entering wait loop");

            string|error waitResult = self.waitForStoreUpdate(storeKey);
            if waitResult is string {
                return waitResult;
            }

            // Store never got a valid token — the holder may have crashed.
            // Attempt to acquire the lock ourselves for a self-healing refresh.
            log:printWarn("Wait loop exhausted — attempting to acquire lock for self-healing refresh");
            acquired = check self.tokenStore.acquireLock(storeKey, self.lockTtlSeconds);
            if !acquired {
                return error("Token refresh timed out: another replica held the lock for over " +
                        "10 seconds and did not write a valid token to the store");
            }
        }

        // Lock acquired — proceed with double-checked locking.
        string|error result = self.doRefreshWithLock(storeKey);

        // --- Phase 5: Release lock (always, even on error) ---
        error? releaseErr = self.tokenStore.releaseLock(storeKey);
        if releaseErr is error {
            log:printWarn("Failed to release token refresh lock", 'error = releaseErr);
        }

        return result;
    }

    # Polls the token store with exponential backoff, waiting for the lock holder
    # to write a valid (non-expired) token. Returns the access token if one appears,
    # or an error if the timeout is exhausted.
    #
    # Backoff schedule: 100ms, 200ms, 400ms, 800ms, 1000ms, 1000ms, 1000ms, ...
    # Total wait budget: ~10 seconds (configurable via maxWaitSeconds).
    #
    # + storeKey - The token family key to poll in the store
    # + return - The adopted access token, or an error if timeout expired
    private isolated function waitForStoreUpdate(string storeKey) returns string|error {
        // Maximum total wall-clock time to spend waiting (seconds).
        int maxWaitSeconds = 10;
        // Initial sleep between polls (seconds as decimal).
        decimal sleepInterval = 0.1;
        // Maximum per-poll sleep (cap for exponential backoff).
        decimal maxSleepInterval = 1.0;
        // Backoff multiplier.
        decimal backoffFactor = 2.0;

        [int, decimal] startTime = time:utcNow();
        int attempt = 0;

        while true {
            attempt = attempt + 1;
            runtime:sleep(sleepInterval);

            // Check elapsed wall-clock time.
            [int, decimal] now = time:utcNow();
            int elapsedSeconds = now[0] - startTime[0];
            if elapsedSeconds >= maxWaitSeconds {
                log:printWarn(string `Store poll timeout after ${attempt} attempts (${elapsedSeconds}s elapsed)`);
                return error("Store poll timeout");
            }

            // Read from store — another replica may have written fresh token data.
            TokenData? storeData = check self.tokenStore.getTokenData(storeKey);
            if storeData is TokenData {
                if storeData.accessTokenExpiryEpoch > now[0] {
                    self.adoptStoreData(storeData);
                    log:printInfo(
                        string `Adopted token from store after ${attempt} poll(s) (${elapsedSeconds}s wait)`,
                        fingerprint = fingerprintToken(storeData.accessToken),
                        expiresInSeconds = storeData.accessTokenExpiryEpoch - now[0]);
                    return storeData.accessToken;
                }
            }

            // Exponential backoff with cap.
            decimal nextInterval = sleepInterval * backoffFactor;
            sleepInterval = nextInterval < maxSleepInterval ? nextInterval : maxSleepInterval;
        }
        // Unreachable — loop exits via return or error above.
    }

    # Core refresh logic executed while holding the advisory lock.
    # Implements the double-checked locking pattern with the token store.
    private isolated function doRefreshWithLock(string storeKey) returns string|error {
        lock {
            // --- Phase 2: Double-check — read from store ---
            TokenData? storeData = check self.tokenStore.getTokenData(storeKey);
            if storeData is TokenData {
                [int, decimal] now = time:utcNow();
                if storeData.accessTokenExpiryEpoch > now[0] {
                    // Another replica refreshed while we waited for the lock.
                    self.accessToken = storeData.accessToken;
                    self.refreshToken = storeData.refreshToken;
                    self.accessTokenExpiryEpoch = storeData.accessTokenExpiryEpoch;
                    if storeData.issuedAtEpoch > 0 {
                        self.rtIssuedAtEpoch = storeData.issuedAtEpoch;
                    }
                    log:printInfo("Adopted token from store (refreshed by another replica)",
                            fingerprint = fingerprintToken(storeData.accessToken),
                            expiresInSeconds = storeData.accessTokenExpiryEpoch - now[0]);
                    return storeData.accessToken;
                }
                // Store token expired — use the store's refresh token (may be more recent
                // than ours if another replica rotated it previously).
                if storeData.refreshToken != "" && storeData.refreshToken != self.refreshToken {
                    log:printInfo("Adopting newer refresh token from store before refreshing",
                            localFingerprint = fingerprintToken(self.refreshToken),
                            storeFingerprint = fingerprintToken(storeData.refreshToken));
                    self.refreshToken = storeData.refreshToken;
                }
            }

            // --- Phase 3: Call Salesforce token endpoint ---
            string currentRefreshToken = self.refreshToken;

            // URL-encode parameter values to handle special characters in secrets.
            string encodedRefreshToken = check url:encode(currentRefreshToken, "UTF-8");
            string encodedClientId = check url:encode(self.clientId, "UTF-8");
            string encodedClientSecret = check url:encode(self.clientSecret, "UTF-8");
            string payload = string `grant_type=refresh_token&refresh_token=${encodedRefreshToken}`
                + string `&client_id=${encodedClientId}&client_secret=${encodedClientSecret}`;

            http:Response response = check self.tokenClient->post("", payload,
                mediaType = "application/x-www-form-urlencoded");

            if response.statusCode != 200 {
                json|error errBody = response.getJsonPayload();
                string errMsg = "Failed to refresh access token.";
                if errBody is json {
                    errMsg = errMsg + " Response: " + errBody.toJsonString();
                }
                log:printError("Token refresh failed",
                    refreshTokenFingerprint = fingerprintToken(currentRefreshToken),
                    statusCode = response.statusCode);
                return error(errMsg);
            }

            json body = check response.getJsonPayload();
            map<json> bodyMap = check body.ensureType();

            string newAccessToken = check (check body.access_token).ensureType(string);

            // Capture rotated refresh token if present in the response.
            string? rotatedRefreshToken = ();
            if bodyMap.hasKey("refresh_token") {
                json rtValue = bodyMap.get("refresh_token");
                string|error rtStr = rtValue.ensureType(string);
                if rtStr is string && rtStr != "" {
                    rotatedRefreshToken = rtStr;
                } else if rtStr is error {
                    log:printError("refresh_token field exists but conversion to string failed",
                        'error = rtStr);
                }
            }

            // Extract server-reported issuance epoch from `issued_at` (milliseconds).
            // Salesforce does not return expires_in; AT expiry is derived from issued_at
            // plus the configured session timeout.
            int newRtIssuedAtEpoch = -1;
            json|error issuedAtField = body.issued_at;
            if issuedAtField is json {
                string|error issuedAtStr = issuedAtField.ensureType(string);
                if issuedAtStr is string {
                    int|error issuedAtMs = int:fromString(issuedAtStr);
                    if issuedAtMs is int {
                        newRtIssuedAtEpoch = issuedAtMs / 1000;
                    }
                }
            }

            [int, decimal] currentTime = time:utcNow();
            int issuedAtEpoch = newRtIssuedAtEpoch > 0 ? newRtIssuedAtEpoch : currentTime[0];
            if rotatedRefreshToken is string {
                self.rtGeneration = self.rtGeneration + 1;
                self.refreshToken = rotatedRefreshToken;
                self.rtIssuedAtEpoch = issuedAtEpoch;
                self.rtWindowSeconds = self.sessionTimeoutSeconds;
            }
            self.atGeneration = self.atGeneration + 1;
            self.accessToken = newAccessToken;
            self.accessTokenExpiryEpoch = issuedAtEpoch + self.sessionTimeoutSeconds - self.clockSkewSeconds;

            int validForMinutes = (self.accessTokenExpiryEpoch - issuedAtEpoch) / 60;
            log:printInfo(string `AT#${self.atGeneration} issued`,
                fingerprint = fingerprintToken(newAccessToken),
                validForMinutes = validForMinutes,
                sessionTimeoutAssumptionMinutes = self.sessionTimeoutSeconds / 60);

            if rotatedRefreshToken is string {
                log:printInfo(string `RT#${self.rtGeneration - 1} → RT#${self.rtGeneration} (Salesforce rotated refresh token)`,
                    previousFingerprint = fingerprintToken(currentRefreshToken),
                    newFingerprint = fingerprintToken(<string>rotatedRefreshToken));
            } else {
                log:printInfo("No refresh token rotation in response — existing RT unchanged",
                    rtGeneration = self.rtGeneration,
                    fingerprint = fingerprintToken(currentRefreshToken));
            }

            // --- Phase 4: Write updated token data to store ---
            TokenData updatedData = {
                accessToken: newAccessToken,
                refreshToken: self.refreshToken,
                accessTokenExpiryEpoch: self.accessTokenExpiryEpoch,
                issuedAtEpoch: issuedAtEpoch,
                lastRefreshedAtEpoch: currentTime[0]
            };
            error? storeErr = self.tokenStore.setTokenData(storeKey, updatedData);
            if storeErr is error {
                log:printWarn("Failed to write token data to store — other replicas may not see the update",
                        'error = storeErr);
            }

            return newAccessToken;
        }
    }

    # Adopts token data from the shared store into local state.
    private isolated function adoptStoreData(TokenData data) {
        lock {
            self.accessToken = data.accessToken;
            self.refreshToken = data.refreshToken;
            self.accessTokenExpiryEpoch = data.accessTokenExpiryEpoch;
            if data.issuedAtEpoch > 0 {
                self.rtIssuedAtEpoch = data.issuedAtEpoch;
            }
        }
    }

    # Clears the cached access token, forcing the next `getAccessToken()` call to obtain a fresh one.
    public isolated function invalidateAccessToken() {
        lock {
            self.accessToken = "";
            self.accessTokenExpiryEpoch = -1;
        }
    }

    # Returns seconds remaining until the cached access token expires.
    # Returns 0 if no token is cached or token is already expired.
    public isolated function getSecondsUntilExpiry() returns int {
        lock {
            if self.accessTokenExpiryEpoch < 0 {
                return 0;
            }
            [int, decimal] now = time:utcNow();
            int remaining = self.accessTokenExpiryEpoch - now[0];
            return remaining > 0 ? remaining : 0;
        }
    }

    # Returns an estimate of seconds remaining until the current refresh token expires,
    # based on the `issued_at` epoch from the most recent rotation response and the
    # configured session timeout. Returns -1 if no rotation has occurred yet (seed token still in use).
    public isolated function getEstimatedRtSecondsLeft() returns int {
        lock {
            if self.rtIssuedAtEpoch < 0 {
                return -1;
            }
            [int, decimal] now = time:utcNow();
            int remaining = (self.rtIssuedAtEpoch + self.rtWindowSeconds) - now[0];
            return remaining > 0 ? remaining : 0;
        }
    }

    # Returns the current in-memory refresh token.
    public isolated function getRefreshToken() returns string {
        lock {
            return self.refreshToken;
        }
    }

    # Replaces the in-memory refresh token and clears the cached access token.
    # Resets RT issuance tracking so `getEstimatedRtSecondsLeft()` returns -1
    # until the next rotation response arrives.
    #
    # + newRefreshToken - The new refresh token to install
    public isolated function updateRefreshToken(string newRefreshToken) {
        lock {
            self.refreshToken = newRefreshToken;
            self.accessToken = "";
            self.accessTokenExpiryEpoch = -1;
            self.rtIssuedAtEpoch = -1;
            self.rtWindowSeconds = self.sessionTimeoutSeconds;
            self.atGeneration = 0;
            self.rtGeneration = 0;
        }
        log:printInfo("New seed refresh token installed (RT#0) — generation counters reset",
            newSeedFingerprint = fingerprintToken(newRefreshToken));
    }

}

# Returns a short non-reversible fingerprint (first 12 hex chars of SHA-256).
isolated function fingerprintToken(string token) returns string {
    string fingerprint = crypto:hashSha256(token.toBytes()).toBase16();
    return fingerprint.substring(0, 12);
}
