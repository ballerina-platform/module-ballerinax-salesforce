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
import ballerina/task;
import ballerina/time;
import ballerinax/salesforce.utils;

# Seconds before token expiry to trigger a proactive CometD reconnection with a fresh token.
const int TOKEN_REFRESH_BUFFER_SECONDS = 60;

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
    private final string baseUrl;
    private final int sessionTimeout;
    private boolean tokenRefreshPermanentlyFailed = false;
    private task:JobId? tokenRefreshJobId = ();

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
        int sessionTimeout = listenerConfig.sessionTimeout;
        if sessionTimeout <= 0 {
            return error("Session timeout must be greater than 0.");
        }
        self.sessionTimeout = sessionTimeout;
        check utils:validateApiVersion(listenerConfig.apiVersion);
        self.apiVersion = listenerConfig.apiVersion;
        if listenerConfig is RestBasedListenerConfig {
            self.username = "";
            self.password = "";
            self.isOAuth2 = true;
            self.baseUrl = listenerConfig.baseUrl;
            self.oauth2Config = listenerConfig.auth.cloneReadOnly();
            // Create TokenManager for RefreshTokenGrantConfig to handle token rotation
            if listenerConfig.auth is http:OAuth2RefreshTokenGrantConfig {
                http:OAuth2RefreshTokenGrantConfig rtConfig =
                    <http:OAuth2RefreshTokenGrantConfig>listenerConfig.auth;

                self.tokenManager = check new (
                    rtConfig.clientId, rtConfig.clientSecret,
                    rtConfig.refreshToken, rtConfig.refreshUrl,
                    sessionTimeout
                );
            } else {
                self.tokenManager = ();
            }
            initListenerWithOAuth2(self, self.replayFrom, listenerConfig.baseUrl,
                    connectionTimeout, readTimeout, keepAliveInterval, self.apiVersion);
        } else {
            self.username = listenerConfig.auth.username;
            self.password = listenerConfig.auth.password;
            self.isOAuth2 = false;
            self.baseUrl = "";
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
            check self.scheduleTokenRefreshJob();
        } else {
            return startListener(self.username, self.password, self);
        }
    }

    # Retrieves the OAuth2 access token based on the configured grant type.
    # For RefreshTokenGrantConfig, uses TokenManager which handles refresh token rotation.
    # Invalidates the cached token first to ensure a fresh token is obtained on re-auth.
    #
    # + return - The access token or an error if token retrieval fails
    isolated function getOAuth2Token() returns string|error {
        utils:TokenManager? tm = self.tokenManager;
        if tm is utils:TokenManager {
            tm.invalidateAccessToken();
            log:printInfo("Requesting access token for CometD authentication");
            string|error token = tm.getAccessToken();
            if token is error {
                if token.message().includes("invalid_grant") {
                    lock {
                        self.tokenRefreshPermanentlyFailed = true;
                    }
                    log:printError("Refresh token permanently expired (invalid_grant). " +
                        "Re-authenticate via the authorization code grant to obtain a new refresh token.");
                    error? unscheduleErr = self.unscheduleTokenRefreshJob();
                    if unscheduleErr is error {
                        log:printWarn("Failed to unschedule token refresh job on invalid_grant",
                            'error = unscheduleErr);
                    }
                    _ = start self.gracefulStop();
                }
                return token;
            }
            log:printInfo("Access token obtained for CometD",
                expiresInMinutes = tm.getSecondsUntilExpiry() / 60);
            return token;
        }

        // Existing paths for other grant types
        OAuth2Config? & readonly config = self.oauth2Config;
        if config is () {
            return error("OAuth2 configuration is not set for this listener.");
        }
        if config is http:BearerTokenConfig {
            return config.token;
        }
        // Password grant and client credentials grant
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
        log:printInfo("Salesforce CDC listener gracefully stopping — closing CometD connection");
        error? unscheduleErr = self.unscheduleTokenRefreshJob();
        if unscheduleErr is error {
            log:printWarn("Failed to unschedule token refresh job", 'error = unscheduleErr);
        }
        error? result = stopListener(self);
        log:printInfo("Salesforce CDC listener stopped");
        if self.isOAuth2 {
            boolean permFailed;
            lock {
                permFailed = self.tokenRefreshPermanentlyFailed;
            }
            if permFailed {
                log:printError("Refresh token has permanently expired. " +
                    "Obtain a new refresh token and restart the listener.");
            } else {
                log:printInfo("Scheduling auto-reconnect in 5 seconds...");
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
        check startListenerWithOAuth2(self);
        check self.scheduleTokenRefreshJob();
    }

    # Updates the in-memory refresh token used by the listener.
    # This is useful after an authorization-code exchange returns a new refresh token.
    #
    # + newRefreshToken - The latest refresh token returned by Salesforce
    # + return - `()` or else an error if this listener is not using refresh-token auth
    public isolated function updateRefreshToken(string newRefreshToken) returns error? {
        utils:TokenManager? tm = self.tokenManager;
        if tm is () {
            return error("Refresh token updates are only supported for refresh-token OAuth2 listeners");
        }
        tm.updateRefreshToken(newRefreshToken);
        lock {
            self.tokenRefreshPermanentlyFailed = false;
        }
    }

    # Returns the current in-memory refresh token held by the TokenManager.
    # Use this to read the latest rotated token and persist it to durable storage
    # so a process restart loads the newest token rather than the original seed.
    #
    # + return - The current refresh token, or an error if this listener is not using refresh-token auth
    public isolated function getRefreshToken() returns string|error {
        utils:TokenManager? tm = self.tokenManager;
        if tm is () {
            return error("getRefreshToken() is only supported for refresh-token OAuth2 listeners");
        }
        return tm.getRefreshToken();
    }

    # Schedules a recurring token refresh job using `task:scheduleJobRecurByFrequency`.
    # The job fires every (effectiveSessionTimeout - tokenRefreshBuffer) seconds and
    # proactively refreshes the CometD connection before the access token expires.
    # The effective session timeout is read from the TokenManager (may have been
    # auto-detected from the org via the Metadata API).
    #
    # + return - `()` or else an error if scheduling fails
    isolated function scheduleTokenRefreshJob() returns error? {
        utils:TokenManager? tm = self.tokenManager;
        if tm is utils:TokenManager {
            error? unscheduleErr = self.unscheduleTokenRefreshJob();
            if unscheduleErr is error {
                log:printWarn("Failed to unschedule existing token refresh job", 'error = unscheduleErr);
            }
            int intervalSeconds = self.sessionTimeout - TOKEN_REFRESH_BUFFER_SECONDS;
            if intervalSeconds <= 0 {
                log:printError("Token refresh interval is non-positive — TOKEN_REFRESH_BUFFER_SECONDS " +
                    "exceeds session timeout. Skipping job scheduling.",
                    sessionTimeoutMinutes = self.sessionTimeout / 60,
                    bufferSeconds = TOKEN_REFRESH_BUFFER_SECONDS);
                return;
            }
            TokenRefreshJob job = new (self, tm);
            // Delay the first execution by intervalSeconds so the job doesn't fire
            // immediately at t=0 (scheduleJobRecurByFrequency fires at t=0 by default).
            time:Utc firstFireUtc = time:utcAddSeconds(time:utcNow(), <decimal>intervalSeconds);
            time:Civil firstFireCivil = time:utcToCivil(firstFireUtc);
            task:JobId jobId = check task:scheduleJobRecurByFrequency(job, <decimal>intervalSeconds,
                startTime = firstFireCivil);
            lock {
                self.tokenRefreshJobId = jobId;
            }
            int atSecondsLeft = tm.getSecondsUntilExpiry();
            log:printInfo("Proactive token refresh job scheduled",
                jobId = jobId.id,
                intervalSeconds = intervalSeconds,
                intervalMinutes = intervalSeconds / 60,
                sessionTimeoutMinutes = self.sessionTimeout / 60,
                bufferSeconds = TOKEN_REFRESH_BUFFER_SECONDS,
                currentAtExpiresInMinutes = atSecondsLeft / 60);
        } else {
            log:printInfo("Token refresh job not scheduled — TokenManager not available (non-RefreshToken grant)");
        }
    }

    # Unschedules the proactive token refresh job if one is currently active.
    #
    # + return - `()` or else an error if unscheduling fails
    isolated function unscheduleTokenRefreshJob() returns error? {
        task:JobId? jobId;
        lock {
            jobId = self.tokenRefreshJobId;
            self.tokenRefreshJobId = ();
        }
        if jobId is task:JobId {
            check task:unscheduleJob(jobId);
            log:printInfo("Proactive token refresh job unscheduled");
        }
    }

    # Returns true if a permanent token failure (e.g. invalid_grant) has been detected.
    # Used by the token refresh job to know when to stop retrying.
    isolated function isTokenRefreshPermanentlyFailed() returns boolean {
        lock {
            return self.tokenRefreshPermanentlyFailed;
        }
    }

    # Stops subscriptions through all the consumer services and terminates the connection with the server.
    #
    # + return - `()` or else a `error` upon failure to close ChannelListener.
    public isolated function immediateStop() returns error? {
        error? unscheduleErr = self.unscheduleTokenRefreshJob();
        if unscheduleErr is error {
            log:printWarn("Failed to unschedule token refresh job", 'error = unscheduleErr);
        }
    }
}

isolated function scheduleReconnect(Listener instance) {
    runtime:sleep(5);
    error? err = startListenerWithOAuth2(instance);
    if err is error {
        log:printError("Auto-reconnect failed — manual reconnect required", 'error = err);
    } else {
        error? scheduleErr = instance.scheduleTokenRefreshJob();
        if scheduleErr is error {
            log:printError("Failed to reschedule token refresh job after auto-reconnect",
                'error = scheduleErr);
        }
    }
}

# Job that proactively refreshes the CometD connection before the access token expires.
# Scheduled via `task:scheduleJobRecurByFrequency` at (sessionTimeout - tokenRefreshBuffer) intervals.
class TokenRefreshJob {
    *task:Job;

    private final Listener listenerInstance;
    private final utils:TokenManager tokenManager;

    isolated function init(Listener listenerInstance, utils:TokenManager tokenManager) {
        self.listenerInstance = listenerInstance;
        self.tokenManager = tokenManager;
    }

    public function execute() {
        if self.listenerInstance.isTokenRefreshPermanentlyFailed() {
            log:printError("Token refresh job skipped — refresh token permanently expired. " +
                "Re-authenticate via the authorization code grant to obtain a new refresh token.");
            return;
        }
        int atSecondsLeft = self.tokenManager.getSecondsUntilExpiry();
        int rtSecondsLeft = self.tokenManager.getEstimatedRtSecondsLeft();

        self.tokenManager.invalidateAccessToken();
        log:printInfo("Proactive token refresh: stopping CometD to reconnect with fresh token...");
        error? stopErr = stopListener(self.listenerInstance);
        if stopErr is error {
            log:printWarn("Proactive token refresh: stop warning", 'error = stopErr);
        }
        error? startErr = startListenerWithOAuth2(self.listenerInstance);
        if startErr is error {
            log:printError("Proactive token refresh failed", 'error = startErr);
        } else {
            int newAtSecondsLeft = self.tokenManager.getSecondsUntilExpiry();
            log:printInfo("Proactive token refresh succeeded — CometD refreshed with new token",
                newAtExpiresInMinutes = newAtSecondsLeft / 60);
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
