// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/test;
import ballerina/io;
import ballerina/lang.runtime;
import ballerina/os;

configurable string & readonly username = os:getEnv("SF_USERNAME");
configurable string & readonly password = os:getEnv("SF_PASSWORD");

ListenerConfiguration listenerConfig = {
    username: username,
    password: password
};
listener Listener eventListener = new (listenerConfig);
isolated boolean isUpdated = false;

@ServiceConfig {channelName: "/data/ChangeEvents"}
service on eventListener {
    remote isolated function onUpdate(EventData event) {
        json accountName = event.changedData.get("Name");
        if (accountName.toString() == "WSO2 Inc") {
            lock {
                isUpdated = true;
            }
        } else {
            io:println(event.toString());
        }
    }
}

@test:Config {
    enable: true,
    dependsOn: [testUpdateRecord]
}
isolated function testUpdated() {
    runtime:sleep(3.0);
    lock {
        test:assertTrue(isUpdated, "Error in retrieving account update!");
    }
}
