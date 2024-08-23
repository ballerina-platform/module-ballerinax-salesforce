// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/log;
import ballerina/os;
import ballerina/test;
import ballerina/time;
import ballerina/lang.runtime;

// Create Salesforce client configuration by reading from environemnt.
configurable string clientId = os:getEnv("CLIENT_ID");
configurable string clientSecret = os:getEnv("CLIENT_SECRET");
configurable string refreshToken = os:getEnv("REFRESH_TOKEN");
configurable string refreshUrl = os:getEnv("REFRESH_URL");
configurable string baseUrl = os:getEnv("EP_URL");

string reportInstanceID = "";

// Using direct-token config for client configuration
ConnectionConfig sfConfigRefreshCodeFlow = {
    baseUrl: baseUrl,
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
    }
};

ConnectionConfig sfConfigCredentialsFlow = {
    baseUrl: baseUrl,
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        tokenUrl: refreshUrl
    }
};

Client baseClient = check new (sfConfigRefreshCodeFlow);
// Client baseClientPasswordFlow = check new (sfConfigPasswordFlow);
// Client baseClientCredentialsFlow = check new (sfConfigCredentialsFlow);

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

public type Layout record {
    record{}[] layouts;
    json recordTypeMappings;
    boolean[] recordTypeSelectorRequired;
};

type AccountResultWithAlias record {
    string Name;
    int NumAccounts;
};

