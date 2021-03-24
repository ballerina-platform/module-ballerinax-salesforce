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
//
import ballerina/test;
import ballerina/log;
import ballerina/os;

// Create Salesforce client configuration by reading from environemnt.

// Using direct-token config for client configuration
SalesforceConfiguration sfConfig = {
    baseUrl: os:getEnv("EP_URL"),
    clientConfig: {
        clientId: os:getEnv("CLIENT_ID"),
        clientSecret: os:getEnv("CLIENT_SECRET"),
        refreshToken: os:getEnv("REFRESH_TOKEN"),
        refreshUrl: os:getEnv("REFRESH_URL")
    }
};

Client baseClient = check new (sfConfig);

json accountRecord = {
    Name: "John Keells Holdings",
    BillingCity: "Colombo 3"
};

string testRecordId = "";

@test:Config {}
function testCreateRecord() {
    log:print("baseClient -> createRecord()");
    string|Error stringResponse = baseClient->createRecord(ACCOUNT, accountRecord);

    if (stringResponse is string) {
        test:assertNotEquals(stringResponse, "", msg = "Found empty response!");
        testRecordId = <@untainted>stringResponse;
    } else {
        test:assertFail(msg = stringResponse.message());
    }
}

@test:Config {dependsOn: [testCreateRecord]}
function testGetRecord() {
    json|Error response;
    log:print("baseClient -> getRecord()");
    string path = "/services/data/v48.0/sobjects/Account/" + testRecordId;
    response = baseClient->getRecord(path);

    if (response is json) {
        test:assertNotEquals(response, (), msg = "Found null JSON response!");
        test:assertEquals(response.Name, "John Keells Holdings", msg = "Name key mismatched in response");
        test:assertEquals(response.BillingCity, "Colombo 3", msg = "BillingCity key mismatched in response");
    } else {
        test:assertFail(msg = response.message());
    }
}

@test:Config {dependsOn: [testCreateRecord, testGetRecord]}
function testUpdateRecord() {
    log:print("baseClient -> updateRecord()");
    json account = {
        Name: "WSO2 Inc",
        BillingCity: "Jaffna",
        Phone: "+94110000000"
    };
    boolean|Error response = baseClient->updateRecord(ACCOUNT, testRecordId, account);

    if (response is boolean) {
        test:assertTrue(response, msg = "Expects true on success");
    } else {
        test:assertFail(msg = response.message());
    }
}

@test:Config {dependsOn: [testSearchSOSLString]}
function testDeleteRecord() {
    log:print("baseClient -> deleteRecord()");
    boolean|Error response = baseClient->deleteRecord(ACCOUNT, testRecordId);

    if (response is boolean) {
        test:assertTrue(response, msg = "Expects true on success");
    } else {
        test:assertFail(msg = response.message());
    }
}

@test:Config {}
function testGetQueryResult() {
    log:print("baseClient -> getQueryResult()");
    string sampleQuery = "SELECT name FROM Account";
    SoqlResult|Error res = baseClient->getQueryResult(sampleQuery);

    if (res is SoqlResult) {
        assertSoqlResult(res);
        string|error nextRecordsUrl = res["nextRecordsUrl"].toString();

        while (nextRecordsUrl is string && nextRecordsUrl.trim() != EMPTY_STRING) {
            log:print("Found new query result set! nextRecordsUrl:" + nextRecordsUrl);
            SoqlResult|Error resp = baseClient->getNextQueryResult(<@untainted>nextRecordsUrl);

            if (resp is SoqlResult) {
                assertSoqlResult(resp);
                res = resp;
            } else {
                test:assertFail(msg = resp.message());
            }
        }
    } else {
        test:assertFail(msg = res.message());
    }
}

@test:Config {dependsOn: [testUpdateRecord]}
function testSearchSOSLString() {
    log:print("baseClient -> searchSOSLString()");
    string searchString = "FIND {WSO2 Inc}";
    SoslResult|Error res = baseClient->searchSOSLString(searchString);

    if (res is SoslResult) {
        test:assertTrue(res.searchRecords.length() > 0, msg = "Found 0 search records!");
        test:assertTrue(res.searchRecords[0].attributes.'type == ACCOUNT, 
        msg = "Matched search record is not an Account type!");
    } else {
        test:assertFail(msg = res.message());
    }
}

isolated function assertSoqlResult(SoqlResult|Error res) {
    if (res is SoqlResult) {
        test:assertTrue(res.totalSize > 0, "Total number result records is 0");
        test:assertTrue(res.'done, "Query is not completed");
        test:assertTrue(res.records.length() == res.totalSize, "Query result records not equal to totalSize");
    } else {
        test:assertFail(msg = res.message());
    }
}

@test:Config {}
function testGetAvailableApiVersions() {
    log:print("baseClient -> getAvailableApiVersions()");
    Version[]|Error versions = baseClient->getAvailableApiVersions();

    if (versions is Version[]) {
        test:assertTrue(versions.length() > 0, msg = "Found 0 or No API versions");
    } else {
        test:assertFail(msg = versions.message());
    }
}

@test:Config {}
function testGetResourcesByApiVersion() {
    log:print("baseClient -> getResourcesByApiVersion()");
    map<string>|Error resources = baseClient->getResourcesByApiVersion(API_VERSION);

    if (resources is map<string>) {
        test:assertTrue(resources.length() > 0, msg = "Found empty resource map");

        test:assertTrue((resources["sobjects"].toString().trim()).length() > 0, msg = "Found null for resource sobjects");
        test:assertTrue((resources["search"].toString().trim()).length() > 0, msg = "Found null for resource search");
        test:assertTrue((resources["query"].toString().trim()).length() > 0, msg = "Found null for resource query");
        test:assertTrue((resources["licensing"].toString().trim()).length() > 0, 
        msg = "Found null for resource licensing");
        test:assertTrue((resources["connect"].toString().trim()).length() > 0, msg = "Found null for resource connect");
        test:assertTrue((resources["tooling"].toString().trim()).length() > 0, msg = "Found null for resource tooling");
        test:assertTrue((resources["chatter"].toString().trim()).length() > 0, msg = "Found null for resource chatter");
        test:assertTrue((resources["recent"].toString().trim()).length() > 0, msg = "Found null for resource recent");
    } else {
        test:assertFail(msg = resources.message());
    }
}

@test:Config {}
function testGetOrganizationLimits() {
    log:print("baseClient -> getOrganizationLimits()");
    map<Limit>|Error limits = baseClient->getOrganizationLimits();

    if (limits is map<Limit>) {
        test:assertTrue(limits.length() > 0, msg = "Found empty resource map");
        string[] keys = limits.keys();
        test:assertTrue(keys.length() > 0, msg = "Response doesn't have enough keys");
        foreach var key in keys {
            Limit? lim = limits[key];
            if (lim is Limit) {
                test:assertNotEquals(lim.Max, (), msg = "Max limit not found");
                test:assertNotEquals(lim.Remaining, (), msg = "Remaining resources not found");
            } else {
                test:assertFail(msg = "Could not get the Limit for the key:" + key);
            }
        }
    } else {
        test:assertFail(msg = limits.message());
    }
}
