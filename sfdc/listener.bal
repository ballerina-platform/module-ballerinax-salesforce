// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
@display {label: "Salesforce Listener", iconPath: "resources/sfdc.svg"}
public class Listener {
    private handle username = JAVA_NULL;
    private handle password = JAVA_NULL;

    # Initializes the connector. During initialization you have to pass Salesforce username and concatenation of 
    # password and security token.
    # 
    # + ListenerConfiguration - Salesforce Listener configuration
    public function init(ListenerConfiguration config) {
        self.username = java:fromString(config.username);
        self.password = java:fromString(config.password);
        initListener(self);
    }

    public function attach(service object {} s, string[]|string? name) returns error? {
        return attachService(self, s);
    }

    public function detach(service object {} s) returns error? {
        return detachService(self, s);
    }

    public function 'start() returns error? {
        return startListener(self.username, self.password, self);
    }

    public function gracefulStop() returns error? {
        return stopListener();
    }

    public isolated function immediateStop() returns error? {

    }
}

function initListener(Listener lis) = 
@java:Method {
    'class: "org.ballerinalang.sf.ListenerUtil"
} external;

function attachService(Listener lis, service object {} s) returns error? =
@java:Method {
    'class: "org.ballerinalang.sf.ListenerUtil"
} external;

function startListener(handle username, handle password, Listener lis) returns error? = 
@java:Method {
    'class: "org.ballerinalang.sf.ListenerUtil"
} external;

function detachService(Listener lis, service object {} s) returns error? =
@java:Method {
    'class: "org.ballerinalang.sf.ListenerUtil"
} external;

function stopListener() returns error? = 
@java:Method {
    'class: "org.ballerinalang.sf.ListenerUtil"
} external;

# Salesforce listener configuration
# 
# + username - Salesforce login username
# + password - Salesforce login password appended with the security token (<password><security token>)
@display{label: "Listener Config"}
public type ListenerConfiguration record {|
    @display{label: "Username"}
    string username;
    @display{label: "Password"}
    string password;
|};

const REPLAY_FROM_TIP = -1;
const REPLAY_FROM_EARLIEST = -2;

public type ReplayFrom REPLAY_FROM_TIP|REPLAY_FROM_EARLIEST;

public type SFDCChannelConfigData record {|
    string channelName;
    ReplayFrom replayFrom = REPLAY_FROM_TIP;
|};

public annotation SFDCChannelConfigData ServiceConfig on service;

# A record type which contains data returned from a Change Data Event.
#
# + changedData - A JSON map which contains the changed data
# + metadata - Header fields that contain information about the event
public type EventData record {
    map<json> changedData;
    ChangeEventMetadata metadata?;
};

# Header fields that contain information about the event.
#
# + commitTimestamp - The date and time when the change occurred, represented as the number of milliseconds 
#                     since January 1, 1970 00:00:00 GMT
# + transactionKey - Uniquely identifies the transaction that the change is part of
# + changeOrigin - Origin of the change. Use this field to find out what caused the change.  
# + changeType - The operation that caused the change  
# + entityName - The name of the standard or custom object for this record change
# + sequenceNumber - Identifies the sequence of the change within a transaction
# + commitUser - The ID of the user that ran the change operation
# + commitNumber - The system change number (SCN) of a committed transaction
# + recordId - The record ID for the changed record
public type ChangeEventMetadata record {
    int commitTimestamp?;
    string transactionKey?;
    string changeOrigin?;
    string changeType?;
    string entityName?;
    int sequenceNumber?;
    string commitUser?;
    int commitNumber?;
    string recordId?;
};
