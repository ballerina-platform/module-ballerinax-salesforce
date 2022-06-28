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

import ballerina/log;
import ballerina/os;
import ballerina/test;

// Create Salesforce client configuration by reading from environemnt.
configurable string clientId = os:getEnv("CLIENT_ID");
configurable string clientSecret = os:getEnv("CLIENT_SECRET");
configurable string refreshToken = os:getEnv("REFRESH_TOKEN");
configurable string refreshUrl = os:getEnv("REFRESH_URL");
configurable string baseUrl = os:getEnv("EP_URL");

// Using direct-token config for client configuration
ConnectionConfig sfConfig = {
    baseUrl: baseUrl,
    clientConfig: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
    }
};

Client baseClient = check new (sfConfig);

//////////////////////////////////////////// DEPRECATED ////////////////////////////////////////////////////////////////

json accountRecordJson = {
    Name: "John Keells Holdings",
    BillingCity: "Colombo 3"
};

string testRecordIdJson = "";

@test:Config {
    enable: true
}
function testCreateRecord() {
    log:printInfo("baseClient -> createRecord()");
    string|Error stringResponse = baseClient->createRecord(ACCOUNT, accountRecordJson);

    if stringResponse is string {
        test:assertNotEquals(stringResponse, "", msg = "Found empty response!");
        testRecordIdJson = stringResponse;
    } else {
        test:assertFail(msg = stringResponse.message());
    }
}

@test:Config {
    enable: true,
    dependsOn: [testCreateRecord]
}
function testGetRecord() {
    json|Error response;
    log:printInfo("baseClient -> getRecord()");
    string path = "/services/data/v48.0/sobjects/Account/" + testRecordIdJson;
    response = baseClient->getRecord(path);

    if response is json {
        test:assertNotEquals(response, (), msg = "Found null JSON response!");
        test:assertEquals(response.Name, "John Keells Holdings", msg = "Name key mismatched in response");
        test:assertEquals(response.BillingCity, "Colombo 3", msg = "BillingCity key mismatched in response");
    } else {
        test:assertFail(msg = response.message());
    }
}

@test:Config {
    enable: true,
    dependsOn: [testCreateRecord, testGetRecord]
}
function testUpdateRecord() {
    log:printInfo("baseClient -> updateRecord()");
    json account = {
        Name: "WSO2 Inc",
        BillingCity: "Jaffna",
        Phone: "+94110000000"
    };
    Error? response = baseClient->updateRecord(ACCOUNT, testRecordIdJson, account);

    if response is Error {
        test:assertFail(msg = response.message());
    }
}

@test:Config {
    enable: true,
    dependsOn: [testSearchSOSLString]
}
function testDeleteRecord() {
    log:printInfo("baseClient -> deleteRecord()");
    Error? response = baseClient->deleteRecord(ACCOUNT, testRecordIdJson);

    if response is Error {
        test:assertFail(msg = response.message());
    }
}

@test:Config {
    enable: true
}
function testGetQueryResult() returns error? {
    log:printInfo("baseClient -> getQueryResult()");
    string sampleQuery = "SELECT name FROM Account";
    SoqlResult res = check baseClient->getQueryResult(sampleQuery);
    assertSoqlResult(res);
    string nextRecordsUrl = res["nextRecordsUrl"].toString();

    while (nextRecordsUrl.trim() != EMPTY_STRING) {
        // log:printInfo("Found new query result set! nextRecordsUrl:" + nextRecordsUrl);
        SoqlResult resp = check baseClient->getNextQueryResult(nextRecordsUrl);
        assertSoqlResult(resp);
        res = resp;
    }
}

@test:Config {
    enable: true,
    dependsOn: [testUpdateRecord]
}
function testSearchSOSLString() {
    log:printInfo("baseClient -> searchSOSLString()");
    string searchString = "FIND {WSO2 Inc}";
    SoslResult|Error res = baseClient->searchSOSLString(searchString);

    if res is SoslResult {
        test:assertTrue(res.searchRecords.length() > 0, msg = "Found 0 search records!");
        test:assertTrue(res.searchRecords[0].attributes.'type == ACCOUNT,
        msg = "Matched search record is not an Account type!");
    } else {
        test:assertFail(msg = res.message());
    }
}

@test:Config {
    enable: true
}
function testGetQueryResultStream() returns error? {
    log:printInfo("baseClient -> getQueryResultStream()");
    string sampleQuery = "SELECT Name,Industry FROM Account";
    stream<record {}, error?> resultStream = check baseClient->getQueryResultStream(sampleQuery);
    int count = check countStream(resultStream);
    test:assertTrue(count > 0, msg = "Found 0 search records!");
}

@test:Config {
    enable: true
}
function testGetQueryResultWithLimit() returns error? {
    log:printInfo("baseClient -> getQueryResultWithLimit()");
    string sampleQuery = "SELECT Name,Industry FROM Account LIMIT 3";
    stream<record {}, error?> resultStream = check baseClient->getQueryResultStream(sampleQuery);
    int count = check countStream(resultStream);
    test:assertTrue(count > 0, msg = "Found 0 search records!");
}

@test:Config {
    enable: false
}
function testGetQueryResultWithPagination() returns error? {
    log:printInfo("baseClient -> getQueryResultWithPagination()");
    string sampleQuery = "SELECT Name FROM Contact";
    stream<record {}, error?> resultStream = check baseClient->getQueryResultStream(sampleQuery);
    int count = check countStream(resultStream);
    log:printInfo("Number of records", count = count);
    test:assertTrue(count > 2000, msg = "Found less than or exactly 2000 search records!");
}

@test:Config {
    enable: true,
    dependsOn: [testUpdateRecord]
}
function testSearchSOSLStringStream() returns error? {
    log:printInfo("baseClient -> searchSOSLStringStream()");
    string searchString = "FIND {WSO2 Inc}";
    stream<record {}, error?> resultStream = check baseClient->searchSOSLStringStream(searchString);
    int count = check countStream(resultStream);
    test:assertTrue(count > 0, msg = "Found 0 search records!");
}

/////////////////////////////////////////// Helper Functions ///////////////////////////////////////////////////////////

isolated function assertSoqlResult(SoqlResult|Error res) {
    if res is SoqlResult {
        test:assertTrue(res.totalSize > 0, "Total number result records is 0");
        test:assertTrue(res.'done, "Query is not completed");
        test:assertTrue(res.records.length() == res.totalSize, "Query result records not equal to totalSize");
    } else {
        test:assertFail(msg = res.message());
    }
}

isolated function countStream(stream<record {}, error?> resultStream) returns int|error {
    int nLines = 0;
    check from record {} _ in resultStream
        do {
            nLines += 1;
        };
    return nLines;
}
