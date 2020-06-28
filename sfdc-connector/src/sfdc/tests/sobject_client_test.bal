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
import ballerina/log;

json accountRecord = { 
    Name: "John Keells Holdings", 
    BillingCity: "Colombo 3" 
};

string testRecordId = "";

@test:Config {}
function testCreateRecord() {
    SObjectClient sobjectClient = baseClient->getSobjectClient();
    log:printInfo("sobjectClient -> createRecord()");
    string|Error stringResponse = sobjectClient->createRecord(ACCOUNT, accountRecord);

    if (stringResponse is string) {
        test:assertNotEquals(stringResponse, "", msg = "Found empty response!");
        testRecordId = <@untainted> stringResponse;
    } else {
        test:assertFail(msg = stringResponse.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRecord"]
}
function testGetRecord() {
    SObjectClient sobjectClient = baseClient->getSobjectClient();
    json|Error response;
    log:printInfo("sobjectClient -> getRecord()");
    string path = "/services/data/v48.0/sobjects/Account/" + testRecordId;
    response = sobjectClient->getRecord(path);

    if (response is json) {
        test:assertNotEquals(response, (), msg = "Found null JSON response!");
        test:assertEquals(response.Name, "John Keells Holdings", msg = "Name key mismatched in response");
        test:assertEquals(response.BillingCity, "Colombo 3", msg = "BillingCity key mismatched in response");
    } else {
        test:assertFail(msg = response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRecord", "testGetRecord"]
}
function testUpdateRecord() {
    SObjectClient sobjectClient = baseClient->getSobjectClient();
    log:printInfo("sobjectClient -> updateRecord()");
    json account = { Name: "WSO2 Inc", BillingCity: "Jaffna", Phone: "+94110000000" };
    boolean|Error response = sobjectClient->updateRecord(ACCOUNT, testRecordId, account);

    if (response is boolean) {
        test:assertTrue(response, msg = "Expects true on success");
    } else {
        test:assertFail(msg = response.message());
    }
}

@test:Config {
    dependsOn: ["testSearchSOSLString"]
}
function testDeleteRecord() {
    SObjectClient sobjectClient = baseClient->getSobjectClient();
    log:printInfo("sobjectClient -> deleteRecord()");
    boolean|Error response = sobjectClient->deleteRecord(ACCOUNT, testRecordId);

    if (response is boolean) {
        test:assertTrue(response, msg = "Expects true on success");
    } else {
        test:assertFail(msg = response.message());
    }
}
