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
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
    }
};

Client baseClient = check new (sfConfig);

public type Account record {
    string Id?;
    boolean IsDeleted?;
    string? MasterRecordId?;
    string Name?;
    anydata Type?;
    string? ParentId = ();
    string? BillingStreet = ();
    string? BillingCity?;
    string? BillingState = ();
    string? BillingPostalCode = ();
    string? BillingCountry = ();
    float? BillingLatitude = ();
    float? BillingLongitude = ();
    anydata BillingGeocodeAccuracy = ();
    anydata BillingAddress?;
    string? ShippingStreet = ();
    string? ShippingCity = ();
    string? ShippingState = ();
    string? ShippingPostalCode = ();
    string? ShippingCountry = ();
    float? ShippingLatitude = ();
    float? ShippingLongitude = ();
    anydata ShippingGeocodeAccuracy = ();
    anydata ShippingAddress?;
    string? Phone?;
    string? Fax = ();
    string? AccountNumber = ();
    string? Website = ();
    string? PhotoUrl?;
    string? Sic = ();
    anydata Industry = ();
    float? AnnualRevenue = ();
    int? NumberOfEmployees = ();
    anydata Ownership = ();
    string? TickerSymbol = ();
    string? Description = ();
    anydata Rating = ();
    string? Site = ();
    string OwnerId?;
    string CreatedDate?;
    string CreatedById?;
    string LastModifiedDate?;
    string LastModifiedById?;
    string SystemModstamp?;
    string? LastActivityDate?;
    string? LastViewedDate?;
    string? LastReferencedDate?;
    string? Jigsaw = ();
    string? JigsawCompanyId?;
    anydata CleanStatus = ();
    anydata AccountSource = ();
    string? DunsNumber = ();
    string? Tradestyle = ();
    string? NaicsCode = ();
    string? NaicsDesc = ();
    string? YearStarted = ();
    string? SicDesc = ();
    string? DandbCompanyId = ();
    string? OperatingHoursId = ();
    anydata CustomerPriority__c = ();
    anydata SLA__c = ();
    anydata Active__c = ();
    float? NumberofLocations__c = ();
    anydata UpsellOpportunity__c = ();
    string? SLASerialNumber__c = ();
    string? SLAExpirationDate__c = ();
};

Account accountRecordNew = {
    Name: "CSK Holdings",
    BillingCity: "Colombo 3"
};

string testRecordIdNew = "";

@test:Config {
    enable: true
}
function testCreate() {
    log:printInfo("baseClient -> create");
    CreationResponse|error response = baseClient->create(ACCOUNT, accountRecordNew);

    if response is CreationResponse {
        test:assertNotEquals(response, "", msg = "Found empty response!");
        testRecordIdNew = response.id;
    } else {
        error:Detail detail = response.detail();
        log:printError(detail.toString());
        test:assertFail(msg = response.message());
    }
}

@test:Config {
    enable: true,
    dependsOn: [testCreate]
}
function testGetById() {
    log:printInfo("baseClient -> getById()");
    Account|error response = baseClient->getById(ACCOUNT, testRecordIdNew);

    if response is Account {
        test:assertNotEquals(response, (), msg = "Found null JSON response!");
        test:assertEquals(response["Name"], "CSK Holdings", msg = "Name key mismatched in response");
    } else {
        test:assertFail(msg = response.detail().toString());
    }
}

@test:Config {
    enable: false,
    dependsOn: [testCreate]
}
function testGetByExternalId() {
    log:printInfo("baseClient -> getByExternalId()");
    string externalIdField = "";
    string externalId = "";
    Account|error response = baseClient->getByExternalId("Account", externalIdField, externalId);

    if response is Account {
        test:assertNotEquals(response, (), msg = "Found null JSON response!");
        test:assertEquals(response["Name"], "LNG Holdings", msg = "Name key mismatched in response");
    } else {
        test:assertFail(msg = response.detail().toString());
    }
}

@test:Config {
    enable: true,
    dependsOn: [testCreateRecord, testGetById]
}
function testUpdate() {
    log:printInfo("baseClient -> update()");
    Account account = {
        Name: "MAAS Holdings",
        BillingCity: "Jaffna",
        Phone: "+94110000000"
    };
    error? response = baseClient->update(ACCOUNT, testRecordIdNew, account);

    if response is error {
        test:assertFail(msg = response.detail().toString());
    }
}

