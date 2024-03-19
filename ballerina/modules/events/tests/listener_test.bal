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

import ballerina/io;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/os;
import ballerina/test;
import ballerinax/salesforce as sfdc;

configurable string & readonly username = os:getEnv("SF_USERNAME");
configurable string & readonly password = os:getEnv("SF_PASSWORD");

ListenerConfig listenerConfig = {
    username: username,
    password: password,
    channelName: "/data/ChangeEvents"
};
listener Listener eventListener = new (listenerConfig);

isolated boolean isUpdated = false;
isolated boolean isCreated = false;
isolated boolean isDeleted = false;
isolated boolean isRestored = false;

service RecordService on eventListener {
    remote function onCreate(EventData payload) {
        string? eventType = payload.metadata?.changeType;
        if (eventType is string && eventType == "CREATE") {
            lock {
                isCreated = true;
            }
            io:println("Created " + payload.toString());
        } else {
            io:println(payload.toString());
        }
    }

    remote isolated function onUpdate(EventData payload) {
        json accountName = payload.changedData.get("Name");
        if (accountName.toString() == "WSO2 Inc") {
            lock {
                isUpdated = true;
            }
            io:println("Updated " + payload.toString());
        } else {
            io:println(payload.toString());
        }
    }

    remote function onDelete(EventData payload) {
        string? eventType = payload.metadata?.changeType;
        if (eventType is string && eventType == "DELETE") {
            lock {
                isDeleted = true;
            }
            io:println("Deleted " + payload.toString());
        } else {
            io:println(payload.toString());
        }
    }

    remote function onRestore(EventData payload) {
        string? eventType = payload.metadata?.changeType;
        if (eventType is string && eventType == "UNDELETE") {
            lock {
                isRestored = true;
            }
            io:println("Restored " + payload.toString());
        } else {
            io:println(payload.toString());
        }
    }
}

// Create Salesforce client configuration by reading from environemnt.
configurable string & readonly clientId = os:getEnv("CLIENT_ID");
configurable string & readonly clientSecret = os:getEnv("CLIENT_SECRET");
configurable string & readonly refreshToken = os:getEnv("REFRESH_TOKEN");
configurable string & readonly refreshUrl = os:getEnv("REFRESH_URL");
configurable string & readonly baseUrl = os:getEnv("EP_URL");

// Using direct-token config for client configuration
sfdc:ConnectionConfig sfConfig = {
    baseUrl: baseUrl,
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
    }
};

sfdc:Client baseClient = check new (sfConfig);
string testRecordId = "";

@test:Config {
    enable: true
}
function testCreateRecord() {
    log:printInfo("baseClient -> createRecord()");
    json accountRecord = {
        Name: "John Keells Holdings",
        BillingCity: "Colombo 3"
    };
    string|error stringResponse = baseClient->createRecord("Account", accountRecord);

    if (stringResponse is string) {
        test:assertNotEquals(stringResponse, "", msg = "Found empty response!");
        testRecordId = <@untainted>stringResponse;
    } else {
        test:assertFail(msg = stringResponse.message());
    }
}

@test:Config {
    enable: true,
    dependsOn: [testCreateRecord]
}
function testUpdateRecord() {
    log:printInfo("baseClient -> updateRecord()");
    json account = {
        Name: "WSO2 Inc",
        BillingCity: "Jaffna",
        Phone: "+94110000000"
    };
    error? response = baseClient->updateRecord("Account", testRecordId, account);

    if (response is error) {
        test:assertFail(msg = response.message());
    }
}

@test:Config {
    enable: true,
    dependsOn: [testUpdateRecord]
}
function testDeleteRecord() {
    log:printInfo("baseClient -> deleteRecord()");

    error? response = baseClient->deleteRecord("Account", testRecordId);

    if (response is error) {
        test:assertFail(msg = response.message());
    }
}

@test:Config {
    enable: true,
    dependsOn: [testCreateRecord]
}
function testCreatedEventTrigger() {
    runtime:sleep(10.0);
    lock {
        test:assertTrue(isCreated, "Error in retrieving account update!");

    }
}

@test:Config {
    enable: true,
    dependsOn: [testUpdateRecord]
}
function testUpdatedEventTrigger() {
    runtime:sleep(10.0);
    lock {
        test:assertTrue(isUpdated, "Error in retrieving account update!");

    }
}

@test:Config {
    enable: true,
    dependsOn: [testDeleteRecord]
}
function testDeletedEventTrigger() {
    runtime:sleep(10.0);
    lock {
        test:assertTrue(isDeleted, "Error in retrieving account update!");

    }
}

@test:Config {
    enable: false,
    dependsOn: [testDeleteRecord]
}
function testRestoredEventTrigger() {
    runtime:sleep(10.0);
    lock {
        test:assertTrue(isRestored, "Error in retrieving account update!");

    }
}
