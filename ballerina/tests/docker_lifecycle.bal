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
// Redis Availability Probe for Integration Tests
// ==========================================================================
//
// Container lifecycle is owned by Gradle (`startRedis` / `stopRedis` tasks in
// ballerina/build.gradle). This file only PROBES that Redis is reachable
// before the integration tests run and exposes `redisAvailable` so Redis-
// dependent tests can be skipped gracefully in environments without Docker
// (e.g. a dev laptop that skipped the Gradle startup path).
//
// Why `configurable` and not a mutable module variable:
//   `@test:Config { enable: <expr> }` is evaluated at test DISCOVERY time,
//   which runs before `@test:BeforeSuite`. Only `configurable` variables are
//   resolvable at that point — a mutable variable flipped by BeforeSuite
//   would still read its default value at discovery, silently excluding
//   every Redis-dependent test from the run.
//
// ==========================================================================

import ballerina/log;
import ballerina/tcp;
import ballerina/test;

const string REDIS_PROBE_HOST = "localhost";
const int REDIS_PROBE_PORT = 6379;

// Module-level flag read by Redis-dependent tests via
// `@test:Config { enable: redisAvailable }`.
//
// Default `true` so CI (where Gradle's `startRedis` task guarantees Redis is
// up) and local dev with Docker both work out of the box. Environments
// without Docker can override to false via:
//   - `ballerina/modules/utils/tests/Config.toml`:
//       [ballerinax.salesforce.utils]
//       redisAvailable = false
//   - or the env var `BAL_CONFIG_VAR_redisAvailable=false`.
public configurable boolean redisAvailable = true;

# Sanity probe: verifies Redis is reachable when `redisAvailable` is true.
# Does NOT start a container (Gradle owns lifecycle) and does NOT mutate the
# `redisAvailable` flag. If the probe fails while `redisAvailable` is true,
# the Redis-dependent tests will fail naturally with "connection refused" —
# which is the intended behaviour (a misconfiguration, not a silent skip).
@test:BeforeSuite
function probeRedisAvailability() returns error? {
    if !redisAvailable {
        log:printInfo("[RedisProbe] redisAvailable=false — Redis-integration tests are disabled by config.");
        return;
    }
    log:printInfo(string `[RedisProbe] Probing ${REDIS_PROBE_HOST}:${REDIS_PROBE_PORT}...`);
    tcp:Client|error tcpClient = new (REDIS_PROBE_HOST, REDIS_PROBE_PORT, timeout = 3);
    if tcpClient is error {
        log:printError("[RedisProbe] redisAvailable=true but Redis is NOT reachable on " +
                string `${REDIS_PROBE_HOST}:${REDIS_PROBE_PORT}. ` +
                "Ensure Gradle's `startRedis` task ran, or set `redisAvailable = false` " +
                "in tests/Config.toml to disable Redis-integration tests.",
                'error = tcpClient);
        return;
    }
    error? closeResult = tcpClient->close();
    if closeResult is error {
        log:printWarn("[RedisProbe] Probe socket close warning", 'error = closeResult);
    }
    log:printInfo("[RedisProbe] Redis is reachable.");
}
