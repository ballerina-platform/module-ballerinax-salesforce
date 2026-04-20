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

// =============================================================================
// Distributed CDC Listener with Custom TokenStore
// =============================================================================
//
// Demonstrates a production-ready CDC listener for multi-replica / Kubernetes
// deployments where multiple pods share the same Salesforce Connected App.
//
// The core problem: Token Replay Attack
// ------------------------------------
// When Salesforce enables Refresh Token Rotation (RTR), every token exchange
// invalidates the previous refresh token and issues a new one.  If two pods
// simultaneously call the token endpoint with the same refresh token:
//
//   Pod A → POST /oauth2/token (RT_seed)  → AT_1 + RT_1  ✅
//   Pod B → POST /oauth2/token (RT_seed)  → 400 invalid_grant ❌
//                                           (RT_seed already rotated)
//   Salesforce then revokes the ENTIRE token family → both pods crash-loop.
//
// The solution: distributed double-checked locking
// ------------------------------------------------
// All pods share a single `salesforce:TokenStore` backed by a distributed
// store (Redis, a relational database, etc.).  The TokenStore enforces:
//
//   1. Advisory lock (SETNX / SELECT FOR UPDATE) — only one pod refreshes.
//   2. Double-check read — the lock winner reads the store before calling
//      Salesforce; if a peer just refreshed, the winner adopts that token
//      and releases the lock without making an HTTP call.
//   3. Atomic write — the winner writes AT+RT to the shared store.
//   4. Losers adopt — pods that failed to acquire the lock poll the store
//      with exponential backoff and adopt the winner's result.
//
// This file contains:
//   - `SharedTokenStore`: a fully compilable, self-contained TokenStore
//     implementation backed by Ballerina's built-in isolated maps.
//     This acts as a reference / test double for the real Redis or DB
//     implementation you would use in production.
//   - Instructions (in comments) for replacing each method with real Redis
//     calls when you bring in the `ballerinax/redis` dependency.
//   - The listener configuration wiring that plugs the store into the CDC
//     listener.
//
// Replacing the stub with a real Redis implementation
// ---------------------------------------------------
// 1. Add to Ballerina.toml:
//      [[dependency]]
//      org   = "ballerinax"
//      name  = "redis"
//      version = "<latest>"
//
// 2. Add `import ballerinax/redis;` to this file.
//
// 3. Replace the `lock { ... }` bodies in each method with the corresponding
//    Redis calls shown in the comments inside each method.
//
// For a battle-tested reference, the integration test suite at
// ballerina/modules/utils/tests/redis_token_store.bal contains a
// complete Redis-backed TokenStore verified against a live Redis instance.
// =============================================================================

import ballerina/http;
import ballerina/log;
import ballerinax/salesforce;

// ---------------------------------------------------------------------------
// Credentials — supplied via Config.toml (never hardcode in source)
// ---------------------------------------------------------------------------
configurable string baseUrl = ?;
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;
configurable string tokenUrl = ?;

// defaultTokenExpTime must match your Salesforce org's Session Timeout setting.
// Navigate to: Setup → Security → Session Settings → Timeout Value.
configurable int sessionTimeoutSeconds = 3600;

