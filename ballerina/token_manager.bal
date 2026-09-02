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

import ballerina/crypto;
import ballerina/http;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/oauth2;
import ballerina/time;
import ballerina/url;

const UTF8 = "UTF-8";
const string FORM_URLENCODED = "application/x-www-form-urlencoded";
const string GRANT_TYPE_PARAM = "grant_type";
const string CLIENT_CREDENTIALS_GRANT = "client_credentials";
const string PASSWORD_GRANT = "password";
const string USERNAME_PARAM = "username";
const string SCOPE_PARAM = "scope";
const string CLIENT_ID_PARAM = "client_id";
const string CLIENT_SECRET_PARAM = "client_secret";
const string AUTHORIZATION_HEADER = "Authorization";
const string BASIC_AUTH_SCHEME = "Basic ";

type TokenManagerConfig http:OAuth2RefreshTokenGrantConfig|oauth2:ClientCredentialsGrantConfig|
        oauth2:PasswordGrantConfig;

# Manages OAuth2 token lifecycle with support for refresh token rotation.
# When Salesforce returns a new refresh token in the token response,
# the `TokenManager` captures it in memory and uses it for subsequent refreshes.
#
# When a `TokenStore` is provided, the manager coordinates with other replicas
# using advisory locking — only one replica refreshes at a time, preventing
# Token Replay Attacks in multi-replica Kubernetes deployments.
isolated class TokenManager {

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
    private final readonly & (oauth2:ClientCredentialsGrantConfig|oauth2:PasswordGrantConfig)? grantConfig;
    private final boolean supportsRefreshTokenRotation;
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
    // Minimum remaining TTL (seconds) a token must have to be considered valid for
    // adoption from the shared store. Tokens within this buffer are treated as expired
    // even if technically still alive — adopting a near-death token is pointless since
    // it will expire before the CometD long-poll completes.
    // Set from Listener's TOKEN_REFRESH_BUFFER_SECONDS via init().
    private final int refreshBufferSeconds;

    # Initializes the TokenManager.
    #
    # + clientId - OAuth2 client ID
    # + clientSecret - OAuth2 client secret
    # + refreshToken - Initial refresh token (seed token)
    # + tokenUrl - Salesforce token endpoint URL
    # + sessionTimeoutSeconds - The Salesforce org-level "Session Timeout" value, in seconds.
    #                           Named after the Salesforce setting (NOT a generic token expiry)
    #                           because the value maps 1:1 to the org configuration operators
    #                           look up, and Salesforce's own refresh-token OAuth response does
    #                           NOT include an `expires_in` field — access token expiry must
    #                           therefore be derived as `issued_at + sessionTimeoutSeconds`.
    #                           Look this up in your Salesforce org at:
    #                           Setup → Security → Session Settings → Timeout Value.
    #                           Default: `900` (15 minutes) — the Salesforce platform default.
    #                           Operators SHOULD set this to match their org's actual Timeout
    #                           Value; a mismatch produces either premature refreshes (value
    #                           too low) or stale-token 401s (value too high).
    #                           Note: this is distinct from the refresh-token lifetime, which
    #                           is governed separately by the Connected App's OAuth policies
    #                           (e.g. "Refresh Token is valid until revoked" vs a fixed window).
    # + refreshBufferSeconds - Minimum remaining TTL a token must have to be adoptable from the store.
    #                          Tokens with fewer seconds remaining are treated as expired.
    # + tokenStore - Pluggable token store for multi-replica coordination.
    #               Defaults to a fresh `InMemoryTokenStore` (single-replica, in-process).
    #               Pass a distributed implementation (e.g. Redis-backed) to coordinate
    #               token refresh across multiple pods and prevent Token Replay Attacks.
    # + proxyConfig - Optional proxy server configuration. When set, all token refresh HTTP
    #        calls are routed through the specified proxy.
    # + return - An error if the HTTP client cannot be created
    isolated function init(TokenManagerConfig grantConfig,
            int sessionTimeoutSeconds = 900,
            int refreshBufferSeconds = 60,
            TokenStore tokenStore = new InMemoryTokenStore(),
            ProxyConfig? proxyConfig = (),
            decimal connectionTimeout = 15,
            decimal requestTimeout = 30) returns error? {
        string clientId;
        string clientSecret;
        string refreshToken;
        string tokenUrl;
        if grantConfig is http:OAuth2RefreshTokenGrantConfig {
            clientId = grantConfig.clientId;
            clientSecret = grantConfig.clientSecret;
            refreshToken = grantConfig.refreshToken;
            tokenUrl = grantConfig.refreshUrl;
        } else if grantConfig is oauth2:ClientCredentialsGrantConfig {
            clientId = grantConfig.clientId;
            clientSecret = grantConfig.clientSecret;
            refreshToken = PRIVATE_EMPTY_STRING;
            tokenUrl = grantConfig.tokenUrl;
        } else {
            clientId = grantConfig.clientId ?: PRIVATE_EMPTY_STRING;
            clientSecret = grantConfig.clientSecret ?: PRIVATE_EMPTY_STRING;
            refreshToken = PRIVATE_EMPTY_STRING;
            tokenUrl = grantConfig.tokenUrl;
        }
        self.clientId = clientId;
        self.clientSecret = clientSecret;
        self.refreshToken = refreshToken;
        self.tokenUrl = tokenUrl;
        self.sessionTimeoutSeconds = sessionTimeoutSeconds;
        self.refreshBufferSeconds = refreshBufferSeconds;
        self.grantConfig = grantConfig is oauth2:ClientCredentialsGrantConfig|oauth2:PasswordGrantConfig ?
                grantConfig.cloneReadOnly() : ();
        self.supportsRefreshTokenRotation = grantConfig is http:OAuth2RefreshTokenGrantConfig;
        self.accessToken = PRIVATE_EMPTY_STRING;
        self.accessTokenExpiryEpoch = -1;
        self.rtIssuedAtEpoch = -1;
        self.rtWindowSeconds = sessionTimeoutSeconds;
        self.atGeneration = 0;
        self.rtGeneration = 0;
        if sessionTimeoutSeconds <= self.clockSkewSeconds {
            return error("sessionTimeoutSeconds must be greater than clockSkewSeconds (" + string `(${self.clockSkewSeconds})`);
        }
        self.tokenStore = tokenStore;
        self.storeKey = "sf_token:" + fingerprintToken(clientId);
        if grantConfig is oauth2:ClientCredentialsGrantConfig|oauth2:PasswordGrantConfig {
            if proxyConfig is ProxyConfig && proxyConfig.scheme != HTTP {
                return error(string `Unsupported proxy scheme '${proxyConfig.scheme}'. ` +
                        "OAuth2 token requests support only HTTP proxies.");
            }
            oauth2:ClientConfiguration oauthClientConfig = grantConfig.clientConfig;
            http:ClientConfiguration httpClientConfig = {
                httpVersion: oauthClientConfig.httpVersion == oauth2:HTTP_2 ? http:HTTP_2_0 : http:HTTP_1_1,
                timeout: requestTimeout,
                socketConfig: {
                    connectTimeOut: connectionTimeout
                }
            };
            if proxyConfig is ProxyConfig {
                http:ProxyConfig httpProxy = {
                    host: proxyConfig.host,
                    port: proxyConfig.port,
                    userName: proxyConfig.auth?.username ?: PRIVATE_EMPTY_STRING,
                    password: proxyConfig.auth?.password ?: PRIVATE_EMPTY_STRING
                };
                httpClientConfig.proxy = httpProxy;
            }
            oauth2:SecureSocket? oauthSecureSocket = oauthClientConfig?.secureSocket;
            if oauthSecureSocket is oauth2:SecureSocket {
                http:ClientSecureSocket httpSecureSocket = {
                    enable: !oauthSecureSocket.disable
                };
                crypto:TrustStore|string? cert = oauthSecureSocket?.cert;
                if cert is crypto:TrustStore|string {
                    httpSecureSocket.cert = cert;
                }
                crypto:KeyStore|oauth2:CertKey? privateKey = oauthSecureSocket?.key;
                if privateKey is crypto:KeyStore {
                    httpSecureSocket.key = privateKey;
                } else if privateKey is oauth2:CertKey {
                    http:CertKey httpCertKey = {
                        certFile: privateKey.certFile,
                        keyFile: privateKey.keyFile,
                        keyPassword: privateKey?.keyPassword
                    };
                    httpSecureSocket.key = httpCertKey;
                }
                httpClientConfig.secureSocket = httpSecureSocket;
            }
            self.tokenClient = check new (tokenUrl, httpClientConfig);
        } else if proxyConfig is ProxyConfig {
            http:ProxyConfig httpProxy = {
                host: proxyConfig.host,
                port: proxyConfig.port,
                userName: proxyConfig.auth?.username ?: PRIVATE_EMPTY_STRING,
                password: proxyConfig.auth?.password ?: PRIVATE_EMPTY_STRING
            };
            self.tokenClient = check new (tokenUrl, {proxy: httpProxy});
        } else {
            self.tokenClient = check new (tokenUrl);
        }
    }

    # Returns a valid access token, refreshing proactively if expired or about to expire.
    #
    # + return - The access token string or an error
    isolated function getAccessToken() returns string|error {
        if self.grantConfig is oauth2:ClientCredentialsGrantConfig|oauth2:PasswordGrantConfig {
            lock {
                [int, decimal] currentTime = time:utcNow();
                if self.accessToken != PRIVATE_EMPTY_STRING && currentTime[0] < self.accessTokenExpiryEpoch {
                    return self.accessToken;
                }
            }
            string token = check self.generateGrantToken();
            lock {
                [int, decimal] currentTime = time:utcNow();
                self.accessToken = token;
                self.accessTokenExpiryEpoch = currentTime[0] + self.sessionTimeoutSeconds -
                        self.clockSkewSeconds;
            }
            return token;
        }
        lock {
            [int, decimal] currentTime = time:utcNow();
            if self.accessToken != PRIVATE_EMPTY_STRING && currentTime[0] < self.accessTokenExpiryEpoch {
                return self.accessToken;
            }
        }
        return self.refreshAccessToken();
    }

    isolated function generateGrantToken() returns string|error {
        oauth2:ClientCredentialsGrantConfig|oauth2:PasswordGrantConfig grantConfig;
        oauth2:ClientCredentialsGrantConfig|oauth2:PasswordGrantConfig? configuredGrant = self.grantConfig;
        if configuredGrant is oauth2:ClientCredentialsGrantConfig|oauth2:PasswordGrantConfig {
            grantConfig = configuredGrant;
        } else {
            return error("OAuth2 grant configuration is not set.");
        }
        string payload;
        string? clientId = ();
        string? clientSecret = ();
        string|string[]? scopes;
        map<string>? optionalParams;
        oauth2:CredentialBearer credentialBearer;

        if grantConfig is oauth2:ClientCredentialsGrantConfig {
            if grantConfig.clientId == PRIVATE_EMPTY_STRING ||
                    grantConfig.clientSecret == PRIVATE_EMPTY_STRING {
                return error("Client-id or client-secret cannot be empty.");
            }
            payload = GRANT_TYPE_PARAM + EQUAL_SIGN + CLIENT_CREDENTIALS_GRANT;
            clientId = grantConfig.clientId;
            clientSecret = grantConfig.clientSecret;
            scopes = grantConfig?.scopes;
            optionalParams = grantConfig?.optionalParams;
            credentialBearer = grantConfig.credentialBearer;
        } else {
            payload = GRANT_TYPE_PARAM + EQUAL_SIGN + PASSWORD_GRANT + AMPERSAND + USERNAME_PARAM + EQUAL_SIGN +
                check url:encode(grantConfig.username, UTF8) + AMPERSAND + PASSWORD_GRANT + EQUAL_SIGN +
                check url:encode(grantConfig.password, UTF8);
            clientId = grantConfig?.clientId;
            clientSecret = grantConfig?.clientSecret;
            if (clientId is string) != (clientSecret is string) {
                return error("Both client-id and client-secret must be provided together.");
            }
            if clientId is string && clientSecret is string &&
                    (clientId == PRIVATE_EMPTY_STRING || clientSecret == PRIVATE_EMPTY_STRING) {
                return error("Client-id or client-secret cannot be empty.");
            }
            scopes = grantConfig?.scopes;
            optionalParams = grantConfig?.optionalParams;
            credentialBearer = grantConfig.credentialBearer;
        }

        payload = check self.appendScopes(payload, scopes);
        payload = check self.appendOptionalParams(payload, optionalParams);

        http:Request request = new;
        if credentialBearer == oauth2:AUTH_HEADER_BEARER {
            if clientId is string && clientSecret is string {
                string credentials = clientId + ":" + clientSecret;
                request.setHeader(AUTHORIZATION_HEADER, BASIC_AUTH_SCHEME + credentials.toBytes().toBase64());
            }
        } else if clientId is string && clientSecret is string {
            payload += AMPERSAND + CLIENT_ID_PARAM + EQUAL_SIGN + check url:encode(clientId, UTF8) +
                AMPERSAND + CLIENT_SECRET_PARAM + EQUAL_SIGN + check url:encode(clientSecret, UTF8);
        }

        map<string>? customHeaders = grantConfig.clientConfig?.customHeaders;
        if customHeaders is map<string> {
            foreach [string, string] [name, value] in customHeaders.entries() {
                request.setHeader(name, value);
            }
        }
        string? customPayload = grantConfig.clientConfig?.customPayload;
        if customPayload is string && customPayload != PRIVATE_EMPTY_STRING {
            payload += AMPERSAND + customPayload;
        }
        request.setTextPayload(payload, contentType = FORM_URLENCODED);

        http:Response response = check self.tokenClient->post(PRIVATE_EMPTY_STRING, request);
        json|error jsonPayload = response.getJsonPayload();
        if response.statusCode < 200 || response.statusCode >= 300 {
            string message = string `Failed to call the token endpoint. HTTP status: ${response.statusCode}`;
            if jsonPayload is json {
                message += ". Response: " + jsonPayload.toJsonString();
            }
            return error(message);
        }
        if jsonPayload is error {
            return error("Failed to parse the token endpoint response as JSON.", jsonPayload);
        }
        json|error accessToken = jsonPayload.access_token;
        if accessToken is string {
            return accessToken;
        }
        return error("Failed to extract 'access_token' from the token endpoint response.");
    }

    isolated function appendScopes(string payload, string|string[]? scopes) returns string|error {
        string updatedPayload = payload;
        string[] values = [];
        if scopes is string {
            string scope = scopes.trim();
            if scope != PRIVATE_EMPTY_STRING {
                values.push(scope);
            }
        } else if scopes is string[] {
            foreach string value in scopes {
                string scope = value.trim();
                if scope != PRIVATE_EMPTY_STRING {
                    values.push(scope);
                }
            }
        }
        if values.length() > 0 {
            updatedPayload += AMPERSAND + SCOPE_PARAM + EQUAL_SIGN +
                    check url:encode(string:'join(" ", ...values), UTF8);
        }
        return updatedPayload;
    }

    isolated function appendOptionalParams(string payload, map<string>? optionalParams) returns string|error {
        string updatedPayload = payload;
        if optionalParams is map<string> {
            foreach [string, string] [paramName, value] in optionalParams.entries() {
                updatedPayload += AMPERSAND + check url:encode(paramName.trim(), UTF8) +
                    EQUAL_SIGN + check url:encode(value.trim(), UTF8);
            }
        }
        return updatedPayload;
    }

    isolated function isRefreshTokenManager() returns boolean {
        return self.supportsRefreshTokenRotation;
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
    isolated function refreshAccessToken() returns string|error {
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
            log:printDebug("Token refresh lock held by another replica — entering wait loop");

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
                int remainingSeconds = storeData.accessTokenExpiryEpoch - now[0];
                if remainingSeconds > self.refreshBufferSeconds {
                    self.adoptStoreData(storeData);
                    log:printDebug(
                            string `Adopted token from store after ${attempt} poll(s) (${elapsedSeconds}s wait)`,
                            fingerprint = fingerprintToken(storeData.accessToken),
                            expiresInSeconds = remainingSeconds);
                    return storeData.accessToken;
                }
                if remainingSeconds > 0 {
                    log:printDebug("Store token within refresh buffer during poll — treating as expired",
                            expiresInSeconds = remainingSeconds,
                            refreshBufferSeconds = self.refreshBufferSeconds);
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
                int remainingSeconds = storeData.accessTokenExpiryEpoch - now[0];
                if remainingSeconds > self.refreshBufferSeconds {
                    // Another replica refreshed while we waited for the lock.
                    // Token has enough remaining TTL to be useful (beyond the buffer).
                    self.accessToken = storeData.accessToken;
                    self.refreshToken = storeData.refreshToken;
                    self.accessTokenExpiryEpoch = storeData.accessTokenExpiryEpoch;
                    if storeData.issuedAtEpoch > 0 {
                        self.rtIssuedAtEpoch = storeData.issuedAtEpoch;
                    }
                    log:printDebug("Adopted token from store (refreshed by another replica)",
                            fingerprint = fingerprintToken(storeData.accessToken),
                            expiresInSeconds = remainingSeconds);
                    return storeData.accessToken;
                }
                if remainingSeconds > 0 {
                    log:printDebug("Store token within refresh buffer — treating as expired",
                            expiresInSeconds = remainingSeconds,
                            refreshBufferSeconds = self.refreshBufferSeconds);
                }
                // Store token expired — use the store's refresh token (may be more recent
                // than ours if another replica rotated it previously).
                if storeData.refreshToken != PRIVATE_EMPTY_STRING && storeData.refreshToken != self.refreshToken {
                    log:printDebug("Adopting newer refresh token from store before refreshing",
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

            http:Response response = check self.tokenClient->post(PRIVATE_EMPTY_STRING, payload,
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
                if rtStr is string && rtStr != PRIVATE_EMPTY_STRING {
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
            // Salesforce does not return an `expires_in` field in its OAuth token response,
            // so access token expiry is derived from `issued_at` (seconds epoch) plus the
            // configured org-level Session Timeout, minus a small clock-skew safety margin.
            self.accessTokenExpiryEpoch = issuedAtEpoch + self.sessionTimeoutSeconds - self.clockSkewSeconds;

            int validForMinutes = (self.accessTokenExpiryEpoch - issuedAtEpoch) / 60;
            log:printDebug(string `AT#${self.atGeneration} issued`,
                    fingerprint = fingerprintToken(newAccessToken),
                    validForMinutes = validForMinutes,
                    sessionTimeoutAssumptionMinutes = self.sessionTimeoutSeconds / 60);

            if rotatedRefreshToken is string {
                log:printDebug(string `RT#${self.rtGeneration - 1} → RT#${self.rtGeneration} (Salesforce rotated refresh token)`,
                        previousFingerprint = fingerprintToken(currentRefreshToken),
                        newFingerprint = fingerprintToken(<string>rotatedRefreshToken));
            } else {
                log:printDebug("No refresh token rotation in response — existing RT unchanged",
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
                if rotatedRefreshToken is string {
                    // CRITICAL: Salesforce rotated the refresh token in this response,
                    // which means RT#(n-1) is NOW REVOKED server-side. The new RT#n
                    // exists only in this replica's local memory. If we return success
                    // here, the lock is released, and other replicas will read the
                    // stale RT#(n-1) from the store, send it to Salesforce, and trigger
                    // an invalid_grant that kills the entire token family.
                    //
                    // Returning an error is safe: this replica still holds RT#n in
                    // memory. The caller (CometD reconnect) will retry the full
                    // refreshAccessToken() flow, re-acquire the lock, and attempt
                    // the store write again — most likely the Redis blip will have
                    // passed by then and the write will succeed.
                    log:printError("CRITICAL: Failed to persist rotated refresh token to store — " +
                            "aborting refresh to prevent Token Replay Attack. " +
                            "RT#" + self.rtGeneration.toString() + " exists only in local memory. " +
                            "The caller will retry the full refresh cycle.",
                            storeKey = storeKey,
                            rtGeneration = self.rtGeneration,
                            'error = storeErr);
                    return error("Failed to persist rotated refresh token to distributed store: " +
                            storeErr.message());
                }
                // No rotation occurred — the existing RT in the store is still valid.
                // Other replicas can safely use it. Log and continue.
                log:printWarn("Failed to write token data to store — other replicas " +
                        "may not see the new access token, but the refresh token " +
                        "in the store is still valid (no rotation occurred)",
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

    # Evicts token data from the distributed store, preventing cache poisoning.
    #
    # When Salesforce returns `invalid_grant`, the entire token family is dead.
    # This method removes the dead token data and its lock from the shared store
    # so that when the application restarts with a fresh seed token, the store
    # is empty and the new seed is used instead of the stale cached data.
    #
    # Also clears the local in-memory token state.
    #
    # + return - `()` on success, or an `error` if the store eviction fails
    isolated function clearTokenStore() returns error? {
        string storeKey;
        lock {
            storeKey = self.storeKey;
        }
        // Evict from distributed store first (most important — prevents cache poisoning)
        error? clearErr = self.tokenStore.clearTokenData(storeKey);
        if clearErr is error {
            log:printWarn("Failed to evict dead token from distributed store — " +
                    "manual cleanup may be needed to prevent cache poisoning on restart",
                    storeKey = storeKey,
                    'error = clearErr);
        } else {
            log:printDebug("Dead token evicted from distributed store (cache poisoning prevented)",
                    storeKey = storeKey);
        }
        // Also release any lingering lock
        error? releaseLockErr = self.tokenStore.releaseLock(storeKey);
        if releaseLockErr is error {
            log:printWarn("Failed to release lock during token store eviction",
                    'error = releaseLockErr);
        }
        // Clear local in-memory state
        self.invalidateAccessToken();
        return clearErr;
    }

    # Clears the cached access token, forcing the next `getAccessToken()` call to obtain a fresh one.
    isolated function invalidateAccessToken() {
        lock {
            self.accessToken = PRIVATE_EMPTY_STRING;
            self.accessTokenExpiryEpoch = -1;
        }
    }

    # Returns seconds remaining until the cached access token expires.
    # Returns 0 if no token is cached or token is already expired.
    isolated function getSecondsUntilExpiry() returns int {
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
    isolated function getEstimatedRtSecondsLeft() returns int {
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
    isolated function getRefreshToken() returns string {
        lock {
            return self.refreshToken;
        }
    }

    # Replaces the in-memory refresh token, clears the cached access token,
    # and evicts any stale token data from the shared store.
    #
    # The store eviction is critical: without it, the double-check read in
    # `doRefreshWithLock()` would find the old (dead) refresh token in the
    # store and silently overwrite the fresh seed — causing the next refresh
    # to send the revoked token to Salesforce and trigger `invalid_grant`.
    #
    # Resets RT issuance tracking so `getEstimatedRtSecondsLeft()` returns -1
    # until the next rotation response arrives.
    #
    # + newRefreshToken - The new refresh token to install
    # + return - `()` on success, or an `error` if the store eviction fails
    isolated function updateRefreshToken(string newRefreshToken) returns error? {
        string storeKey;
        lock {
            self.refreshToken = newRefreshToken;
            self.accessToken = PRIVATE_EMPTY_STRING;
            self.accessTokenExpiryEpoch = -1;
            self.rtIssuedAtEpoch = -1;
            self.rtWindowSeconds = self.sessionTimeoutSeconds;
            self.atGeneration = 0;
            self.rtGeneration = 0;
            storeKey = self.storeKey;
        }
        // Evict stale token data from the shared store so the double-check
        // in doRefreshWithLock() finds an empty store and uses the fresh seed
        // instead of re-adopting the dead RT from Redis.
        error? evictErr = self.tokenStore.clearTokenData(storeKey);
        if evictErr is error {
            log:printError("Failed to evict stale token data from store after seed update — " +
                    "the next refresh may re-adopt the dead token from the store",
                    storeKey = storeKey,
                    'error = evictErr);
            return evictErr;
        }
        log:printDebug("New seed refresh token installed (RT#0) — generation counters reset, " +
                "stale store data evicted",
                newSeedFingerprint = fingerprintToken(newRefreshToken),
                storeKey = storeKey);
    }

}

# Returns a short non-reversible fingerprint (first 12 hex chars of SHA-256).
isolated function fingerprintToken(string token) returns string {
    string fingerprint = crypto:hashSha256(token.toBytes()).toBase16();
    return fingerprint.substring(0, 12);
}
