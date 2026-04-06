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
import ballerina/log;
import ballerina/time;
import ballerina/url;

# Manages OAuth2 token lifecycle with support for refresh token rotation.
# When Salesforce returns a new refresh token in the token response,
# the `TokenManager` captures it in memory and uses it for subsequent refreshes.
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
    // Salesforce does not return expires_in in token responses. This value is used
    // as the assumed session timeout for AT expiry and RT window estimation.
    // Set from ListenerConfig.sessionTimeout — configure it to match your Salesforce
    // org's Session Settings (Setup > Session Settings > Session Timeout).
    private final int sessionTimeoutSeconds;

    # Initializes the TokenManager.
    #
    # + clientId - OAuth2 client ID
    # + clientSecret - OAuth2 client secret
    # + refreshToken - Initial refresh token (seed token)
    # + tokenUrl - Salesforce token endpoint URL
    # + sessionTimeoutSeconds - Salesforce session timeout in seconds (from ListenerConfig.sessionTimeout)
    # + return - An error if the HTTP client cannot be created
    public isolated function init(string clientId, string clientSecret,
            string refreshToken, string tokenUrl,
            int sessionTimeoutSeconds = 900) returns error? {
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
        self.tokenClient = check new (tokenUrl);

    }

    # Returns a valid access token, refreshing proactively if expired or about to expire.
    #
    # + return - The access token string or an error
    public isolated function getAccessToken() returns string|error {
        lock {
            [int, decimal] currentTime = time:utcNow();
            if self.accessToken != "" && currentTime[0] < self.accessTokenExpiryEpoch {
                int secondsRemaining = self.accessTokenExpiryEpoch - currentTime[0];

                return self.accessToken;
            }
        }
        return self.refreshAccessToken();
    }

    # Refreshes the access token by calling the Salesforce token endpoint.
    # Captures the rotated refresh token if present in the response.
    # Uses double-checked locking so that concurrent callers never make more than
    # one token-endpoint call per expiry cycle, which would cause `invalid_grant`
    # when Salesforce Refresh Token Rotation is enabled.
    #
    # + return - The new access token or an error
    public isolated function refreshAccessToken() returns string|error {
        lock {
            // Double-check: another strand may have already refreshed while this one
            // was waiting for the lock.
            [int, decimal] currentTime = time:utcNow();
            if self.accessToken != "" && currentTime[0] < self.accessTokenExpiryEpoch {

                return self.accessToken;
            }

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

            return newAccessToken;
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
