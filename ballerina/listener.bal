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

import ballerina/jballerina.java;

# Ballerina Salesforce Listener connector provides the capability to receive notifications from Salesforce.  
@display {label: "Salesforce", iconPath: "icon.png"}
public isolated class Listener {
    private final string username;
    private final string password;
    private string? channelName = ();
    private final int replayFrom;
    private final boolean isSandBox;

    # Initializes the listener. During initialization you can set the credentials.
    # Create a Salesforce account and obtain tokens following [this guide](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).
    #
    # + listenerConfig - Salesforce Listener configuration
    public isolated function init(*ListenerConfig listenerConfig) {
        // set these in java code 
        self.username = listenerConfig.auth.username;
        self.password = listenerConfig.auth.password;
        if listenerConfig.replayFrom is REPLAY_FROM_TIP {
            self.replayFrom = -1;
        } else {
            self.replayFrom = -2;
        }

        self.isSandBox = listenerConfig.isSandBox;
        initListener(self, self.replayFrom, self.isSandBox);
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
        return startListener(self.username, self.password, self);
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
    # + return - `()` or else a `error` upon failure to close the `sfdc:Listener`
    public isolated function gracefulStop() returns error? {
        return stopListener();
    }

    # Stops subscriptions through all the consumer services and terminates the connection with the server.
    #
    # + return - `()` or else a `error` upon failure to close ChannelListener.
    public isolated function immediateStop() returns error? {

    }
}

isolated function initListener(Listener instance, int replayFrom, boolean isSandBox) =
@java:Method {
    'class: "io.ballerinax.salesforce.ListenerUtil"
} external;

isolated function attachService(Listener instance, Service s, string? channelName) returns error? =
@java:Method {
    'class: "io.ballerinax.salesforce.ListenerUtil"
} external;

isolated function startListener(string username, string password, Listener instance) returns error? =
@java:Method {
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
