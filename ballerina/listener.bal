// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
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

import ballerina/http;
import ballerina/jballerina.java;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/oauth2;
import ballerinax/salesforce.utils;

# Ballerina Salesforce Listener connector provides the capability to receive notifications from Salesforce.
@display {label: "Salesforce", iconPath: "icon.png"}
public isolated class Listener {
    private final string username;
    private final string password;
    private final boolean isOAuth2;
    private final readonly & OAuth2Config? oauth2Config;
    private final utils:TokenManager? tokenManager;
    private string? channelName = ();
    private final int replayFrom;
    private final string apiVersion;
    private boolean tokenRefreshPermanentlyFailed = false;

    # Initializes the listener. During initialization you can set the credentials.
    # Create a Salesforce account and obtain tokens following [this guide](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).
    #
    # + listenerConfig - Salesforce Listener configuration
    # + return - An error if initialization fails
    public isolated function init(ListenerConfig listenerConfig) returns error? {
        if listenerConfig.replayFrom is REPLAY_FROM_TIP {
            self.replayFrom = -1;
        } else {
            self.replayFrom = -2;
        }
        decimal connectionTimeout = listenerConfig.connectionTimeout;
        if connectionTimeout <= 0d {
            return error("Connection timeout must be greater than 0.");
        }
        decimal readTimeout = listenerConfig.readTimeout;
        if readTimeout <= 0d {
            return error("Read timeout must be greater than 0.");
        }
        decimal keepAliveInterval = listenerConfig.keepAliveInterval;
        if keepAliveInterval <= 0d {
            return error("Keep alive interval must be greater than 0.");
        }
        check utils:validateApiVersion(listenerConfig.apiVersion);
        self.apiVersion = listenerConfig.apiVersion;
        if listenerConfig is RestBasedListenerConfig {
            self.username = "";
            self.password = "";
            self.isOAuth2 = true;
            self.oauth2Config = listenerConfig.auth.cloneReadOnly();
            // Create TokenManager for RefreshTokenGrantConfig to handle token rotation
            if listenerConfig.auth is http:OAuth2RefreshTokenGrantConfig {
                http:OAuth2RefreshTokenGrantConfig rtConfig =
                    <http:OAuth2RefreshTokenGrantConfig>listenerConfig.auth;
                log:printDebug("Listener using TokenManager for OAuth2 RefreshTokenGrantConfig (supports rotation)");
                self.tokenManager = check new (
                    rtConfig.clientId, rtConfig.clientSecret,
                    rtConfig.refreshToken, rtConfig.refreshUrl
                );
            } else {
                log:printDebug("Listener using standard OAuth2 provider (no rotation support)");
                self.tokenManager = ();
            }
            initListenerWithOAuth2(self, self.replayFrom, listenerConfig.baseUrl,
                    connectionTimeout, readTimeout, keepAliveInterval, self.apiVersion);
        } else {
            self.username = listenerConfig.auth.username;
            self.password = listenerConfig.auth.password;
            self.isOAuth2 = false;
            self.oauth2Config = ();
            self.tokenManager = ();
            initListener(self, self.replayFrom, listenerConfig.isSandBox,
                    connectionTimeout, readTimeout, keepAliveInterval, self.apiVersion);
        }
    }

    # Attaches the service to the `salesforce:Listener` endpoint.
    #
    # + s - Service object to attach. Use `CdcService` for CDC channels and `PlatformEventsService` for platform events.
    # + name - Channel name to subscribe to (e.g. `/data/ChangeEvents` or `/event/MyEvent__e`)
    # + return - `()` or else a `error` upon failure to register the service
    public isolated function attach(Service s, string[]|string? name) returns error? {
        if name is string {
            string channelName;
            if s is PlatformEventsService {
                channelName = name.startsWith(PLATFORM_EVENT_PREFIX) ? name : PLATFORM_EVENT_PREFIX + name;
            } else {
                channelName = name.startsWith(CDC_PREFIX) ? name : CDC_PREFIX + name;
            }
            return attachService(self, s, channelName);
        } else {
            return error("Invalid channel name.");
        }
    }

    # Starts the subscription and listen to events on all the attached services.
    #
    # + return - `()` or else a `error` upon failure to start
    public isolated function 'start() returns error? {
        if self.isOAuth2 {
            check startListenerWithOAuth2(self);
            utils:TokenManager? tm = self.tokenManager;
            if tm is utils:TokenManager {
                _ = start proactiveReconnectMonitor(self, tm);
            }
        } else {
            return startListener(self.username, self.password, self);
        }
    }

    # Retrieves the OAuth2 access token based on the configured grant type.
    # For RefreshTokenGrantConfig, uses TokenManager which handles refresh token rotation.
    #
    # + return - The access token or an error if token retrieval fails
    isolated function getOAuth2Token() returns string|error {
        // Use TokenManager for refresh token grant (handles rotation in memory)
        utils:TokenManager? tm = self.tokenManager;
        if tm is utils:TokenManager {
            log:printDebug("Listener forcing fresh token refresh for CometD re-authentication");
            string|error token = tm.refreshAccessToken();
            if token is error {
                if token.message().includes("invalid_grant") {
                    lock {
                        self.tokenRefreshPermanentlyFailed = true;
                    }
                    log:printError("Refresh token invalid or expired (invalid_grant) — " +
                        "auto-reconnect will be suppressed. Obtain a new refresh token and restart.");
                }
                return token;
            }
            log:printDebug("Listener obtained fresh access token for CometD");
            return token;
        }

        // Existing paths for other grant types
        OAuth2Config? & readonly config = self.oauth2Config;
        if config is () {
            return error("OAuth2 configuration is not set for this listener.");
        }
        if config is http:BearerTokenConfig {
            log:printDebug("Listener using static bearer token");
            return config.token;
        }
        // Password grant and client credentials grant
        log:printDebug("Listener generating token via OAuth2 provider");
        oauth2:ClientOAuth2Provider provider = new (check config.cloneWithType());
        return provider.generateToken();
    }

    # Stops subscription and detaches the service from the `salesforce:Listener` endpoint.
    #
    # + s - Type descriptor of the service
    # + return - `()` or else a `error` upon failure to detach the service
    public isolated function detach(Service s) returns error? {
        return detachService(self, s);
    }

    # Stops subscription through all consumer services by terminating the connection and all its channels.
    # For OAuth2 listeners, automatically schedules a reconnect after 5 seconds.
    #
    # + return - `()` or else a `error` upon failure to close the `salesforce:Listener`
    public isolated function gracefulStop() returns error? {
        log:printDebug("Salesforce CDC listener gracefully stopping — closing CometD connection");
        error? result = stopListener(self);
        log:printDebug("Salesforce CDC listener stopped");
        if self.isOAuth2 {
            boolean permFailed;
            lock {
                permFailed = self.tokenRefreshPermanentlyFailed;
            }
            if permFailed {
                log:printError("Auto-reconnect SKIPPED: refresh token has permanently expired. " +
                    "Obtain a new refresh token and restart the listener.");
            } else {
                log:printDebug("Scheduling auto-reconnect in 5 seconds...");
                _ = start scheduleReconnect(self);
            }
        }
        return result;
    }

    # Re-establishes the CometD connection. Safe to call after gracefulStop() or after a connection drop.
    # Only supported for OAuth2 (RestBasedListenerConfig) listeners.
    #
    # + return - `()` or else a `error` upon failure to reconnect
    public isolated function reconnect() returns error? {
        if !self.isOAuth2 {
            return error("reconnect() is only supported for OAuth2 listeners");
        }
        lock {
            self.tokenRefreshPermanentlyFailed = false;
        }
        log:printDebug("Salesforce CDC listener reconnecting — creating new CometD connection");
        check startListenerWithOAuth2(self);
        log:printDebug("Salesforce CDC listener reconnected successfully");
    }

    # Returns true if a permanent token failure (e.g. invalid_grant) has been detected.
    # Used by background monitors to know when to stop retrying.
    isolated function isTokenRefreshPermanentlyFailed() returns boolean {
        lock {
            return self.tokenRefreshPermanentlyFailed;
        }
    }

    # Stops subscriptions through all the consumer services and terminates the connection with the server.
    #
    # + return - `()` or else a `error` upon failure to close ChannelListener.
    public isolated function immediateStop() returns error? {

    }
}

