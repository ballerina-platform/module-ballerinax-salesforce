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

handle JAVA_NULL = java:createNull();

# Ballerina Salesforce Listener connector provides the capability to receive notifications from Salesforce.  
@display {label: "Salesforce", iconPath: "docs/icon.png"}
public class Listener {
    private string username;
    private string password;
    private string? channelName = ();
    private int replayFrom;
    private boolean isSandBox;


    # Initializes the listener. During initialization you can set the credentials.
    # Create a Salesforce account and obtain tokens following [this guide](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).
    #
    # + listenerConfig - Salesforce Listener configuration
    public function init(*ListenerConfig listenerConfig) {
        self.username = listenerConfig.auth.username;
        self.password = listenerConfig.auth.password;
        if listenerConfig.replayFrom is REPLAY_FROM_TIP {
            // internal detail (-1 and -2)
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
    public function attach(Service s, string[]|string? name) returns error? {
        if name is string {
            self.channelName = name;
        } else if name is string[] {
            self.channelName = name[0];
        } else {
            return error("Invalid channel name."); 
        }
        
        return attachService(self, s, self.channelName);
    }

    # Starts the subscription and listen to events on all the attached services.
    #
    # + return - `()` or else a `error` upon failure to start
    public function 'start() returns error? {
        return startListener(self.username, self.password, self);
    }

    # Stops subscription and detaches the service from the `salesforce:Listener` endpoint.
    #
    # + s - Type descriptor of the service
    # + return - `()` or else a `error` upon failure to detach the service
    public function detach(Service s) returns error? {
        return detachService(self, s);
    }

    # Stops subscription through all consumer services by terminating the connection and all its channels.
    #
    # + return - `()` or else a `error` upon failure to close the `sfdc:Listener`
    public function gracefulStop() returns error? {
        return stopListener();
    }

    # Stops subscriptions through all the consumer services and terminates the connection with the server.
    #
    # + return - `()` or else a `error` upon failure to close ChannelListener.
    public isolated function immediateStop() returns error? {

    }
}

function initListener(Listener instance, int replayFrom, boolean isSandBox) = 
@java:Method {
    'class: "io.ballerinax.salesforce.ListenerUtil"
} external;

function attachService(Listener instance, Service s, string? channelName) returns error? =
@java:Method {
    'class: "io.ballerinax.salesforce.ListenerUtil"
} external;

function startListener(string username, string password, Listener instance) returns error? =
@java:Method {
    'class: "io.ballerinax.salesforce.ListenerUtil"
} external;

function detachService(Listener instance, Service s) returns error? =
@java:Method {
    'class: "io.ballerinax.salesforce.ListenerUtil"
} external;

function stopListener() returns error? =
@java:Method {
    'class: "io.ballerinax.salesforce.ListenerUtil"
} external;
