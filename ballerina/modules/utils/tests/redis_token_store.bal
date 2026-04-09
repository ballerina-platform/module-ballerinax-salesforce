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

// Redis-backed TokenStore implementation for integration tests.
// Uses SETNX + EXPIRE for advisory locking and JSON serialization for token data.
//
// This implementation proves that distributed coordination via Redis prevents
// Token Replay Attacks when multiple replicas share a single Salesforce
// Connected App.
//
// Since adding `ballerinax/redis` as a dependency is not desired for the
// main connector, this file lives ONLY in the tests/ directory.

import ballerina/log;
import ballerinax/redis;

const string REDIS_HOST = "localhost";
const int REDIS_PORT = 6379;

// Redis-backed distributed TokenStore.
// Uses Redis SETNX + EXPIRE for advisory locking (distributed mutex)
// and stores TokenData as a JSON string under a namespaced key.
public isolated class RedisTokenStore {
    *TokenStore;

    private final redis:Client redisClient;

    public isolated function init() returns error? {
        redis:ConnectionConfig config = {
            connection: {
                host: REDIS_HOST,
                port: REDIS_PORT
            }
        };
        self.redisClient = check new (config);
    }

    // Acquires an advisory lock using SETNX + EXPIRE.
    // Returns true if acquired, false if another holder has it.
    //
    // API reference (ballerinax/redis:3.2.1):
    //   setNx(string key, string value) returns boolean|Error
    //   expire(string key, int seconds) returns boolean|Error
    //
    // Note: This two-step approach has a tiny race between SETNX and EXPIRE.
    // For production, use a Lua script or Redlock for atomicity.
    // Acceptable for integration tests.
    public isolated function acquireLock(string lockKey, int ttlSeconds) returns boolean|error {
        string lockRedisKey = string `lock:${lockKey}`;
        boolean didSet = check self.redisClient->setNx(lockRedisKey, "locked");
        if didSet {
            // Set TTL for auto-release safety net (if holder crashes mid-refresh)
            _ = check self.redisClient->expire(lockRedisKey, ttlSeconds);
            log:printDebug("[RedisTokenStore] Lock acquired", lockKey = lockRedisKey);
            return true;
        }
        log:printDebug("[RedisTokenStore] Lock NOT acquired (held by another)", lockKey = lockRedisKey);
        return false;
    }

    // Releases the advisory lock by deleting the key.
    //
    // API reference: del(string[] keys) returns int|Error
    public isolated function releaseLock(string lockKey) returns error? {
        string lockRedisKey = string `lock:${lockKey}`;
        _ = check self.redisClient->del([lockRedisKey]);
        log:printDebug("[RedisTokenStore] Lock released", lockKey = lockRedisKey);
    }

    // Reads token data from Redis. Stored as a JSON string.
    //
    // API reference: get(string key) returns string|Error?
    //   Returns nil (()) if the key does not exist.
    public isolated function getTokenData(string key) returns TokenData?|error {
        string dataKey = "data:" + key;
        string|redis:Error? result = self.redisClient->get(dataKey);
        if result is redis:Error {
            // Connection error or similar — propagate
            return error(result.message());
        }
        if result is () || result == "" {
            return ();
        }
        json jsonData = check result.fromJsonString();
        TokenData data = check jsonData.cloneWithType(TokenData);
        return data;
    }

    // Writes token data to Redis as a JSON string.
    //
    // API reference: set(string key, string value) returns string|Error
    public isolated function setTokenData(string key, TokenData data) returns error? {
        string dataKey = "data:" + key;
        string jsonStr = data.toJsonString();
        _ = check self.redisClient->set(dataKey, jsonStr);
        log:printDebug("[RedisTokenStore] Token data written to store", dataKey = dataKey);
    }

    // Removes token data and its associated lock from Redis.
    // Called on invalid_grant to prevent cache poisoning — ensures the next
    // boot uses the fresh seed token from config instead of the dead cached one.
    //
    // Deletes both the data key and the lock key for the given token family.
    public isolated function clearTokenData(string key) returns error? {
        string dataKey = "data:" + key;
        string lockKey = "lock:" + key;
        _ = check self.redisClient->del([dataKey, lockKey]);
        log:printDebug("[RedisTokenStore] Token data evicted (cache poisoning prevention)",
                dataKey = dataKey, lockKey = lockKey);
    }

    // Flushes all test-namespaced keys from Redis (for test cleanup).
    public isolated function flushAll() returns error? {
        string[]|redis:Error lockKeys = self.redisClient->keys("lock:*");
        if lockKeys is string[] && lockKeys.length() > 0 {
            _ = check self.redisClient->del(lockKeys);
        }
        string[]|redis:Error dataKeys = self.redisClient->keys("data:*");
        if dataKeys is string[] && dataKeys.length() > 0 {
            _ = check self.redisClient->del(dataKeys);
        }
        log:printDebug("[RedisTokenStore] Test keys flushed");
    }

    // Closes the Redis connection.
    //
    // API reference: close() returns Error?  (non-remote method)
    public isolated function close() returns error? {
        check self.redisClient.close();
    }
}