type AccountResultWithoutAlias record {
    int expr0;
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
    dependsOn: [testCreate, testGetById]
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

// @test:Config {
//     enable: false
// }
// function testQueryPasswordFlow() returns error? {
//     log:printInfo("baseClientPasswordFlow -> query()");
//     stream<Account, error?> queryResult = 
//         check baseClientPasswordFlow->query("SELECT name FROM Account");
//     int count = check countStream(queryResult);
//     test:assertTrue(count > 0, msg = "Found 0 search records!");
// }

// @test:Config {
//     enable: false
// }
// function testQueryCredentialsFlow() returns error? {
//     log:printInfo("baseClientCredentialsFlow -> query()");
//     stream<Account, error?> queryResult = 
//         check baseClientCredentialsFlow->query("SELECT name FROM Account");
//     int count = check countStream(queryResult);
//     test:assertTrue(count > 0, msg = "Found 0 search records!");
// }


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

    if description is OrganizationMetadata {
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
function testgetDeleted() {
    log:printInfo("baseClient -> getDeletedRecords()");
    DeletedRecordsResult|error deletedRecords = baseClient->getDeletedRecords("Account", time:utcToCivil(time:utcNow()),
        time:utcToCivil(time:utcAddSeconds(time:utcNow(), -86400)));

    if deletedRecords !is DeletedRecordsResult {
        test:assertFail(msg = deletedRecords.message());
    }
}

@test:Config {
    enable: true
}
function testgetUpdated() {
    log:printInfo("baseClient -> getUpdatedRecords()");
    UpdatedRecordsResults|error updatedRecords = baseClient->getUpdatedRecords("Account", time:utcToCivil(time:utcNow()),
        time:utcToCivil(time:utcAddSeconds(time:utcNow(), -86400)));
    if updatedRecords !is UpdatedRecordsResults {
        test:assertFail(msg = updatedRecords.message());
    }
}

@test:Config {
    enable: true
}
function testgetPasswordInfo() returns error? {
    log:printInfo("baseClient -> getPasswordInfo()");
    boolean _ = check baseClient->isPasswordExpired("0055g00000J48In");
}

@test:Config {
    enable: false,
    dependsOn: [testgetPasswordInfo]
}
function testResetPassword() returns error? {
    log:printInfo("baseClient -> resetPassword()");
    runtime:sleep(10);
    byte[]|error resettedPassword = baseClient->resetPassword("");
    if resettedPassword !is byte[] {
        test:assertFail(msg = resettedPassword.message());
    }
}

@test:Config {
    enable: false,
    dependsOn: [testResetPassword]
}
function testSetPassword() returns error? {
    log:printInfo("baseClient -> changePassword()");
    string newPassword = "";
    error? response = baseClient->changePassword("", newPassword);
    if response !is () {
        test:assertFail(msg = response.message());
    }
}
@test:Config {
    enable: true,
    dependsOn: []
}
function testGetQuickActions() returns error? {
    log:printInfo("baseClient -> getQuickActions()");
    QuickAction[]|error resp = baseClient->getQuickActions("Contact");
    if resp !is QuickAction[] {
        test:assertFail(msg = resp.message());
    }
}

@test:Config {
    enable: true,
    dependsOn: []
}
function testListReports() returns error? {
    log:printInfo("baseClient -> listReports()");
    Report[]|error resp = baseClient->listReports();
    if resp !is Report[] {
        test:assertFail(msg = resp.message());
    }
    if resp.length() == 0{
        test:assertFail("No reports found");
    }
}

@test:Config {
    enable: true,
    dependsOn: []
}
function testRunReportSync() returns error? {
    log:printInfo("baseClient -> runReportSync()");
    ReportInstanceResult|error resp = baseClient->runReportSync("00O5g00000Jrs9DEAR");
    if resp !is ReportInstanceResult {
        test:assertFail(msg = resp.message());
    }
    if resp.length() == 0 {
        test:assertFail("No reports found");
    }
}

@test:Config {
    enable: true,
    dependsOn: []
}
function testRunReportAsync() returns error? {
    log:printInfo("baseClient -> runReportAsync()");
    ReportInstance|error resp = baseClient->runReportAsync("00O5g00000Jrs9DEAR");
    if resp !is ReportInstance {
        test:assertFail(msg = resp.message());
    }
    if resp.id == "" {
        test:assertFail("No reports found");
    }
}

@test:Config {
    enable: true,
    dependsOn: [testRunReportAsync]
}
function testListAsyncRunsOfReport() returns error? {
    log:printInfo("baseClient -> listAsyncRunsOfReport()");
    ReportInstance[]|error resp = baseClient->listAsyncRunsOfReport("00O5g00000Jrs9DEAR");
    if resp !is ReportInstance[] {
        test:assertFail(msg = resp.message());
    }
    if resp.length() == 0 {
        test:assertFail("No reports found");
    }
    reportInstanceID = resp[0].id;
}

@test:Config {
    enable: true,
    dependsOn: [testListAsyncRunsOfReport]
}
function testGetReportInstanceResult() returns error? {
    log:printInfo("baseClient -> getReportInstanceResult()");
    ReportInstanceResult|error resp = baseClient->getReportInstanceResult("00O5g00000Jrs9DEAR", reportInstanceID);
    if resp !is ReportInstanceResult {
        test:assertFail(msg = resp.message());
    }
    if resp.length() == 0 {
        test:assertFail("No reports found");
    }
}


@test:Config {
    enable: true
}
function testBatchExecute() returns error? {
    log:printInfo("baseClient -> batch()");
    Subrequest[] subrequests = [{method: "GET", url: "/services/data/v59.0/sobjects/Account/describe"},
                                {method: "GET", url: "/services/data/v59.0/sobjects/Contact/describe"}];
    BatchResult|error batchResult = baseClient->batch(subrequests, true);
    if batchResult !is BatchResult {
        test:assertFail(msg = batchResult.message());
    } else {
        test:assertFalse(batchResult.hasErrors, msg = "Batch result has errors");
    }
}

@test:Config {
    enable: true,
    dependsOn: []
}
function testGeNamedLayouts() returns error? {
    log:printInfo("baseClient -> getNamedLayouts()");
    Layout|error resp = baseClient->getNamedLayouts("User", "UserAlt");
    if resp !is Layout {
        test:assertFail(msg = resp.message());
    } else {
        if (resp.layouts.length() > 0) {
            test:assertTrue(resp.layouts.length() > 0, msg = "Layout is empty");
        }
    }
}

@test:Config {
    enable: true,
    dependsOn: []
}
function testDeleteByExternalId() returns error? {
    log:printInfo("baseClient -> deleteRecordsUsingExtId()");
    CreationResponse|error creation = check baseClient->create("Asset", {"Name": "testAsset", "assetExt_id__c": "asdfg", "AccountId":"0015g00001Per6rAAB"});
    if creation is error {
        test:assertFail(msg = creation.message());
    }
    runtime:sleep(10);
    error? response = baseClient->deleteRecordsUsingExtId("Asset", "assetExt_id__c", "asdfg");
    if response is error {
        test:assertFail(msg = response.message());
    }
}

@test:Config {
    enable: true,
    dependsOn: []
}
function testlistReports() returns error? {
    log:printInfo("baseClient -> listReports()");
    Report[]|error creation = check baseClient->listReports();
    if creation is error {
        test:assertFail(msg = creation.message());
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

@test:Config {
    enable: true
}
function testApex() returns error? {
    log:printInfo("baseClient -> executeApex()");
    string|error caseId = baseClient->apexRestExecute("Cases", "POST", 
        {"subject" : "Bigfoot Sighting9!",
            "status" : "New",
            "origin" : "Phone",
            "priority" : "Low"});
    if caseId is error {
        test:assertFail(msg = caseId.message());
    }
    runtime:sleep(5);
    record{}|error case = baseClient->apexRestExecute(string `Cases/${caseId}`, "GET", {});
    if case is error {
        test:assertFail(msg = case.message());
    }
    runtime:sleep(5);
    error? deleteResponse = baseClient->apexRestExecute(string `Cases/${caseId}`, "DELETE", {});
    if deleteResponse is error {
        test:assertFail(msg = deleteResponse.message());
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

/////////////////////////////////////////// Helper Functions ///////////////////////////////////////////////////////////

isolated function countStream(stream<record {}, error?> resultStream) returns int|error {
    int nLines = 0;
    check from record {} _ in resultStream
        do {
            nLines += 1;
        };
    return nLines;
}
