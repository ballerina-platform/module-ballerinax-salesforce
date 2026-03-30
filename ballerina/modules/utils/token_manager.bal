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

# Manages OAuth2 token lifecycle with support for refresh token rotation.
# When Salesforce returns a new refresh token in the token response,
# the `TokenManager` captures it in memory and uses it for subsequent refreshes.
public isolated class TokenManager {

    private string accessToken;
    private string refreshToken;
    private int accessTokenExpiryEpoch;
    private final string clientId;
    private final string clientSecret;
    private final string tokenUrl;
    private final http:Client tokenClient;
    private final int clockSkewSeconds = 30;

    # Initializes the TokenManager.
    #
    # + clientId - OAuth2 client ID
    # + clientSecret - OAuth2 client secret
    # + refreshToken - Initial refresh token (seed token)
    # + tokenUrl - Salesforce token endpoint URL
    # + return - An error if the HTTP client cannot be created
    public isolated function init(string clientId, string clientSecret,
            string refreshToken, string tokenUrl) returns error? {
        self.clientId = clientId;
        self.clientSecret = clientSecret;
        self.refreshToken = refreshToken;
        self.tokenUrl = tokenUrl;
        self.accessToken = "";
        self.accessTokenExpiryEpoch = -1;
        self.tokenClient = check new (tokenUrl);
        log:printInfo("TokenManager initialized",
            tokenEndpoint = tokenUrl,
            seedRefreshToken = maskToken(refreshToken));
    }

    # Returns a valid access token, refreshing proactively if expired or about to expire.
    #
    # + return - The access token string or an error
    public isolated function getAccessToken() returns string|error {
        lock {
            [int, decimal] currentTime = time:utcNow();
            if self.accessToken != "" && currentTime[0] < self.accessTokenExpiryEpoch {
                int secondsRemaining = self.accessTokenExpiryEpoch - currentTime[0];
                log:printInfo("Reusing cached access token",
                    accessTokenFingerprint = fingerprintToken(self.accessToken),
                    expiresInSeconds = secondsRemaining);
                return self.accessToken;
            }
        }
        log:printInfo("Access token expired or not yet obtained, refreshing");
        return self.refreshAccessToken();
    }

    # Forces a refresh of the access token by calling the Salesforce token endpoint.
    # Captures the rotated refresh token if present in the response.
    #
    # + return - The new access token or an error
    public isolated function refreshAccessToken() returns string|error {
        string currentRefreshToken;
        lock {
            currentRefreshToken = self.refreshToken;
        }

        log:printInfo("Requesting new access token from Salesforce",
            refreshTokenUsed = maskToken(currentRefreshToken),
            refreshTokenFingerprint = fingerprintToken(currentRefreshToken),
            tokenEndpoint = self.tokenUrl);

        string payload = string `grant_type=refresh_token&refresh_token=${currentRefreshToken}`
            + string `&client_id=${self.clientId}&client_secret=${self.clientSecret}`;

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

        // Log response keys to diagnose whether Salesforce returned a refresh_token
        map<json> bodyMap = check body.ensureType();
        log:printInfo("Salesforce token response received",
            responseFields = bodyMap.keys().toString());

        string newAccessToken = check (check body.access_token).ensureType(string);

        // Capture rotated refresh token if present in the response
        string? rotatedRefreshToken = ();
        if bodyMap.hasKey("refresh_token") {
            json rtValue = bodyMap.get("refresh_token");
            log:printInfo("refresh_token field found in response",
                valueType = (typeof rtValue).toString(),
                isNull = rtValue is ());
            string|error rtStr = rtValue.ensureType(string);
            if rtStr is string && rtStr != "" {
                rotatedRefreshToken = rtStr;
            } else if rtStr is error {
                log:printError("refresh_token field exists but conversion to string failed",
                    'error = rtStr);
            }
        } else {
            log:printInfo("No refresh_token field in Salesforce response");
        }

        // Extract expires_in for proactive refresh
        int expiresIn = 3600; // default 1 hour if not provided
        json|error exp = body.expires_in;
        if exp is json {
            int|error expInt = exp.ensureType(int);
            if expInt is int {
                expiresIn = expInt;
            }
        }

        int effectiveExpiryEpoch;
        lock {
            self.accessToken = newAccessToken;
            [int, decimal] currentTime = time:utcNow();
            self.accessTokenExpiryEpoch = currentTime[0] + expiresIn - self.clockSkewSeconds;
            effectiveExpiryEpoch = self.accessTokenExpiryEpoch;
            if rotatedRefreshToken is string {
                self.refreshToken = rotatedRefreshToken;
            }
        }

        log:printInfo("Access token obtained successfully",
            accessTokenFingerprint = fingerprintToken(newAccessToken),
            expiresInSeconds = expiresIn,
            expiryEpoch = effectiveExpiryEpoch);

        if rotatedRefreshToken is string {
            log:printInfo("Refresh token rotated by Salesforce — updated in memory",
                previousRefreshToken = maskToken(currentRefreshToken),
                previousRefreshTokenFingerprint = fingerprintToken(currentRefreshToken),
                newRefreshToken = maskToken(rotatedRefreshToken),
                newRefreshTokenFingerprint = fingerprintToken(rotatedRefreshToken));
        } else {
            log:printInfo("No refresh token rotation detected (same token remains valid)",
                refreshTokenFingerprint = fingerprintToken(currentRefreshToken));
        }

        return newAccessToken;
    }

    # Clears the cached access token, forcing the next `getAccessToken()` call to obtain a fresh one.
    # Call this after receiving a 401 from the Salesforce REST API to recover from a remotely-invalidated token.
    public isolated function invalidateAccessToken() {
        lock {
            self.accessToken = "";
            self.accessTokenExpiryEpoch = -1;
        }
        log:printDebug("Access token cache cleared — next call will fetch a fresh token");
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
}

# Masks a token for safe logging: shows first 6 and last 6 characters.
isolated function maskToken(string token) returns string {
    int len = token.length();
    if len <= 12 {
        return "<masked>";
    }
    return token.substring(0, 6) + "..." + token.substring(len - 6);
}

# Returns a short non-reversible fingerprint (first 12 hex chars of SHA-256).
isolated function fingerprintToken(string token) returns string {
    string fingerprint = crypto:hashSha256(token.toBytes()).toBase16();
    return fingerprint.substring(0, 12);
}
