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
import ballerina/oauth2;
import ballerinax/salesforce.utils;

# Ballerina Salesforce Listener connector provides the capability to receive notifications from Salesforce.
@display {label: "Salesforce", iconPath: "icon.png"}
public isolated class Listener {
    private final string username;
    private final string password;
    private final boolean isOAuth2;
    private final readonly & OAuth2Config? oauth2Config;
    private string? channelName = ();
    private final int replayFrom;
    private final string apiVersion;
    private final readonly & http:ClientSecureSocket? secureSocket;

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
        self.secureSocket = listenerConfig?.secureSocket.cloneReadOnly();
        if listenerConfig is RestBasedListenerConfig {
            self.username = "";
            self.password = "";
            self.isOAuth2 = true;
            self.oauth2Config = listenerConfig.auth.cloneReadOnly();
            initListenerWithOAuth2(self, self.replayFrom, listenerConfig.baseUrl,
                    connectionTimeout, readTimeout, keepAliveInterval, self.apiVersion,
                    self.secureSocket);
        } else {
            self.username = listenerConfig.auth.username;
            self.password = listenerConfig.auth.password;
            self.isOAuth2 = false;
            self.oauth2Config = ();
            initListener(self, self.replayFrom, listenerConfig.isSandBox,
                    connectionTimeout, readTimeout, keepAliveInterval, self.apiVersion,
                    self.secureSocket);
        }
    }

    # Attaches the service to the `salesforce:Listener` endpoint.
    #
    # + s - Type descriptor of the service
    # + name - Name of the service
    # + return - `()` or else a `error` upon failure to register the service
    public isolated function attach(Service s, string[]|string? name) returns error? {
        if name is string {
            return attachService(self, s, name);
        } else {
            return error("Invalid channel name.");
        }
    }

    # Starts the subscription and listen to events on all the attached services.
    #
    # + return - `()` or else a `error` upon failure to start
    public isolated function 'start() returns error? {
        if self.isOAuth2 {
            return startListenerWithOAuth2(self);
        } else {
            return startListener(self.username, self.password, self);
        }
    }

    # Retrieves the OAuth2 access token based on the configured grant type.
    #
    # + return - The access token or an error if token retrieval fails
    isolated function getOAuth2Token() returns string|error {
        OAuth2Config? & readonly config = self.oauth2Config;
        if config is () {
            return error("OAuth2 configuration is not set for this listener.");
        }
        if config is http:BearerTokenConfig {
            return config.token;
        } else {
            oauth2:ClientOAuth2Provider provider = new (check config.cloneWithType());
            return provider.generateToken();
        }
    }

    # Stops subscription and detaches the service from the `salesforce:Listener` endpoint.
    #
    # + s - Type descriptor of the service
    # + return - `()` or else a `error` upon failure to detach the service
    public isolated function detach(Service s) returns error? {
        return detachService(self, s);
    }

    # Stops subscription through all consumer services by terminating the connection and all its channels.
    #
    # + return - `()` or else a `error` upon failure to close the `salesforce:Listener`
    public isolated function gracefulStop() returns error? {
        return stopListener();
    }

    # Stops subscriptions through all the consumer services and terminates the connection with the server.
    #
    # + return - `()` or else a `error` upon failure to close ChannelListener.
    public isolated function immediateStop() returns error? {

    }
}

isolated function initListener(Listener instance, int replayFrom, boolean isSandBox,
        decimal connectionTimeout, decimal readTimeout, decimal keepAliveInterval, string apiVersion,
        http:ClientSecureSocket? secureSocket) =
@java:Method {
    'class: "io.ballerinax.salesforce.ListenerUtil",
    paramTypes: ["io.ballerina.runtime.api.values.BObject", "int", "boolean",
        "io.ballerina.runtime.api.values.BDecimal", "io.ballerina.runtime.api.values.BDecimal",
        "io.ballerina.runtime.api.values.BDecimal", "io.ballerina.runtime.api.values.BString",
        "java.lang.Object"]
} external;

isolated function initListenerWithOAuth2(Listener instance, int replayFrom, string baseUrl,
        decimal connectionTimeout, decimal readTimeout, decimal keepAliveInterval,
        string apiVersion, http:ClientSecureSocket? secureSocket) =
@java:Method {
    name: "initListener",
    'class: "io.ballerinax.salesforce.ListenerUtil",
    paramTypes: ["io.ballerina.runtime.api.values.BObject", "int",
        "io.ballerina.runtime.api.values.BString", "io.ballerina.runtime.api.values.BDecimal",
        "io.ballerina.runtime.api.values.BDecimal", "io.ballerina.runtime.api.values.BDecimal",
        "io.ballerina.runtime.api.values.BString", "java.lang.Object"]
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

isolated function stopListener() returns error? =
@java:Method {
    'class: "io.ballerinax.salesforce.ListenerUtil"
} external;