// ---------------------------------------------------------------------------
// SharedTokenStore
// ---------------------------------------------------------------------------
// A fully compilable TokenStore that uses isolated Ballerina maps as its
// backing store.  This is deliberately self-contained so the example compiles
// and runs without any external infrastructure.
//
// In a real Kubernetes deployment, replace the `lock { ... }` bodies in each
// method with calls to your Redis client or JDBC connection pool.  The method
// signatures and contract (described in the doc comments) stay the same.
public isolated class SharedTokenStore {
    *salesforce:TokenStore;

    // In-memory backing store (replace with Redis client / DB connection pool)
    private map<salesforce:TokenData> dataStore = {};
    private map<boolean> lockStore = {};

    // -------------------------------------------------------------------------
    // acquireLock
    // -------------------------------------------------------------------------
    // Atomically sets a lock key if it does not already exist.
    // Returns true if this caller owns the lock, false if another holder has it.
    //
    // Redis equivalent (atomic, no race condition):
    //   boolean acquired = check redisClient->setNx("lock:" + lockKey, "1");
    //   if acquired {
    //       _ = check redisClient->expire("lock:" + lockKey, ttlSeconds);
    //   }
    //   return acquired;
    //
    // JDBC equivalent:
    //   INSERT INTO token_locks (lock_key, acquired_at)
    //   VALUES (lockKey, NOW())
    //   ON CONFLICT DO NOTHING;
    //   -- check affected rows: 1 = acquired, 0 = held by another
    public isolated function acquireLock(string lockKey, int ttlSeconds) returns boolean|error {
        lock {
            if self.lockStore.hasKey(lockKey) {
                return false; // lock already held
            }
            self.lockStore[lockKey] = true;
            return true;
        }
    }

    // -------------------------------------------------------------------------
    // releaseLock
    // -------------------------------------------------------------------------
    // Deletes the lock key, allowing other replicas to acquire it.
    //
    // Redis equivalent:
    //   _ = check redisClient->del(["lock:" + lockKey]);
    //
    // JDBC equivalent:
    //   DELETE FROM token_locks WHERE lock_key = lockKey;
    public isolated function releaseLock(string lockKey) returns error? {
        lock {
            _ = self.lockStore.remove(lockKey);
        }
    }

    // -------------------------------------------------------------------------
    // getTokenData
    // -------------------------------------------------------------------------
    // Reads the current token data for the given key.
    // Returns () if no data has been written yet (first startup).
    //
    // Redis equivalent:
    //   string|redis:Error? raw = redisClient->get("data:" + key);
    //   if raw is string {
    //       json jsonData = check raw.fromJsonString();
    //       return check jsonData.cloneWithType(salesforce:TokenData);
    //   }
    //   return ();
    //
    // JDBC equivalent:
    //   SELECT access_token, refresh_token, expiry_epoch, issued_at_epoch, last_refreshed_epoch
    //   FROM token_store WHERE store_key = key;
    public isolated function getTokenData(string key) returns salesforce:TokenData?|error {
        lock {
            salesforce:TokenData? data = self.dataStore[key];
            return data.cloneReadOnly();
        }
    }

    // -------------------------------------------------------------------------
    // setTokenData
    // -------------------------------------------------------------------------
    // Persists updated token data after a successful refresh cycle.
    // Called by the winning replica immediately after receiving AT+RT from
    // Salesforce and before releasing the advisory lock.
    //
    // Redis equivalent:
    //   _ = check redisClient->set("data:" + key, data.toJsonString());
    //
    // JDBC equivalent:
    //   INSERT INTO token_store (store_key, access_token, refresh_token, ...)
    //   VALUES (key, data.accessToken, data.refreshToken, ...)
    //   ON CONFLICT (store_key) DO UPDATE SET ...;
    public isolated function setTokenData(string key, salesforce:TokenData data) returns error? {
        lock {
            self.dataStore[key] = data.cloneReadOnly();
        }
    }

    // -------------------------------------------------------------------------
    // clearTokenData
    // -------------------------------------------------------------------------
    // Evicts token data AND the associated lock for this key.
    //
    // This is called on `invalid_grant` to prevent cache poisoning: without
    // eviction, a restarting replica would read the dead token from the store,
    // ignore the fresh seed token in its config, and crash-loop indefinitely.
    //
    // Redis equivalent:
    //   _ = check redisClient->del(["data:" + key, "lock:" + key]);
    //
    // JDBC equivalent:
    //   DELETE FROM token_store WHERE store_key = key;
    //   DELETE FROM token_locks WHERE lock_key = key;
    public isolated function clearTokenData(string key) returns error? {
        lock {
            _ = self.dataStore.remove(key);
            _ = self.lockStore.remove(key);
            log:printInfo("Token data evicted from shared store (cache poisoning prevention)",
                    storeKey = key);
        }
    }
}

// ---------------------------------------------------------------------------
// Shared store instance (one per process; replace with Redis client in prod)
// ---------------------------------------------------------------------------
// In a real Kubernetes deployment this would be:
//
//   final salesforce:TokenStore sharedStore = check new MyRedisTokenStore();
//
// where MyRedisTokenStore holds a `final redis:Client redisClient` field that
// connects to the cluster-wide Redis instance (e.g., Redis Sentinel or Cluster).
// All pods point at the SAME Redis — that is what makes the locking effective.
final salesforce:TokenStore sharedStore = new SharedTokenStore();

// ---------------------------------------------------------------------------
// Listener configuration
// ---------------------------------------------------------------------------
salesforce:RestBasedListenerConfig listenerConfig = {
    baseUrl: baseUrl,
    auth: <http:OAuth2RefreshTokenGrantConfig>{
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: tokenUrl,
        defaultTokenExpTime: <decimal>sessionTimeoutSeconds
    },
    // Plug in the shared store. The connector's TokenManager will use it for
    // distributed advisory locking on every token refresh cycle.
    tokenStore: sharedStore
};

listener salesforce:Listener eventListener = new (listenerConfig);

// ---------------------------------------------------------------------------
// CDC service
// ---------------------------------------------------------------------------
service "/data/ChangeEvents" on eventListener {

    remote function onCreate(salesforce:EventData payload) {
        log:printInfo("CDC onCreate received",
                entityName = payload.metadata?.entityName ?: "unknown");
    }

    remote isolated function onUpdate(salesforce:EventData payload) {
        log:printInfo("CDC onUpdate received",
                entityName = payload.metadata?.entityName ?: "unknown",
                changedFields = payload.changedData.keys().toString());
    }

    remote function onDelete(salesforce:EventData payload) {
        log:printInfo("CDC onDelete received",
                entityName = payload.metadata?.entityName ?: "unknown");
    }

    remote function onRestore(salesforce:EventData payload) {
        log:printInfo("CDC onRestore received",
                entityName = payload.metadata?.entityName ?: "unknown");
    }
}

// ---------------------------------------------------------------------------
// Module-level init
// ---------------------------------------------------------------------------
function init() returns error? {
    log:printInfo("Starting Salesforce CDC listener (distributed / shared TokenStore)",
            baseUrl = baseUrl,
            channel = "/data/ChangeEvents",
            sessionTimeoutSeconds = sessionTimeoutSeconds,
            storeType = "SharedTokenStore (replace with RedisTokenStore for K8s)");
}
