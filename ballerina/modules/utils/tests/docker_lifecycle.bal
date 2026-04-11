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

// ==========================================================================
// Docker Lifecycle for Redis Integration Tests
// ==========================================================================
//
// Automates the lifecycle of a disposable Redis container used by the
// Refresh Token Rotation (RTR) integration tests. Runs `docker run` in
// @test:BeforeSuite and `docker rm -f` in @test:AfterSuite via `os:exec`.
//
// CI/CD SAFETY CONTRACT: infrastructure errors are NEVER swallowed. If
// Docker is missing, the daemon is down, the image cannot be pulled, or
// the container fails to start for any reason, BeforeSuite returns the
// error and the entire test run fails. This prevents "false pass"
// outcomes where Redis-dependent tests would silently skip and mislead
// the CI dashboard into thinking the suite is green.
// ==========================================================================

import ballerina/lang.runtime;
import ballerina/log;
import ballerina/os;
import ballerina/test;

const string REDIS_CONTAINER_NAME = "sf-redis-test";
const string REDIS_IMAGE = "redis:7-alpine";
const int REDIS_HOST_PORT = 6379;

# Starts a disposable Redis Docker container before any test in the suite runs.
# Hard-fails the suite if `docker` is missing, the daemon is unreachable,
# or the container does not start cleanly. This is intentional — Redis is
# a required piece of integration infrastructure for the `redis-integration`
# test group, and silently skipping its tests would be a CI/CD safety hazard.
@test:BeforeSuite
function startRedisContainer() returns error? {
    log:printInfo("[Docker] Starting Redis test container for RTR integration tests...");

    // --- Step 1: Idempotent cleanup of any pre-existing container ---
    // If a previous run left a container behind (e.g. after a Ctrl-C), remove
    // it. We `check` this call so that a missing `docker` binary fails fast
    // with a clear error rather than silently continuing.
    os:Process cleanupProc = check os:exec({
        value: "docker",
        arguments: ["rm", "-f", REDIS_CONTAINER_NAME]
    });
    int _ = check cleanupProc.waitForExit();

    // --- Step 2: Start a fresh Redis container ---
    os:Process startProc = check os:exec({
        value: "docker",
        arguments: [
            "run",
            "-d",
            "-p",
            string `${REDIS_HOST_PORT}:6379`,
            "--name",
            REDIS_CONTAINER_NAME,
            REDIS_IMAGE
        ]
    });
    int startExitCode = check startProc.waitForExit();
    if startExitCode != 0 {
        return error(string `[Docker] Failed to start Redis container: ` +
                string `'docker run' exited with code ${startExitCode}. ` +
                string `Ensure Docker is installed, the daemon is running, ` +
                string `and port ${REDIS_HOST_PORT} is free.`);
    }

    // --- Step 3: Brief wait for Redis to bind the port and be ready ---
    // Redis typically boots in < 500ms. 2s is generous but keeps CI reliable
    // on slower machines where the daemon pulls the image on first run.
    runtime:sleep(2);

    log:printInfo(string `[Docker] Redis test container ready on localhost:${REDIS_HOST_PORT} (name=${REDIS_CONTAINER_NAME})`);
}

# Stops and removes the Redis Docker container after all tests complete.
# Idempotent: `docker rm -f` is a no-op if the container does not exist
# (e.g., when BeforeSuite failed before the container was created).
# Any error during teardown is logged but intentionally NOT propagated —
# teardown failures should not mask the actual test results.
@test:AfterSuite
function stopRedisContainer() returns error? {
    log:printInfo("[Docker] Stopping and removing Redis test container...");

    os:Process|os:Error rmResult = os:exec({
        value: "docker",
        arguments: ["rm", "-f", REDIS_CONTAINER_NAME]
    });
    if rmResult is os:Error {
        log:printWarn("[Docker] `docker rm -f` could not be invoked during teardown " +
                "(docker may not be installed on this host)",
                'error = rmResult);
        return;
    }
    int exitCode = check rmResult.waitForExit();
    if exitCode != 0 {
        log:printWarn("[Docker] `docker rm -f` exited with non-zero status during teardown",
                exitCode = exitCode);
    } else {
        log:printInfo("[Docker] Redis test container removed cleanly");
    }
}
