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

import ballerina/lang.runtime;
import ballerina/log;
import ballerina/test;

// configurable string username = os:getEnv("USERNAME");
// configurable string password = os:getEnv("PASSWORD");

// ListenerConfig listenerConfig = {
//     auth: {
//         username: username,
//         password: password
//     }
// };
// listener Listener eventListener = new (listenerConfig);

isolated boolean isUpdated = false;
isolated boolean isCreated = false;
isolated boolean isDeleted = false;
isolated boolean isRestored = false;

// service "/data/ChangeEvents" on eventListener {
//     remote function onCreate(EventData payload) {
//         string? eventType = payload.metadata?.changeType;
//         if (eventType is string && eventType == "CREATE") {
//             lock {
//                 isCreated = true;
//             }
//             io:println("Created " + payload.toString());
//         } else {
//             io:println(payload.toString());
//         }
//     }

//     remote isolated function onUpdate(EventData payload) {
//         json accountName = payload.changedData.get("Name");
//         if (accountName.toString() == "WSO2 Inc") {
//             lock {
//                 isUpdated = true;
//             }
//             io:println("Updated " + payload.toString());
//         } else {
//             io:println(payload.toString());
//         }
//     }

//     remote function onDelete(EventData payload) {
//         string? eventType = payload.metadata?.changeType;
//         if (eventType is string && eventType == "DELETE") {
//             lock {
//                 isDeleted = true;
//             }
//             io:println("Deleted " + payload.toString());
//         } else {
//             io:println(payload.toString());
//         }
//     }

//     remote function onRestore(EventData payload) {
//         string? eventType = payload.metadata?.changeType;
//         if (eventType is string && eventType == "UNDELETE") {
//             lock {
//                 isRestored = true;
//             }
//             io:println("Restored " + payload.toString());
//         } else {
//             io:println(payload.toString());
//         }
//     }
// }

// Using direct-token config for client configuration
Client lisbaseClient = check new (sfConfigRefreshCodeFlow);
string testRecordId = "";

@test:Config {
    enable: false
}
function testCreateRecord() {
    log:printInfo("lisbaseClient -> createRecord()");
    Account account = {
        Name: "John Keells Holdings",
        BillingCity: "Colombo 3"
    };
    CreationResponse|error stringResponse = lisbaseClient->create("Account", account);

    if (stringResponse is CreationResponse) {
        test:assertNotEquals(stringResponse, "", msg = "Found empty response!");
        testRecordId = stringResponse.id;
    } else {
        test:assertFail("fail");
    }
}

@test:Config {
    enable: false,
    dependsOn: [testCreateRecord]
}
function testUpdateRecord() {
    log:printInfo("lisbaseClient -> updateRecord()");
    Account account = {
        Name: "WSO2 Inc",
        BillingCity: "Jaffna",
        Phone: "+94110000000"
    };
    error? response = lisbaseClient->update("Account", testRecordId, account);

    if (response is error) {
        test:assertFail(msg = response.message());
    }
}

@test:Config {
    enable: false,
    dependsOn: [testUpdateRecord]
}
function testDeleteRecord() {
    log:printInfo("lisbaseClient -> deleteRecord()");

    error? response = lisbaseClient->delete("Account", testRecordId);

    if (response is error) {
        test:assertFail(msg = response.message());
    }
}

@test:Config {
    enable: false,
    dependsOn: [testCreateRecord]
}
function testCreatedEventTrigger() {
    runtime:sleep(10.0);
    lock {
        test:assertTrue(isCreated, "Error in retrieving account update!");

    }
}

@test:Config {
    enable: false,
    dependsOn: [testUpdateRecord]
}
function testUpdatedEventTrigger() {
    runtime:sleep(10.0);
    lock {
        test:assertTrue(isUpdated, "Error in retrieving account update!");

    }
}

@test:Config {
    enable: false,
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
