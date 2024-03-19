// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
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
    private handle username = JAVA_NULL;
    private handle password = JAVA_NULL;
    private handle channelName = JAVA_NULL;
    private handle replayFrom = JAVA_NULL;
    private handle environment = JAVA_NULL;

    # Gets invoked to initialize the `listener`.
    # The liatener initialization requires setting the credentials.
    # Create an [Salesforce Account](https://www.salesforce.com/ap/?ir=1) and obtain tokens by following [this guide](https://developer.salesforce.com/docs/atlas.en-us.api_streaming.meta/api_streaming/code_sample_java_add_source.htm).
    #
    # + listenerConfig - Salesforce Listener configuration
    public function init(ListenerConfig listenerConfig) {
        self.username = java:fromString(listenerConfig.username);
        self.password = java:fromString(listenerConfig.password);
        self.channelName = java:fromString(listenerConfig.channelName);
        self.replayFrom = java:fromString(listenerConfig.replayFrom.toString());
        self.environment = java:fromString(listenerConfig.environment.toString());
        initListener(self, self.replayFrom, self.channelName, self.environment);    
    }

    # Attaches the service to the `sfdc:Listener` endpoint.
    #
    # + s - Type descriptor of the service
    # + name - Name of the service
    # + return - `()` or else a `error` upon failure to register the service
    public function attach(RecordService s, string[]|string? name) returns error? {
        return attachService(self, s);
    }

    # Starts the subscription and listen to events on all the attached services.
    #
    # + return - `()` or else a `error` upon failure to start
    public function 'start() returns error? {
        return startListener(self.username, self.password, self);
    }

    # Stops subscription and detaches the service from the `sfdc:Listener` endpoint.
    #
    # + s - Type descriptor of the service
    # + return - `()` or else a `error` upon failure to detach the service
    public function detach(RecordService s) returns error? {
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

function initListener(Listener instance, handle replayFrom, handle channelName, handle environment) = 
@java:Method {
    'class: "io.ballerina.sfdc.ListenerUtil"
} external;

function attachService(Listener instance, RecordService s) returns error? =
@java:Method {
    'class: "io.ballerina.sfdc.ListenerUtil"
} external;

function startListener(handle username, handle password, Listener instance) returns error? =
@java:Method {
    'class: "io.ballerina.sfdc.ListenerUtil"
} external;

function detachService(Listener instance, RecordService s) returns error? =
@java:Method {
    'class: "io.ballerina.sfdc.ListenerUtil"
} external;

function stopListener() returns error? =
@java:Method {
    'class: "io.ballerina.sfdc.ListenerUtil"
} external;
