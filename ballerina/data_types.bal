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
import ballerina/oauth2;

# Configurations related to username/password authentication.
public type CredentialsConfig record {|
    # Salesforce login username
    string username;
    # Salesforce login password appended with the security token (<password><security token>)
    string password;
|};

# Salesforce listener configuration type.
public type ListenerConfig SoapBasedListenerConfig|RestBasedListenerConfig;

# OAuth2 authentication configuration type.
public type OAuth2Config http:BearerTokenConfig|
    oauth2:PasswordGrantConfig|oauth2:RefreshTokenGrantConfig|oauth2:ClientCredentialsGrantConfig;

# Salesforce listener configuration for password based authentication against the SOAP API endpoint.
public type SoapBasedListenerConfig record {|
    # Authentication configuration for the listener
    CredentialsConfig auth;
    # The type of salesforce environment, if sandbox environment or not
    boolean isSandBox = false;
    *CommonListenerConfig;
|};

# Active-Standby coordination settings for a Salesforce listener.
public type ListenerCoordinationConfig record {|
    # Active-Standby coordinator. In a multi-replica deployment only the leader
    # opens the CometD subscription; standbys idle until the leader's lease
    # expires. Defaults to `InMemoryCoordinator`, which is scoped to the
    # current process. 
    # 
    # For multi-replica deployments, supply a distributed implementation
    # (e.g. backed by MySQL/PostgreSQL) so that exactly one replica holds the
    # subscription at any time and replayId checkpoints survive failover.
    #
    # See `salesforce:ListenerCoordinator` for the implementation contract.
    ListenerCoordinator coordinator = new InMemoryCoordinator();
    # The interval, in seconds, before a leader's heartbeat is considered
    # expired. A standby that observes a stale heartbeat will attempt to take
    # over. Set higher than the worst-case GC pause / network blip you expect
    # from the leader.
    decimal livenessInterval = 30;
    # The interval, in seconds, between standby leadership-acquisition attempts
    # AND between leader heartbeat renewals. Must be strictly less than
    # `livenessInterval` (recommended ratio: 1/3 to 1/2).
    decimal heartbeatInterval = 5;
|};

# Salesforce listener configuration for OAuth2 based authentication.
public type RestBasedListenerConfig record {|
    # Authentication configuration for the listener
    OAuth2Config auth;
    # The base URL of the Salesforce instance
    string baseUrl;
    # Pluggable token store for coordinating token refresh across replicas.
    # Defaults to `InMemoryTokenStore`, which is scoped to the current process and
    # is the correct choice for single-replica deployments.
    #
    # For horizontally-scaled deployments (e.g. multiple Kubernetes pods sharing one
    # Salesforce Connected App) where Refresh Token Rotation is enabled, replace this
    # with a distributed implementation (e.g. Redis-backed) to prevent Token Replay
    # Attacks caused by concurrent refresh-token usage across pods.
    #
    # See `salesforce:TokenStore` for the implementation contract and
    # `salesforce:InMemoryTokenStore` for the default single-replica implementation.
    TokenStore tokenStore = new InMemoryTokenStore();
    # Active-Standby coordination settings.
    # Controls leader election, heartbeat intervals, and replayId checkpointing
    # across multiple replicas. The default value (`{}`) selects
    # `InMemoryCoordinator`, which is scoped to the current process and is the
    # correct choice for single-replica deployments.
    #
    # For multi-replica deployments (e.g. multiple Kubernetes pods), provide a
    # `ListenerCoordinationConfig` with a distributed `coordinator` implementation
    # (e.g. backed by MySQL/PostgreSQL) so that exactly one replica holds the
    # CometD subscription at any time and replayId checkpoints survive failover.
    #
    # See `salesforce:ListenerCoordinationConfig` for field-level documentation.
    ListenerCoordinationConfig coordination = {};
    *CommonListenerConfig;
|};

# The transport protocol used to connect to the proxy server.
public enum ProxyScheme {
    # Unencrypted HTTP proxy connection
    HTTP = "http",
    # Encrypted HTTPS proxy connection
    HTTPS = "https"
}

# Authentication credentials for proxy server access.
public type ProxyAuthConfig record {|
    # The username for authenticating with the proxy server
    string username;
    # The password for authenticating with the proxy server
    string password;
|};

# Proxy server configuration for routing Salesforce listener traffic.
public type ProxyConfig record {|
    # The transport protocol used to connect to the proxy server.
    # Defaults to `HTTP` which covers most corporate proxy setups
    ProxyScheme scheme = HTTP;
    # The hostname or IP address of the proxy server
    string host;
    # The port number on which the proxy server is listening
    int port;
    # Authentication credentials for the proxy server.
    # If not provided, an unauthenticated proxy connection is assumed
    ProxyAuthConfig auth?;
|};

# Common configuration for Salesforce listeners.
public type CommonListenerConfig record {|
    # The replay ID to change the point in time when events are read
    int|ReplayOptions replayFrom = REPLAY_FROM_TIP;
    # The maximum time in seconds to wait for establishing a connection to the Salesforce streaming API
    decimal connectionTimeout = 30;
    # The maximum time in seconds to wait for the long polling transport before considering a request failed
    decimal readTimeout = 30;
    # The maximum duration in seconds that a connection is kept alive without activity
    decimal keepAliveInterval = 120;
    # The Salesforce API version to use for Streaming API
    string apiVersion = "43.0";
    # The Salesforce session timeout in seconds. Set this to match the "Session Timeout" value
    # configured in your Salesforce org's Session Settings (Setup > Session Settings).
    # At startup the listener can be configured with this value, if so it overrides this setting.
    int sessionTimeout = 900;
    # Proxy server configuration
    ProxyConfig proxyConfig?;
|};

# The replay options representing the point in time when events are read.
public enum ReplayOptions {
    # To get all new events sent after subscription. This option is the default
    REPLAY_FROM_TIP,
    # To get all new events sent after subscription and all past events within the retention window
    REPLAY_FROM_EARLIEST
}

# Contains data returned from a Change Data Event.
public type EventData record {
    # A JSON map which contains the changed data
    map<json> changedData;
    # Header fields that contain information about the event
    ChangeEventMetadata metadata?;
};

# Contains data returned from a Platform Event
public type PlatformEventsMessage record {
    # The fields published with the Platform Event, as a JSON map
    map<json> payload;
    # The replay ID of the event, used for durable subscriptions
    int replayId?;
};

# Header fields that contain information about the event.
public type ChangeEventMetadata record {
    # The date and time when the change occurred, represented as the number of milliseconds since January 1, 1970 00:00:00 GMT
    int commitTimestamp?;
    # Uniquely identifies the transaction that the change is part of
    string transactionKey?;
    # Origin of the change. Use this field to find out what caused the change.
    string changeOrigin?;
    # The operation that caused the change
    string changeType?;
    # The name of the standard or custom object for this record change
    string entityName?;
    # Identifies the sequence of the change within a transaction
    int sequenceNumber?;
    # The ID of the user that ran the change operation
    string commitUser?;
    # The system change number (SCN) of a committed transaction
    int commitNumber?;
    # The record ID for the changed record
    string recordId?;
};