@test:Config {
    enable: true
}
function testQuery() returns error? {
    log:printInfo("baseClient -> query()");
    string sampleQuery = "SELECT name FROM Account";
    stream<Account, error?>|error queryResult = check baseClient->query(sampleQuery);
    if queryResult is error {
        test:assertFail(msg = queryResult.message());
    } else {
        int count = check countStream(queryResult);
        test:assertTrue(count > 0, msg = "Found 0 search records!");
    }
}

@test:Config {
    enable: true
}
function testQueryWithLimit() returns error? {
    log:printInfo("baseClient -> getQueryResultWithLimit()");
    string sampleQuery = "SELECT Name,Industry FROM Account LIMIT 3";
    stream<Account, error?>|error queryResult = check baseClient->query(sampleQuery);
    if queryResult is error {
        test:assertFail(queryResult.message());
    } else {
        int count = check countStream(queryResult);
        test:assertTrue(count > 0, msg = "Found 0 search records!");
    }
}

type AccountResultWithAlias record {|
    string Name;
    int NumAccounts;
|};

@test:Config {
    enable: true
}
function testQueryWithAggregateFunctionWithAlias() returns error? {
    log:printInfo("baseClient -> testQueryWithAggregateFunctionWithAlias()");
    string sampleQuery = "SELECT COUNT(Id) NumAccounts, Name FROM Account GROUP BY Name";
    stream<AccountResultWithAlias, error?>|error queryResult = check baseClient->query(sampleQuery);
    if queryResult is error {
        test:assertFail(msg = queryResult.message());
    } else {
        int count = check countStream(queryResult);
        test:assertTrue(count > 0, msg = "Found 0 search records!");
    }
}

type AccountResultWithoutAlias record {|
    int expr0;
|};

@test:Config {
    enable: true
}
function testQueryWithAggregateFunctionWithoutAlias() returns error? {
    log:printInfo("baseClient -> testQueryWithAggregateFunctionWithoutAlias()");
    string sampleQuery = "SELECT COUNT(Id) FROM Account";
    stream<AccountResultWithoutAlias, error?>|error queryResult = check baseClient->query(sampleQuery);
    if queryResult is error {
        test:assertFail(msg = queryResult.message());
    } else {
        int count = check countStream(queryResult);
        test:assertTrue(count == 1, msg = "Found 0 search records!");
    }
}

@test:Config {
    enable: false
}
function testQueryWithPagination() returns error? {
    log:printInfo("baseClient -> getQueryResultWithPagination()");
    string sampleQuery = "SELECT Name FROM Contact";
    stream<Account, error?> resultStream = check baseClient->query(sampleQuery);
    int count = check countStream(resultStream);
    log:printInfo("Number of records", count = count);
    test:assertTrue(count > 2000, msg = "Found less than or exactly 2000 search records!");
}

@test:Config {
    enable: true,
    dependsOn: [testUpdate]
}
function testSearch() returns error? {
    log:printInfo("baseClient -> search()");
    string searchString = "FIND {MAAS Holdings}";
    stream<record {}, error?>|error queryResult = baseClient->search(searchString);
    if queryResult is error {
        test:assertFail(msg = queryResult.message());
    } else {
        int count = check countStream(queryResult);
        test:assertTrue(count > 0, msg = "Found 0 search records!");
    }
}

