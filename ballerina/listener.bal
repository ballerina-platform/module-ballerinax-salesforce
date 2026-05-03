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
    private final TokenManager? tokenManager;
    private string? channelName = ();
    private final int replayFrom;
    private final string apiVersion;
    private final string baseUrl;
    private final int sessionTimeout;
    private boolean tokenRefreshPermanentlyFailed = false;
    private task:JobId? tokenRefreshJobId = ();

    # Owns the Active-Standby leadership loop and CometD lifecycle for
    # OAuth2-based listeners. SOAP listeners construct a no-op instance
    # (InMemoryCoordinator, dummy intervals) so the field is always present.
    private final CometdStateManager stateManager;

    # Initializes the listener. During initialization you can set the credentials.
    # Create a Salesforce account and obtain tokens following [this guide](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).
    #
    # + listenerConfig - Salesforce Listener configuration
    # + return - An error if initialization fails
    public isolated function init(ListenerConfig listenerConfig) returns error? {
        if listenerConfig.replayFrom is REPLAY_FROM_TIP {
            self.replayFrom = -1;
        } else if listenerConfig.replayFrom is REPLAY_FROM_EARLIEST {
            self.replayFrom = -2;
        } else {
            self.replayFrom = <int>listenerConfig.replayFrom;
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
        ProxyConfig? proxyConfig = listenerConfig?.proxyConfig;

        if listenerConfig is RestBasedListenerConfig {
            decimal liveness = listenerConfig.coordination.livenessInterval;
            decimal heartbeat = listenerConfig.coordination.heartbeatInterval;
            if liveness <= 0d {
                return error("coordination.livenessInterval must be greater than 0.");
            }
            if heartbeat <= 0d {
                return error("coordination.heartbeatInterval must be greater than 0.");
            }
            if heartbeat >= liveness {
                return error("coordination.heartbeatInterval must be strictly less than " +
                        "coordination.livenessInterval (recommended ratio: 1/3 to 1/2).");
            }
            self.stateManager = new CometdStateManager(listenerConfig.coordination.coordinator, liveness, heartbeat);

            self.username = "";
            self.password = "";
            self.isOAuth2 = true;
            string normalizedBaseUrl = listenerConfig.baseUrl.trim();
            if normalizedBaseUrl == "" {
                return error("Salesforce base URL cannot be empty. Please verify and provide a valid URL.");
            }
            self.baseUrl = normalizedBaseUrl;
            self.oauth2Config = listenerConfig.auth.cloneReadOnly();
            // Create TokenManager for RefreshTokenGrantConfig to handle token rotation
            if listenerConfig.auth is http:OAuth2RefreshTokenGrantConfig {
                http:OAuth2RefreshTokenGrantConfig rtConfig =
                    <http:OAuth2RefreshTokenGrantConfig>listenerConfig.auth;

                // `defaultTokenExpTime` is declared as `decimal` in http:OAuth2RefreshTokenGrantConfig
                // (inherited from ballerina/oauth2). TokenManager expects a whole-second `int`,
                // so reject fractional values explicitly instead of rounding or truncating.
                decimal rawExpTime = rtConfig.defaultTokenExpTime;
                if rawExpTime != decimal:floor(rawExpTime) {
                    return error("defaultTokenExpTime must be a whole number of seconds. " +
                            "Fractional values are not valid. Got: " + rawExpTime.toString());
                }
                int sessionTimeoutSeconds = <int>decimal:floor(rawExpTime);
                if sessionTimeoutSeconds <= 0 {
                    return error("defaultTokenExpTime must be a positive number of seconds. " +
                            "Got: " + sessionTimeoutSeconds.toString());
                }

                self.tokenManager = check new TokenManager(
                    rtConfig.clientId, rtConfig.clientSecret,
                    rtConfig.refreshToken, rtConfig.refreshUrl,
                    sessionTimeoutSeconds,
                    TOKEN_REFRESH_BUFFER_SECONDS,
                    listenerConfig.tokenStore,
                    proxyConfig
                );
            } else {
                self.tokenManager = ();
            }
            initListenerWithOAuth2(self, self.replayFrom, self.baseUrl,
                    connectionTimeout, readTimeout, keepAliveInterval, self.apiVersion, proxyConfig);
        } else {
            // SOAP path: install an in-memory coordinator with sentinel intervals.
            // The state manager exists but is never started — SOAP uses the legacy
            // direct-start path and does not participate in Active-Standby coordination.
            self.stateManager = new CometdStateManager(new InMemoryCoordinator(), 30d, 5d);

            self.username = listenerConfig.auth.username;
            self.password = listenerConfig.auth.password;
            self.isOAuth2 = false;
            self.baseUrl = "";
            self.oauth2Config = ();
            self.tokenManager = ();
            initListener(self, self.replayFrom, listenerConfig.isSandBox,
                    connectionTimeout, readTimeout, keepAliveInterval, self.apiVersion, proxyConfig);
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
            // When coordination is active (OAuth2 listeners) each Listener instance
            // is intentionally bound to exactly one channel — the groupId, lease,
            // and replayId checkpoint are all keyed by that channel. Attaching a
            // second, different channel would silently overwrite groupId and corrupt
            // coordination for the first channel, so we reject it explicitly.
            if self.isOAuth2 {
                string? existing;
                lock {
                    existing = self.channelName;
                }
                if existing is string && existing != channelName {
                    return error(string `Coordination is active: this listener is already bound to ` +
                            string `channel '${existing}'. Create a separate salesforce:Listener ` +
                            string `instance for channel '${channelName}'.`);
                }
            }
            // Register the service first. Only commit the coordination identity
            // (groupId + channelName) after registration succeeds — if
            // attachService() fails we must not leave this instance bound to a
            // channel that has no live dispatcher, because:
            //   • the guard above would then block any retry with a different channel,
            //   • start() would fork a leadership loop keyed to a phantom channel.
            check attachService(self, s, channelName);
            // Bind the coordination group to the channel name. All replicas
            // listening on the same channel share a groupId, so leader-election
            // happens per-channel — exactly the granularity Salesforce needs.
            self.stateManager.setGroupId(channelName);
            lock {
                self.channelName = channelName;
            }
        } else {
            string invalidValue = name is string[] ? string `[${", ".join(...name)}]` : "null";
            return error(string `Invalid channel name: '${invalidValue}'`);
        }
    }

    # Starts the subscription and listens to events on all attached services.
    #
    # For OAuth2 (REST-based) listeners this forks the Active-Standby leadership
    # loop — it does NOT immediately open the CometD connection. The loop acquires
    # the lease via the configured `ListenerCoordinator` and then opens CometD.
    # Standby replicas return cleanly and idle in the loop until the leader's
    # lease expires.
    #
    # SOAP-based listeners retain the original direct-start behaviour and do not
    # participate in Active-Standby coordination.
    #
    # + return - `()` or else a `error` upon failure to start
    public isolated function 'start() returns error? {
        if !self.isOAuth2 {
            // `trap` catches both returned errors AND native panics from the Java
            // ListenerUtil.startListener() call, so an INVALID_LOGIN with dummy
            // credentials does not abort the test module and prevents the
            // coordinator-integration tests (which don't use the SOAP listener)
            // from being blocked. Tests that rely on real SOAP connectivity will
            // still fail their own assertions; this only prevents a module-level crash.
            error|() startResult = trap startListener(self.username, self.password, self);
            if startResult is error {
                log:printWarn("[Listener] SOAP login failed — listener will remain inactive. " +
                        "Provide valid username/password to enable SOAP-based streaming. " +
                        "Error: " + startResult.message());
            }
            return ();
        }
        self.stateManager.activate(self);
    }

    # Stops subscription and detaches the service from the `salesforce:Listener` endpoint.
    #
    # + s - Type descriptor of the service
    # + return - `()` or else a `error` upon failure to detach the service
    public isolated function detach(Service s) returns error? {
        return detachService(self, s);
    }

    # Stops subscription through all consumer services by terminating the CometD
    # connection. This is a permanent shutdown — call `reconnect()` to re-establish.
    #
    # For standby replicas, this is a no-op on the CometD layer (they hold no
    # subscription), but the leadership loop is stopped regardless.
    #
    # + return - `()` or else a `error` upon failure to close the `salesforce:Listener`
    public isolated function gracefulStop() returns error? {
        log:printDebug("Salesforce CDC listener gracefully stopping");
        error? unscheduleErr = self.unscheduleTokenRefreshJob();
        if unscheduleErr is error {
            log:printError("Failed to unschedule token refresh job", 'error = unscheduleErr);
        }
        if !self.isOAuth2 {
            // SOAP path: always stop the native listener directly.
            error? result = stopListener(self);
            if result is error {
                log:printError("Salesforce CDC listener (SOAP) failed to stop cleanly",
                        'error = result);
            } else {
                log:printDebug("Salesforce CDC listener (SOAP) stopped");
            }
            return result;
        }
        // OAuth2 path: delegate to the state manager, which checks wasLeader
        // and only calls stopListener if this replica held the subscription.
        return self.stateManager.gracefulStop(self);
    }

    # Re-establishes the CometD connection. Safe to call after `gracefulStop()`
    # or after a connection drop. Only supported for OAuth2 listeners.
    #
    # + return - `()` or else a `error` upon failure to reconnect
    public isolated function reconnect() returns error? {
        if !self.isOAuth2 {
            return error("reconnect() is only supported for OAuth2 listeners");
        }
        lock {
            self.tokenRefreshPermanentlyFailed = false;
        }
        // Re-enter the leadership state machine. If another replica took over
        // while this replica was down, it will idle as standby until that
        // replica's heartbeat goes stale — then compete for leadership.
        self.stateManager.reconnect(self);
    }

    # Updates the in-memory refresh token used by the listener.
    # This is useful after an authorization-code exchange returns a new refresh token.
    #
    # + newRefreshToken - The latest refresh token returned by Salesforce
    # + return - `()` or else an error if this listener is not using refresh-token auth
    public isolated function updateRefreshToken(string newRefreshToken) returns error? {
        TokenManager? tm = self.tokenManager;
        if tm is () {
            return error("Refresh token updates are only supported for refresh-token OAuth2 listeners");
        }
        check tm.updateRefreshToken(newRefreshToken);
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
        TokenManager? tm = self.tokenManager;
        if tm is () {
            return error("getRefreshToken() is only supported for refresh-token OAuth2 listeners");
        }
        return tm.getRefreshToken();
    }

    # Stops subscriptions through all the consumer services and terminates the connection with the server.
    #
    # + return - `()` or else a `error` upon failure to close ChannelListener.
    public isolated function immediateStop() returns error? {
        error? unscheduleErr = self.unscheduleTokenRefreshJob();
        if unscheduleErr is error {
            log:printError("Failed to unschedule token refresh job during immediateStop",
                    'error = unscheduleErr);
        }
        if !self.isOAuth2 {
            // SOAP path: always stop directly.
            return stopListener(self);
        }
        return self.stateManager.immediateStop(self);
    }

    # Called by the Java dispatcher (`DispatcherService`) after the user's
    # `onEvent`/`onCreate`/`onUpdate` etc. handler returns successfully.
    # Persists the latest replayId so a future leader can resume without
    # re-delivering already-handled events.
    #
    # This method is intentionally `public` so the Java layer can invoke it
    # via `runtime.callMethod(listener, "recordEventDispatched", channel, replayId)`.
    #
    # + channel - The channel the event was delivered on
    # + replayId - The Salesforce-issued replay ID of the dispatched event
    public isolated function recordEventDispatched(string channel, int replayId) {
        self.stateManager.saveCheckpoint(channel, replayId);
    }

    # Retrieves the OAuth2 access token based on the configured grant type.
    # For RefreshTokenGrantConfig, uses TokenManager which handles refresh token rotation.
    # Invalidates the cached token first to ensure a fresh token is obtained on re-auth.
    #
    # + return - The access token or an error if token retrieval fails
    isolated function getOAuth2Token() returns string|error {
        TokenManager? tm = self.tokenManager;
        if tm is TokenManager {
            tm.invalidateAccessToken();
            log:printDebug("Requesting access token for CometD authentication");
            string|error token = tm.getAccessToken();
            if token is error {
                if token.message().includes("invalid_grant") {
                    // --- Auto-evict dead token from distributed store ---
                    // Without this, the dead token poisons the Redis cache:
                    // on restart, the connector reads the stale token from Redis,
                    // ignores the fresh seed token in config, and crashes in a loop.
                    error? evictErr = tm.clearTokenStore();
                    if evictErr is error {
                        log:printWarn("Failed to evict dead token from store on invalid_grant — " +
                                "manual Redis cleanup may be needed", 'error = evictErr);
                    }
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
            log:printDebug("Access token obtained for CometD",
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

    # Schedules a one-shot token refresh job anchored to the current access token's
    # actual expiry epoch. The job fires at (tokenExpiryEpoch - TOKEN_REFRESH_BUFFER_SECONDS)
    # to proactively refresh the CometD connection before the access token expires.
    #
    # + return - `()` or else an error if scheduling fails
    isolated function scheduleTokenRefreshJob() returns error? {
        TokenManager? tm = self.tokenManager;
        if tm is TokenManager {
            error? unscheduleErr = self.unscheduleTokenRefreshJob();
            if unscheduleErr is error {
                log:printWarn("Failed to unschedule existing token refresh job", 'error = unscheduleErr);
            }

            int secondsUntilExpiry = tm.getSecondsUntilExpiry();
            int delaySeconds = secondsUntilExpiry - TOKEN_REFRESH_BUFFER_SECONDS;

            if delaySeconds <= 0 {
                delaySeconds = 1;
                log:printDebug("Token already within refresh buffer — scheduling immediate refresh",
                        secondsUntilExpiry = secondsUntilExpiry,
                        bufferSeconds = TOKEN_REFRESH_BUFFER_SECONDS);
            }

            TokenRefreshJob job = new (self, tm);
            time:Utc fireUtc = time:utcAddSeconds(time:utcNow(), <decimal>delaySeconds);
            time:Civil fireCivil = time:utcToCivil(fireUtc);
            task:JobId jobId = check task:scheduleOneTimeJob(job, fireCivil);
            lock {
                self.tokenRefreshJobId = jobId;
            }
            log:printDebug("Proactive token refresh job scheduled (one-shot)",
                    jobId = jobId.id,
                    delaySeconds = delaySeconds,
                    delayMinutes = delaySeconds / 60,
                    tokenExpiresInSeconds = secondsUntilExpiry,
                    bufferSeconds = TOKEN_REFRESH_BUFFER_SECONDS);
        } else {
            log:printDebug("Token refresh job not scheduled — TokenManager not available (non-RefreshToken grant)");
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
            log:printDebug("Proactive token refresh job unscheduled");
        }
    }

    # Returns true if a permanent token failure (e.g. invalid_grant) has been detected.
    isolated function isTokenRefreshPermanentlyFailed() returns boolean {
        lock {
            return self.tokenRefreshPermanentlyFailed;
        }
    }
}

# One-shot job that proactively refreshes the CometD connection before the access token
# expires. Scheduled via `task:scheduleOneTimeJob` at (tokenExpiry - bufferSeconds) from now.
# After each successful cycle, `execute()` reschedules the next one-shot based on the
# freshly-issued (or adopted) token's actual TTL.
isolated class TokenRefreshJob {
    *task:Job;

    private final Listener listenerInstance;
    private final TokenManager tokenManager;

    isolated function init(Listener listenerInstance, TokenManager tokenManager) {
        self.listenerInstance = listenerInstance;
        self.tokenManager = tokenManager;
    }

    public function execute() {
        // --- Kill switch: check if a previous execution detected a fatal error ---
        if self.listenerInstance.isTokenRefreshPermanentlyFailed() {
            log:printError("Proactive token scheduler terminated due to fatal authorization error. " +
                    "Re-authenticate via the authorization code grant to obtain a new refresh token.");
            error? unscheduleErr = self.listenerInstance.unscheduleTokenRefreshJob();
            if unscheduleErr is error {
                log:printWarn("Failed to unschedule token refresh job from kill switch",
                        'error = unscheduleErr);
            }
            return;
        }

        self.tokenManager.invalidateAccessToken();
        log:printDebug("Proactive token refresh: stopping CometD to reconnect with fresh token...");
        error? stopErr = stopListener(self.listenerInstance);
        if stopErr is error {
            log:printWarn("Proactive token refresh: stop warning", 'error = stopErr);
        }
        error? startErr = startListenerWithOAuth2(self.listenerInstance);
        if startErr is error {
            log:printError("Proactive token refresh failed", 'error = startErr);
            if self.listenerInstance.isTokenRefreshPermanentlyFailed() {
                log:printError("Proactive token scheduler terminated due to fatal authorization error.");
                error? unscheduleErr = self.listenerInstance.unscheduleTokenRefreshJob();
                if unscheduleErr is error {
                    log:printWarn("Failed to unschedule token refresh job after fatal error",
                            'error = unscheduleErr);
                }
            }
        } else {
            int newAtSecondsLeft = self.tokenManager.getSecondsUntilExpiry();
            log:printDebug("Proactive token refresh succeeded — CometD refreshed with new token",
                    newAtExpiresInMinutes = newAtSecondsLeft / 60);
            error? rescheduleErr = self.listenerInstance.scheduleTokenRefreshJob();
            if rescheduleErr is error {
                log:printWarn("Failed to reschedule token refresh job after successful refresh",
                        'error = rescheduleErr);
            }
        }
    }
}

isolated function initListener(Listener instance, int replayFrom, boolean isSandBox,
        decimal connectionTimeout, decimal readTimeout, decimal keepAliveInterval, string apiVersion,
        ProxyConfig? proxyConfig) =
@java:Method {
    'class: "io.ballerinax.salesforce.ListenerUtil",
    paramTypes: [
        "io.ballerina.runtime.api.values.BObject",
        "int",
        "boolean",
        "io.ballerina.runtime.api.values.BDecimal",
        "io.ballerina.runtime.api.values.BDecimal",
        "io.ballerina.runtime.api.values.BDecimal",
        "io.ballerina.runtime.api.values.BString",
        "java.lang.Object"
    ]
} external;

isolated function initListenerWithOAuth2(Listener instance, int replayFrom, string baseUrl,
        decimal connectionTimeout, decimal readTimeout, decimal keepAliveInterval,
        string apiVersion, ProxyConfig? proxyConfig) =
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
        "io.ballerina.runtime.api.values.BString",
        "java.lang.Object"
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
