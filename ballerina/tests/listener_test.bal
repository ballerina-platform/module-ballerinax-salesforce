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

string mockServerUrl = envBaseUrl != "" ? envBaseUrl : MOCK_URL;

ListenerConfig listenerConfig = {
    auth: {
        username: "test@example.com",
        password: "testpassword"
    },
    baseUrl: mockServerUrl
};
listener Listener eventListener = new (listenerConfig);

isolated boolean isUpdated = false;
isolated boolean isCreated = false;
isolated boolean isDeleted = false;
isolated boolean isRestored = false;

ConnectionConfig mockSfConfig = {
    baseUrl: mockServerUrl,
    auth: {
        token: "mock-bearer-token"
    }
};

Client sfdc = check new (mockSfConfig);

Listener authListener = check new ({
    auth: {
        token: "mock-bearer-token"
    },
    baseUrl: mockServerUrl
});

service "/data/ChangeEvents" on eventListener {

    remote function onCreate(EventData payload) {
        string? eventType = payload.metadata?.changeType;
        if eventType is "CREATE" {
            lock {
                isCreated = true;
            }
        }
    }

    remote function onUpdate(EventData payload) {
        string? eventType = payload.metadata?.changeType;
        if eventType is "UPDATE" {
            lock {
                isUpdated = true;
            }
        }
    }

    remote function onDelete(EventData payload) {
        string? eventType = payload.metadata?.changeType;
        if eventType is "DELETE" {
            lock {
                isDeleted = true;
            }
        }
    }

    remote function onRestore(EventData payload) {
        string? eventType = payload.metadata?.changeType;
        if eventType is "UNDELETE" {
            lock {
                isRestored = true;
            }
        }
    }
}

// Using mock config for client configuration
Client lisbaseClient = check new (mockSfConfig);
string testRecordId = "";

@test:Config {}
function testCreateRecord() {
    // Wait for CometD listener to fully establish long-polling connection
    runtime:sleep(5.0);
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
    dependsOn: [testDeleteRecord]
}
function testCreatedEventTrigger() {
    // Wait for all CDC events to be delivered via CometD long-poll
    runtime:sleep(5.0);
    lock {
        test:assertTrue(isCreated, "Error in retrieving account create event!");
    }
}

@test:Config {
    dependsOn: [testCreatedEventTrigger]
}
function testUpdatedEventTrigger() {
    lock {
        test:assertTrue(isUpdated, "Error in retrieving account update event!");
    }
}

@test:Config {
    dependsOn: [testUpdatedEventTrigger]
}
function testDeletedEventTrigger() {
    lock {
        test:assertTrue(isDeleted, "Error in retrieving account delete event!");
    }
}

@test:Config {
    enable: false,
    dependsOn: [testDeleteRecord]
}
function testRestoredEventTrigger() {
    runtime:sleep(5.0);
    lock {
        test:assertTrue(isRestored, "Error in retrieving account restore event!");
    }
}

Service oauth2Service = service object {
    remote function onCreate(EventData payload) {
        string? eventType = payload.metadata?.changeType;
        if eventType is "CREATE" {
            lock {
                isCreated = true;
            }
        }
    }

    remote function onUpdate(EventData payload) {
        string? eventType = payload.metadata?.changeType;
        if eventType is "UPDATE" {
            lock {
                isUpdated = true;
            }
        }
    }

    remote function onDelete(EventData payload) {
        string? eventType = payload.metadata?.changeType;
        if eventType is "DELETE" {
            lock {
                isDeleted = true;
            }
        }
    }

    remote function onRestore(EventData payload) {
        string? eventType = payload.metadata?.changeType;
        if eventType is "UNDELETE" {
            lock {
                isRestored = true;
            }
        }
    }
};

@test:Config {
    // Disabled in mock mode: the static EmpConnector in ListenerUtil prevents
    // multiple listeners from subscribing to the same channel in a single JVM.
    enable: false,
    groups: ["oauth2"]
}
function testOAuth2ListenerInitialization() returns error? {
    lock {
	    isCreated = false;
    }
    log:printInfo("Testing OAuth2 listener initialization");
    check authListener.attach(oauth2Service, "/data/ChangeEvents");
    check authListener.'start();
    runtime:registerListener(authListener);
    Account accountRecordNew = {
        Name: "HK Holdings",
        BillingCity: "Colombo 04"
    };
    CreationResponse response = check sfdc->create(ACCOUNT, accountRecordNew);
    runtime:sleep(3);
    lock {
        test:assertTrue(isCreated);
    }
    _ = check sfdc->delete(ACCOUNT, response.id);
}


@test:Config {
    groups: ["listener"]
}
function testConnectionTimeoutInListenerInitialization() returns error? {
    decimal connectionTimeout = 0.5;
    Listener sfListener = check new ({
        auth: {
            token: "mock-bearer-token"
        },
        baseUrl: "http://192.0.2.1:19999",
        connectionTimeout: connectionTimeout
    });
    check sfListener.attach(oauth2Service, "/data/ChangeEvents");
    error? response = sfListener.'start();
    test:assertTrue(response is error);
    if response is error {
        test:assertEquals(response.message(), string `Connection timed out after ${connectionTimeout} seconds.`);
    }
}
