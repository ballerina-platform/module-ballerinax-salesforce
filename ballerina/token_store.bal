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

# Provides the pluggable token store contract and default in-memory
# implementation for Salesforce OAuth2 Refresh Token Rotation (RTR).
# Import this module to implement a custom token store (e.g., Redis-backed)
# for multi-replica CDC listener deployments.

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
    # or an `error` if the store is unreachable
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

    # Removes token data and its associated lock from the shared store.
    # Called when the token family is permanently invalidated (e.g., Salesforce
    # returns `invalid_grant` after absolute session timeout expiry).
    #
    # This prevents "cache poisoning" — without eviction, a restarting replica
    # would read the dead token from the store, ignore the fresh seed token
    # from its configuration, and crash in a loop.
    #
    # + key - A unique key identifying the token family
    # + return - `()` on success, or an `error` if the delete fails
    public isolated function clearTokenData(string key) returns error?;
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

    public isolated function clearTokenData(string key) returns error? {
        lock {
            self.tokenData = ();
        }
    }
}