@test:Config {
    enable: true
}
function testLimits() {
    log:printInfo("baseClient -> getLimits()");
    map<Limit>|error limits = baseClient->getLimits();

    if limits is map<Limit> {
        test:assertTrue(limits.length() > 0, msg = "Found empty resource map");
        string[] keys = limits.keys();
        test:assertTrue(keys.length() > 0, msg = "Response doesn't have enough keys");
        foreach string key in keys {
            Limit? lim = limits[key];
            if lim is Limit {
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

@test:Config {
    enable: true
}
function testOrganizationMetaData() {
    log:printInfo("baseClient -> getOrganizationMetaData()");
    OrganizationMetadata|error description = baseClient->getOrganizationMetaData();

    if description is OrgMetadata {
        test:assertTrue(description.length() > 0, msg = "Found empty descriptions");
    } else {
        test:assertFail(msg = description.message());
    }
}

@test:Config {
    enable: true
}
function testBasicInfo() {
    log:printInfo("baseClient -> getBasicInfo()");
    SObjectBasicInfo|error description = baseClient->getBasicInfo("Account");

    if description is SObjectBasicInfo {
        test:assertTrue(description.length() > 0, msg = "Found empty descriptions");
    } else {
        test:assertFail(msg = description.message());
    }
}

@test:Config {
    enable: true
}
function testDescribe() {
    log:printInfo("baseClient -> describe()");
    SObjectMetaData|error description = baseClient->describe("Account");

    if description is SObjectMetaData {
        test:assertTrue(description.length() > 0, msg = "Found empty descriptions");
    } else {
        test:assertFail(msg = description.message());
    }
}

@test:Config {
    enable: true
}
function testPlatformAction() {
    log:printInfo("baseClient -> getPlatformAction()");
    SObjectBasicInfo|error description = baseClient->getPlatformAction();

    if description is SObjectBasicInfo {
        test:assertTrue(description.length() > 0, msg = "Found empty descriptions");
    } else {
        test:assertFail(msg = description.message());
    }
}

@test:Config {
    enable: true
}
function testApiVersions() {
    log:printInfo("baseClient -> getApiVersions()");
    Version[]|error versions = baseClient->getApiVersions();

    if versions is Version[] {
        test:assertTrue(versions.length() > 0, msg = "Found 0 or No API versions");
    } else {
        test:assertFail(msg = versions.message());
    }
}

@test:Config {
    enable: true
}
function testResources() {
    log:printInfo("baseClient -> getResources()");
    map<string>|error resources = baseClient->getResources(API_VERSION);

    if resources is map<string> {
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

@test:AfterSuite {}
function testDeleteRecordNew() returns error? {
    log:printInfo("baseClient -> delete()");
    error? response = baseClient->delete(ACCOUNT, testRecordIdNew);
    if response is error {
        test:assertFail(msg = response.message());
    }
}

//////////////////////////////////////////// DEPRECATED ////////////////////////////////////////////////////////////////

json accountRecordJson = {
    Name: "John Keells Holdings",
    BillingCity: "Colombo 3"
};

string testRecordIdJson = "";

@test:Config {
    enable: true,
    groups: ["deprecated"]
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
    dependsOn: [testCreateRecord],
    groups: ["deprecated"]
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
    dependsOn: [testCreateRecord, testGetRecord],
    groups: ["deprecated"]
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
    dependsOn: [testSearchSOSLString],
    groups: ["deprecated"]
}
function testDeleteRecord() {
    log:printInfo("baseClient -> deleteRecord()");
    Error? response = baseClient->deleteRecord(ACCOUNT, testRecordIdJson);

    if response is Error {
        test:assertFail(msg = response.message());
    }
}

@test:Config {
    enable: true,
    groups: ["deprecated"]
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
    dependsOn: [testUpdateRecord],
    groups: ["deprecated"]
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
    enable: true,
    groups: ["deprecated"]
}
function testGetQueryResultStream() returns error? {
    log:printInfo("baseClient -> getQueryResultStream()");
    string sampleQuery = "SELECT Name,Industry FROM Account";
    stream<record {}, error?> resultStream = check baseClient->getQueryResultStream(sampleQuery);
    int count = check countStream(resultStream);
    test:assertTrue(count > 0, msg = "Found 0 search records!");
}

@test:Config {
    enable: true,
    groups: ["deprecated"]
}
function testGetQueryResultWithLimit() returns error? {
    log:printInfo("baseClient -> getQueryResultWithLimit()");
    string sampleQuery = "SELECT Name,Industry FROM Account LIMIT 3";
    stream<record {}, error?> resultStream = check baseClient->getQueryResultStream(sampleQuery);
    int count = check countStream(resultStream);
    test:assertTrue(count > 0, msg = "Found 0 search records!");
}

@test:Config {
    enable: false,
    groups: ["deprecated"]
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
    dependsOn: [testUpdateRecord],
    groups: ["deprecated"]
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
