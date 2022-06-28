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

//  SObjects
# Constant field `ACCOUNT`. Holds the value Account for account object.
const string ACCOUNT = "Account";

# Constant field `LEAD`. Holds the value Lead for lead object.
const string LEAD = "Lead";

# Constant field `CONTACT`. Holds the value Contact for contact object.
const string CONTACT = "Contact";

# Constant field `OPPORTUNITY`. Holds the value Opportunity for opportunity object.
const string OPPORTUNITY = "Opportunity";

# Constant field `PRODUCT`. Holds the value Product2 for product object.
const string PRODUCT = "Product2";

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

public type Account record {
    string Id?;
    boolean IsDeleted?;
    string? MasterRecordId?;
    string Name?;
    anydata? Type = ();
    string? ParentId = ();
    string? BillingStreet = ();
    string? BillingCity = ();
    string? BillingState = ();
    string? BillingPostalCode = ();
    string? BillingCountry = ();
    float? BillingLatitude = ();
    float? BillingLongitude = ();
    anydata? BillingGeocodeAccuracy = ();
    anydata? BillingAddress?;
    string? ShippingStreet = ();
    string? ShippingCity = ();
    string? ShippingState = ();
    string? ShippingPostalCode = ();
    string? ShippingCountry = ();
    float? ShippingLatitude = ();
    float? ShippingLongitude = ();
    anydata? ShippingGeocodeAccuracy = ();
    anydata? ShippingAddress?;
    string? Phone = ();
    string? Fax = ();
    string? AccountNumber = ();
    string? Website = ();
    string? PhotoUrl?;
    string? Sic = ();
    anydata? Industry = ();
    float? AnnualRevenue = ();
    int? NumberOfEmployees = ();
    anydata? Ownership = ();
    string? TickerSymbol = ();
    string? Description = ();
    anydata? Rating = ();
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
    anydata? CleanStatus = ();
    anydata? AccountSource = ();
    string? DunsNumber = ();
    string? Tradestyle = ();
    string? NaicsCode = ();
    string? NaicsDesc = ();
    string? YearStarted = ();
    string? SicDesc = ();
    string? DandbCompanyId = ();
    string? OperatingHoursId = ();
    anydata? CustomerPriority__c = ();
    anydata? SLA__c = ();
    anydata? Active__c = ();
    float? NumberofLocations__c = ();
    anydata? UpsellOpportunity__c = ();
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
function testCreateRecordNew() {
    log:printInfo("baseClient -> createRecordNew()");
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
    dependsOn: [testCreateRecordNew]
}
function testGetRecordByIdNew() {
    log:printInfo("baseClient -> testGetRecordByIdNew()");
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
    dependsOn: [testCreateRecordNew]
}
function testGetRecordByExternalIdNew() {
    log:printInfo("baseClient -> testGetRecordByIdNew()");
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
    dependsOn: [testCreateRecordNew, testGetRecordByIdNew]
}
function updateRecordNew() {
    log:printInfo("baseClient -> updateRecordNew()");
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
function testGetQueryResultNew() returns error? {
    log:printInfo("baseClient -> getQueryResultNew()");
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
function testGetQueryResultWithLimitNew() returns error? {
    log:printInfo("baseClient -> getQueryResultWithLimitNew()");
    string sampleQuery = "SELECT Name,Industry FROM Account LIMIT 3";
    stream<Account, error?>|error queryResult = check baseClient->query(sampleQuery);
    if queryResult is error {
        test:assertFail(queryResult.message());
    } else {
        int count = check countStream(queryResult);
        test:assertTrue(count > 0, msg = "Found 0 search records!");
    }
}

@test:Config {
    enable: false
}
function testGetQueryResultWithPaginationNew() returns error? {
    log:printInfo("baseClient -> getQueryResultWithPaginationNew()");
    string sampleQuery = "SELECT Name FROM Contact";
    stream<Account, error?> resultStream = check baseClient->query(sampleQuery);
    int count = check countStream(resultStream);
    log:printInfo("Number of records", count = count);
    test:assertTrue(count > 2000, msg = "Found less than or exactly 2000 search records!");
}

@test:Config {
    enable: true,
    dependsOn: [updateRecordNew]
}
function testSearchSOSLStringNew() returns error? {
    log:printInfo("baseClient -> searchSOSLStringNew()");
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
function testGetOrganizationLimits() {
    log:printInfo("baseClient -> getOrganizationLimits()");
    map<Limit>|error limits = baseClient->getOrganizationLimits();

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
function testdescribeSobject() {
    log:printInfo("baseClient -> describeAvailableObjects()");
    OrgMetadata|error description = baseClient->describeAvailableObjects();

    if description is OrgMetadata {
        test:assertTrue(description.length() > 0, msg = "Found empty descriptions");
    } else {
        test:assertFail(msg = description.message());
    }
}

@test:Config {
    enable: true
}
function testGetSobjectBasicInfo() {
    log:printInfo("baseClient -> getSobjectBasicInfo()");
    SObjectBasicInfo|error description = baseClient->getSObjectBasicInfo("Account");

    if description is SObjectBasicInfo {
        test:assertTrue(description.length() > 0, msg = "Found empty descriptions");
    } else {
        test:assertFail(msg = description.message());
    }
}

@test:Config {
    enable: true
}
function testDescribesObject() {
    log:printInfo("baseClient -> describesObject()");
    SObjectMetaData|error description = baseClient->describeSObject("Account");

    if description is SObjectMetaData {
        test:assertTrue(description.length() > 0, msg = "Found empty descriptions");
    } else {
        test:assertFail(msg = description.message());
    }
}

@test:Config {
    enable: true
}
function testGetSobjectPlatformAction() {
    log:printInfo("baseClient -> getSobjectPlatformAction()");
    SObjectBasicInfo|error description = baseClient->sObjectPlatformAction();

    if description is SObjectBasicInfo {
        test:assertTrue(description.length() > 0, msg = "Found empty descriptions");
    } else {
        test:assertFail(msg = description.message());
    }
}

@test:Config {
    enable: true
}
function testGetAvailableApiVersions() {
    log:printInfo("baseClient -> getAvailableApiVersions()");
    Version[]|error versions = baseClient->getAvailableApiVersions();

    if versions is Version[] {
        test:assertTrue(versions.length() > 0, msg = "Found 0 or No API versions");
    } else {
        test:assertFail(msg = versions.message());
    }
}

@test:Config {
    enable: true
}
function testGetResourcesByApiVersion() {
    log:printInfo("baseClient -> getResourcesByApiVersion()");
    map<string>|error resources = baseClient->getResourcesByApiVersion(API_VERSION);

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
    log:printInfo("baseClient -> deleteRecordNew()");
    error? response = baseClient->delete(ACCOUNT, testRecordIdNew);
    if response is error {
        test:assertFail(msg = response.message());
    }
}

/////////////////////////////////////////// Helper Functions ///////////////////////////////////////////////////////////

isolated function countStream(stream<record {},error?> resultStream) returns int|error {
    int nLines = 0;
    check from record {} _ in resultStream
        do {
            nLines += 1;
        };
    return nLines;
}