isolated function scheduleReconnect(Listener instance) {
    runtime:sleep(5);
    log:printDebug("Attempting auto-reconnect after CometD connection stop...");
    error? err = startListenerWithOAuth2(instance);
    if err is error {
        log:printError("Auto-reconnect failed — manual reconnect required", 'error = err);
    } else {
        log:printDebug("CometD auto-reconnect succeeded — listener is active again");
    }
}

isolated function proactiveReconnectMonitor(Listener instance, utils:TokenManager tokenManager) {
    int bufferSeconds = 300; // reconnect 5 minutes before token expiry
    while true {
        // Stop the monitor if a permanent token failure has been detected
        if instance.isTokenRefreshPermanentlyFailed() {
            log:printError("Proactive token monitor stopping — refresh token permanently expired. " +
                "Obtain a new refresh token and restart the listener.");
            break;
        }

        int secondsLeft = tokenManager.getSecondsUntilExpiry();
        int sleepSeconds;
        if secondsLeft > bufferSeconds {
            sleepSeconds = secondsLeft - bufferSeconds;
        } else if secondsLeft > 0 {
            sleepSeconds = secondsLeft;
        } else {
            sleepSeconds = 60; // token not yet obtained or expired, retry in 1 min
        }
        log:printDebug("Proactive token monitor: next refresh scheduled",
            sleepSeconds = sleepSeconds,
            tokenExpiresInSeconds = secondsLeft);
        runtime:sleep(<decimal>sleepSeconds);

        // Check again after sleeping — flag may have been set while we were sleeping
        if instance.isTokenRefreshPermanentlyFailed() {
            log:printError("Proactive token monitor stopping — refresh token permanently expired. " +
                "Obtain a new refresh token and restart the listener.");
            break;
        }

        log:printDebug("Proactive reconnect: refreshing CometD connection before token expiry...");
        error? stopErr = stopListener(instance);
        if stopErr is error {
            log:printWarn("Proactive reconnect: stop warning", 'error = stopErr);
        }
        error? startErr = startListenerWithOAuth2(instance);
        if startErr is error {
            log:printError("Proactive reconnect failed — will retry in 60 seconds", 'error = startErr);
            runtime:sleep(60d);
        } else {
            log:printDebug("Proactive reconnect succeeded — CometD refreshed with new token");
        }
    }
}

isolated function initListener(Listener instance, int replayFrom, boolean isSandBox,
        decimal connectionTimeout, decimal readTimeout, decimal keepAliveInterval, string apiVersion) =
@java:Method {
    'class: "io.ballerinax.salesforce.ListenerUtil",
    paramTypes: [
        "io.ballerina.runtime.api.values.BObject",
        "int",
        "boolean",
        "io.ballerina.runtime.api.values.BDecimal",
        "io.ballerina.runtime.api.values.BDecimal",
        "io.ballerina.runtime.api.values.BDecimal",
        "io.ballerina.runtime.api.values.BString"
    ]
} external;

isolated function initListenerWithOAuth2(Listener instance, int replayFrom, string baseUrl,
        decimal connectionTimeout, decimal readTimeout, decimal keepAliveInterval,
        string apiVersion) =
@java:Method {
    name: "initListener",
    'class: "io.ballerinax.salesforce.ListenerUtil",
    paramTypes: [
        "io.ballerina.runtime.api.values.BObject",
        "int",
        "io.ballerina.runtime.api.values.BString",
        "io.ballerina.runtime.api.values.BDecimal",
        "io.ballerina.runtime.api.values.BDecimal",
        "io.ballerina.runtime.api.values.BDecimal",
        "io.ballerina.runtime.api.values.BString"
    ]
} external;

isolated function attachService(Listener instance, Service s, string? channelName) returns error? =
@java:Method {
    'class: "io.ballerinax.salesforce.ListenerUtil"
} external;

isolated function startListener(string username, string password, Listener instance) returns error? =
@java:Method {
    name: "startListener",
    'class: "io.ballerinax.salesforce.ListenerUtil"
} external;

isolated function startListenerWithOAuth2(Listener instance) returns error? =
@java:Method {
    name: "startListener",
    'class: "io.ballerinax.salesforce.ListenerUtil"
} external;

isolated function detachService(Listener instance, Service s) returns error? =
@java:Method {
    'class: "io.ballerinax.salesforce.ListenerUtil"
} external;

isolated function stopListener(Listener instance) returns error? =
@java:Method {
    'class: "io.ballerinax.salesforce.ListenerUtil"
} external;
