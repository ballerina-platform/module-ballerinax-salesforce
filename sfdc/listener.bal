//
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
//
import ballerina/jballerina.java;

handle JAVA_NULL = java:createNull();

@display {label: "Salesforce Listener"}
public class Listener {

    private handle username = JAVA_NULL;
    private handle password = JAVA_NULL;

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

function initListener(Listener lis) = @java:Method {'class: "org.ballerinalang.sf.ListenerUtil"} external;

function attachService(Listener lis, service object {} s) returns error? = @java:Method 
{'class: "org.ballerinalang.sf.ListenerUtil"} external;

function startListener(handle username, handle password, Listener lis) returns error? = @java:Method 
{'class: "org.ballerinalang.sf.ListenerUtil"} external;

function detachService(Listener lis, service object {} s) returns error? = @java:Method 
{'class: "org.ballerinalang.sf.ListenerUtil"} external;

function stopListener() returns error? = @java:Method {'class: "org.ballerinalang.sf.ListenerUtil"} external;

public type ListenerConfiguration record {|
    string username;
    string password;
|};

const REPLAY_FROM_TIP = -1;
const REPLAY_FROM_EARLIEST = -2;

public type ReplayFrom REPLAY_FROM_TIP|REPLAY_FROM_EARLIEST;

public type SFDCTopicConfigData record {|
    string topic;
    ReplayFrom replayFrom = REPLAY_FROM_TIP;
|};

public annotation SFDCTopicConfigData ServiceConfig on service;
