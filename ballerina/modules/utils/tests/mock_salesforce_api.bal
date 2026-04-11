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

// Mock Salesforce OAuth2 token endpoint for integration testing.
// Simulates Refresh Token Rotation (RTR) by issuing unique AT/RT pairs
// on every call and maintaining a strict, resettable call counter.
//
// The TokenManager posts to `MOCK_TOKEN_URL` (http://localhost:9443)
// which routes to this service. Since TokenManager posts to the root path "",
// the token endpoint is mounted at the root resource.

import ballerina/http;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/test;
import ballerina/time;
import ballerina/uuid;

// --- Configurable mock port ---
const int MOCK_PORT = 9090;

// The TokenManager creates an http:Client with the full URL as the base,
// then posts to "" (empty path). So the mock server base URL IS the token URL.
final string MOCK_TOKEN_URL = string `http://localhost:${MOCK_PORT}`;

// --- Global atomic counter ---
// Tracks how many times the mock token endpoint was actually hit.
isolated int tokenEndpointCallCount = 0;

isolated function getCallCount() returns int {
    lock {
        return tokenEndpointCallCount;
    }
}

isolated function resetCallCount() {
    lock {
        tokenEndpointCallCount = 0;
    }
}

isolated function incrementCallCount() returns int {
    lock {
        tokenEndpointCallCount = tokenEndpointCallCount + 1;
        return tokenEndpointCallCount;
    }
}

// --- Failure mode toggle ---
// When `mockFailureMode` is true, the mock token endpoint returns a 400
// error response with the configured error code (default: "invalid_grant").
// Used by the cache-poisoning auto-eviction test to simulate a fatal auth
// failure from Salesforce. Tests MUST reset this flag after use to prevent
// interfering with subsequent tests.
isolated boolean mockFailureMode = false;
isolated string mockFailureErrorCode = "invalid_grant";

isolated function enableMockFailureMode(string errorCode = "invalid_grant") {
    lock {
        mockFailureMode = true;
    }
    lock {
        mockFailureErrorCode = errorCode;
    }
}

isolated function disableMockFailureMode() {
    lock {
        mockFailureMode = false;
    }
    lock {
        mockFailureErrorCode = "invalid_grant";
    }
}

isolated function getMockFailureState() returns [boolean, string] {
    boolean mode;
    lock {
        mode = mockFailureMode;
    }
    string code;
    lock {
        code = mockFailureErrorCode;
    }
    return [mode, code];
}

// --- Mock HTTP Service ---
// The service is attached to the listener programmatically in @test:BeforeSuite.
// Each POST to "/" returns a unique access_token, a rotated refresh_token,
// and a server-reported issued_at in milliseconds (just like real Salesforce).

final http:Listener mockListener = check new (MOCK_PORT);

final http:Service mockTokenService = service object {

    // Simulates Salesforce token endpoint.
    // TokenManager posts to "" which maps to root resource.
    // Returns http:Ok (200) explicitly — Ballerina POST resources default to 201.
    // When failure mode is enabled, returns 400 with an error payload matching
    // Salesforce's real invalid_grant response shape.
    resource function post .(http:Request req) returns http:Ok|http:BadRequest|error {
        int count = incrementCallCount();

        // Add a small artificial delay (50ms) to widen the race window for
        // concurrency tests — makes it more likely that multiple replicas
        // overlap their refresh calls if locking is absent.
        runtime:sleep(0.05);

        // --- Failure mode branch ---
        [boolean, string] failState = getMockFailureState();
        if failState[0] {
            log:printInfo(string `[MockSF] Token endpoint hit #${count} — returning 400 ${failState[1]}`);
            http:BadRequest errorResponse = {
                body: {
                    "error": failState[1],
                    "error_description": "expired access/refresh token"
                }
            };
            return errorResponse;
        }

        [int, decimal] now = time:utcNow();
        int issuedAtMs = now[0] * 1000;

        // Generate unique tokens per call to simulate RTR.
        // Include the monotonically-increasing call counter to guarantee
        // uniqueness even when rapid back-to-back calls share a UUID clock tick.
        string accessToken = string `AT_mock_${count}_${uuid:createType1AsString()}`;
        string refreshToken = string `RT_mock_${count}_${uuid:createType1AsString()}`;

        log:printInfo(string `[MockSF] Token endpoint hit #${count}`,
                accessTokenPrefix = accessToken.substring(0, 16),
                refreshTokenPrefix = refreshToken.substring(0, 16));

        http:Ok okResponse = {
            body: {
                "access_token": accessToken,
                "refresh_token": refreshToken,
                "instance_url": "https://mock.salesforce.com",
                "id": "https://mock.salesforce.com/id/00D000000000000EAA/005000000000000AAA",
                "token_type": "Bearer",
                "issued_at": issuedAtMs.toString(),
                "signature": "mock_signature"
            }
        };
        return okResponse;
    }

    // Returns the current call count (for debugging via curl).
    resource function get call\-count() returns json {
        return {"count": getCallCount()};
    }

    // Resets the call counter to 0 (for debugging via curl).
    resource function post reset() returns json {
        resetCallCount();
        log:printInfo("[MockSF] Call counter reset to 0");
        return {"status": "reset", "count": 0};
    }
};

// --- Lifecycle: start mock server before tests, stop after ---

@test:BeforeSuite
function startMockServer() returns error? {
    check mockListener.attach(mockTokenService, "/");
    check mockListener.'start();
    log:printInfo(string `[MockSF] Mock Salesforce token endpoint started on port ${MOCK_PORT}`);
    // Give the listener a moment to bind the port
    runtime:sleep(0.5);
}

@test:AfterSuite
function stopMockServer() returns error? {
    check mockListener.gracefulStop();
    log:printInfo("[MockSF] Mock Salesforce token endpoint stopped");
}
