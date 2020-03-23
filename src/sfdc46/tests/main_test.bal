// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/time;
import ballerina/system;
import ballerina/config;

// Create Salesforce client configuration by reading from config file.
SalesforceConfiguration sfConfig = {
    baseUrl: config:getAsString("EP_URL"),
    clientConfig: {
        accessToken: config:getAsString("ACCESS_TOKEN"),
        refreshConfig: {
            clientId: config:getAsString("CLIENT_ID"),
            clientSecret: config:getAsString("CLIENT_SECRET"),
            refreshToken: config:getAsString("REFRESH_TOKEN"),
            refreshUrl: config:getAsString("REFRESH_URL")
        }
    }
};

string testAccountId = "";
string testLeadId = "";
string testContactId = "";
string testOpportunityId = "";
string testProductId = "";
string testRecordId = "";
string testExternalID = system:uuid().substring(0, 32);
string testIdOfSampleOrg = "";

Client salesforceClient = new(sfConfig);

// Create salesforce bulk client.
SalesforceBulkClient sfBulkClient = salesforceClient->createSalesforceBulkClient();
// No of retries to get bulk results.
int noOfRetries = 25;
// Sample record.
json accountRecord = { 
    Name: "John Keells Holdings", 
    BillingCity: "Colombo 3" 
};
// Sample account.
json accountAbc = { 
    Name: "ABC Inc", 
    BillingCity: "New York" 
};
// Sample lead.
json lead = { 
    LastName: "Carmen", 
    Company: "WSO2", 
    City: "New York" 
};
// Sample contact.
json contact = { 
    LastName: "Patson" 
};
// Sample Opportunity.
json opportunity = { 
    Name: "DevServices", 
    StageName: "30 - Proposal/Price Quote", 
    CloseDate: "2019-01-01" 
};
// Sample product.
json product = { 
    Name: "APIM", 
    Description: "APIM product" 
};
// Sample record with external ID.
json accountExIdRecord = { 
    Name: "Sample Org", 
    BillingCity: "CA", 
    SF_ExternalID__c: testExternalID
};

@test:Config {}
function testGetAvailableApiVersions() {
    log:printInfo("salesforceClient -> getAvailableApiVersions()");
    Version[]|ConnectorError versions = salesforceClient->getAvailableApiVersions();

    if (versions is Version[]) {
        test:assertTrue(versions.length() > 0, msg = "Found 0 or No API versions");
    } else {
        test:assertFail(msg = versions.detail()?.message.toString());
    }
}

@test:Config {}
function testGetResourcesByApiVersion() {
    log:printInfo("salesforceClient -> getResourcesByApiVersion()");
    map<string>|ConnectorError resources = salesforceClient->getResourcesByApiVersion(API_VERSION);

    if (resources is map<string>) {
        test:assertTrue(resources.length() > 0, msg = "Found empty resource map");
        test:assertTrue(trim(resources["sobjects"].toString()).length() > 0, msg = "Found null for resource sobjects");
        test:assertTrue(trim(resources["search"].toString()).length() > 0, msg = "Found null for resource search");
        test:assertTrue(trim(resources["query"].toString()).length() > 0, msg = "Found null for resource query");
        test:assertTrue(trim(resources["licensing"].toString()).length() > 0, 
            msg = "Found null for resource licensing");
        test:assertTrue(trim(resources["connect"].toString()).length() > 0, msg = "Found null for resource connect");
        test:assertTrue(trim(resources["tooling"].toString()).length() > 0, msg = "Found null for resource tooling");
        test:assertTrue(trim(resources["chatter"].toString()).length() > 0, msg = "Found null for resource chatter");
        test:assertTrue(trim(resources["recent"].toString()).length() > 0, msg = "Found null for resource recent");
    } else {
        test:assertFail(msg = resources.detail()?.message.toString());
    }
}

@test:Config {}
function testGetOrganizationLimits() {
    log:printInfo("salesforceClient -> getOrganizationLimits()");
    map<Limit>|ConnectorError limits = salesforceClient->getOrganizationLimits();

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
        test:assertFail(msg = limits.detail()?.message.toString());
    }
}

//============================ Basic functions================================//

@test:Config {}
function testCreateRecord() {
    log:printInfo("salesforceClient -> createRecord()");
    string|ConnectorError stringResponse = salesforceClient->createRecord(ACCOUNT, accountRecord);

    if (stringResponse is string) {
        test:assertNotEquals(stringResponse, "", msg = "Found empty response!");
        testRecordId = <@untainted> stringResponse;
    } else {
        test:assertFail(msg = stringResponse.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateRecord"]
}
function testGetRecord() {
    json|ConnectorError response;
    log:printInfo("salesforceClient -> getRecord()");
    string path = "/services/data/v46.0/sobjects/Account/" + testRecordId;
    response = salesforceClient->getRecord(path);

    if (response is json) {
        test:assertNotEquals(response, (), msg = "Found null JSON response!");
        test:assertEquals(response.Name, "John Keells Holdings", msg = "Name key mismatched in response");
        test:assertEquals(response.BillingCity, "Colombo 3", msg = "BillingCity key mismatched in response");
    } else {
        test:assertFail(msg = response.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateRecord", "testGetRecord"]
}
function testUpdateRecord() {
    log:printInfo("salesforceClient -> updateRecord()");
    json account = { Name: "WSO2 Inc", BillingCity: "Jaffna", Phone: "+94110000000" };
    boolean|ConnectorError response = salesforceClient->updateRecord(ACCOUNT, testRecordId, account);

    if (response is boolean) {
        test:assertTrue(response, msg = "Expects true on success");
    } else {
        test:assertFail(msg = response.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateRecord", "testGetRecord", "testUpdateRecord",
    "testGetFieldValuesFromSObjectRecord"]
}
function testDeleteRecord() {
    log:printInfo("salesforceClient -> deleteRecord()");
    boolean|ConnectorError response = salesforceClient->deleteRecord(ACCOUNT, testRecordId);

    if (response is boolean) {
        test:assertTrue(response, msg = "Expects true on success");
    } else {
        test:assertFail(msg = response.detail()?.message.toString());
    }
}

//=============================== Query ==================================//
@test:Config {}
function testGetQueryResult() {
    log:printInfo("salesforceClient -> getQueryResult()");
    string sampleQuery = "SELECT name FROM Account";
    SoqlResult|ConnectorError res = salesforceClient->getQueryResult(sampleQuery);

    if (res is SoqlResult) {
        assertSoqlResult(res);
        string|error nextRecordsUrl = res["nextRecordsUrl"].toString();

        while (nextRecordsUrl is string && trim(nextRecordsUrl) != EMPTY_STRING) {
            log:printInfo("Found new query result set! nextRecordsUrl:" + nextRecordsUrl);
            SoqlResult|ConnectorError resp = salesforceClient->getNextQueryResult(<@untainted> nextRecordsUrl);

            if (resp is SoqlResult) {
                assertSoqlResult(resp);
                res = resp;
            } else {
                test:assertFail(msg = resp.detail()?.message.toString());
            }
        }
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testGetQueryResult"]
}
function testGetAllQueries() {
    log:printInfo("salesforceClient -> getAllQueries()");
    string sampleQuery = "SELECT Name from Account WHERE isDeleted=TRUE";
    SoqlResult|ConnectorError res = salesforceClient->getQueryAllResult(sampleQuery);
    assertSoqlResult(res);
}

@test:Config {}
function testExplainQueryOrReportOrListview() {
    log:printInfo("salesforceClient -> explainQueryOrReportOrListview()");
    string queryString = "SELECT name FROM Account";
    ExecutionFeedback|ConnectorError res = salesforceClient->explainQueryOrReportOrListview(queryString);

    if (res is ExecutionFeedback) {
        test:assertTrue(res.plans.length() > 0, "Found 0 execution plans");
        test:assertTrue(res["sourceQuery"].toString() == queryString, "Src query mismatched");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}

function assertSoqlResult(SoqlResult|ConnectorError res) {
    if (res is SoqlResult) {
        test:assertTrue(res.totalSize > 0, "Total number result records is 0");
        test:assertTrue(res.'done, "Query is not completed");
        test:assertTrue(res.records.length() == res.totalSize, "Query result records not equal to totalSize");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}

//=============================== Search ==================================//

@test:Config {
    dependsOn: ["testCreateAccount"]
}
function testSearchSOSLString() {
    log:printInfo("salesforceClient -> searchSOSLString()");
    string searchString = "FIND {ABC Inc}";
    SoslResult|ConnectorError res = salesforceClient->searchSOSLString(searchString);

    if (res is SoslResult) {
        test:assertTrue(res.searchRecords.length() > 0, msg = "Found 0 search records!");
        test:assertTrue(res.searchRecords[0].attributes.'type == ACCOUNT, 
            msg = "Matched search record is not an Account type!");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}

//============================ SObject Information ===============================//

@test:Config {}
function testGetSObjectBasicInfo() {
    log:printInfo("salesforceClient -> getSObjectBasicInfo()");
    SObjectBasicInfo|ConnectorError res = salesforceClient->getSObjectBasicInfo("Account");

    if (res is SObjectBasicInfo) {
        test:assertNotEquals(res, (), msg = "Found null response!");
        test:assertNotEquals(res.objectDescribe, (), msg = "Found null response for objectDescribe!");
        test:assertEquals(res.objectDescribe.label, ACCOUNT, msg = "label is not Account!");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}

@test:Config {}
function testSObjectPlatformAction() {
    log:printInfo("salesforceClient -> sObjectPlatformAction()");
    SObjectBasicInfo|ConnectorError res = salesforceClient->sObjectPlatformAction();

    if (res is SObjectBasicInfo) {
        test:assertNotEquals(res, (), msg = "Found null response!");
        test:assertNotEquals(res.objectDescribe, (), msg = "Found null response for objectDescribe!");
        test:assertEquals(res.objectDescribe.name, "PlatformAction", msg = "name is not `PlatformAction`!");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}

@test:Config {}
function testDescribeAvailableObjects() {
    log:printInfo("salesforceClient -> describeAvailableObjects()");
    OrgMetadata|ConnectorError res = salesforceClient->describeAvailableObjects();

    if (res is OrgMetadata) {
        test:assertNotEquals(res, (), msg = "Found null response!");
        test:assertEquals(res.encoding, "UTF-8", msg = "Encoding mismatched!");
        test:assertTrue(res.sobjects.length() > 0, msg = "sobjects list is empty!");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}


@test:Config {}
function testDescribeSObject() {
    log:printInfo("salesforceClient -> describeSObject()");
    SObjectMetaData|ConnectorError res = salesforceClient->describeSObject(ACCOUNT);

    if (res is SObjectMetaData) {
        test:assertNotEquals(res, (), msg = "Found null response!");
        json[] fields = <json[]> res["fields"];
        test:assertTrue(fields.length() > 0, msg = "Fields are empty!");
        test:assertEquals(res.label, ACCOUNT, msg = "label is mismatched!");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}

//=============================== Records Related ==================================//

@test:Config {
    dependsOn: ["testCsvDeleteOperator"]
}
function testGetDeletedRecords() {
    log:printInfo("salesforceClient -> getDeletedRecords()");

    time:Time now = time:currentTime();
    string|error time1 = time:format(now, "yyyy-MM-dd'T'HH:mm:ssZ");
    string endDateTime = "";
    if (time1 is string) {
        endDateTime = time1;
    } else {
        test:assertFail(msg = time1.toString());
    }
    time:Time weekAgo = time:subtractDuration(now, 0, 0, 1, 0, 0, 0, 0);
    string|error time2 = time:format(weekAgo, "yyyy-MM-dd'T'HH:mm:ssZ");
    string startDateTime = "";
    if (time2 is string) {
        startDateTime = time2;
    } else {
        test:assertFail(msg = time2.toString());
    }

    DeletedRecordsInfo|ConnectorError res = salesforceClient->getDeletedRecords("Account", startDateTime, endDateTime);

    if (res is DeletedRecordsInfo) {
        test:assertNotEquals(res, (), msg = "Found null response!");
        test:assertTrue(res.deletedRecords.length() > 0, msg = "No deleted records!");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testJsonUpdateOperator", "testUpdateContact"]
}
function testGetUpdatedRecords() {
    log:printInfo("salesforceClient -> getUpdatedRecords()");

    time:Time now = time:currentTime();
    string|error time1 = time:format(now, "yyyy-MM-dd'T'HH:mm:ssZ");
    string endDateTime = (time1 is string) ? time1 : "";
    time:Time weekAgo = time:subtractDuration(now, 0, 0, 1, 0, 0, 0, 0);
    string|error time2 = time:format(weekAgo, "yyyy-MM-dd'T'HH:mm:ssZ");
    string startDateTime = (time2 is string) ? time2 : "";

    UpdatedRecordsInfo|ConnectorError res = salesforceClient->getUpdatedRecords("Contact", startDateTime, endDateTime);

    if (res is UpdatedRecordsInfo) {
        test:assertNotEquals(res, (), msg = "Found null response!");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}

@test:Config {}
function testCreateMultipleRecords() {
    log:printInfo("salesforceClient -> createMultipleRecords()");
    SObjectTreeResponse|ConnectorError response;

    json multipleRecords = { 
        "records": [
            {
                "attributes": { 
                    "type": "Account", 
                    "referenceId": "ref1" 
                },
                "name": "SampleAccount1",
                "phone": "1111111111",
                "website": "www.sfdc.com",
                "numberOfEmployees": "100",
                "industry": "Banking"
            }, 
            {
                "attributes": { 
                    "type": "Account", 
                    "referenceId": "ref2" 
                },
                "name": "SampleAccount2",
                "phone": "2222222222",
                "website": "www.salesforce2.com",
                "numberOfEmployees": "250",
                "industry": "Banking"
            }
        ]
    };

    response = salesforceClient-> createMultipleRecords(<@untainted> ACCOUNT, multipleRecords);
    if (response is SObjectTreeResponse) {
        test:assertFalse(response.hasErrors, msg = "Errors when creating multiple records!");
        test:assertEquals(response.results.length(), 2, msg = "2 records hasn't created!");
        // Delete created records.
        deleteCreatedMultipleRecords(response);
    } else {
        test:assertFail(msg = response.detail()?.message.toString());
    }
}

function deleteCreatedMultipleRecords(SObjectTreeResponse res) {
    string sampleAcc1ID = res.results[0].id;
    string sampleAcc2ID = res.results[1].id;

    boolean|ConnectorError response1 = salesforceClient->deleteRecord(ACCOUNT, sampleAcc1ID);
    boolean|ConnectorError response2 = salesforceClient->deleteRecord(ACCOUNT, sampleAcc2ID);

    if (response1 is boolean) {
        test:assertTrue(response1, msg = "Expects true on success");
    } else {
        test:assertFail(msg = response1.detail()?.message.toString());
    }

    if (response2 is boolean) {
        test:assertTrue(response2, msg = "Expects true on success");
    } else {
        test:assertFail(msg = response2.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateRecord"]
}
function testGetFieldValuesFromSObjectRecord() {
    log:printInfo("salesforceClient -> getFieldValuesFromSObjectRecord()");
    SObject|ConnectorError res = 
        salesforceClient->getFieldValuesFromSObjectRecord("Account", <@untainted>testRecordId, "Name,BillingCity");

    if (res is SObject) {
        test:assertNotEquals(res, (), msg = "Found null JSON response!");
        test:assertEquals(res.Name, accountRecord.Name, msg = "Record Name mismatched!");
        test:assertEquals(res["BillingCity"], accountRecord.BillingCity, msg = "Record BillingCity mismatched!");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}

@test:Config {}
function testCreateRecordWithExternalId() {
    log:printInfo("salesforceClient -> CreateRecordWithExternalId()");

    string|ConnectorError stringResponse = salesforceClient->createRecord(ACCOUNT, accountExIdRecord);

    if (stringResponse is string) {
        test:assertNotEquals(stringResponse, "", msg = "Found empty response!");
        testIdOfSampleOrg = <@untainted> stringResponse;
    } else {
        test:assertFail(msg = stringResponse.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateRecordWithExternalId"]
}
function testGetRecordByExternalId() {
    log:printInfo("salesforceClient -> getRecordByExternalId()");
    SObject|ConnectorError res = 
        salesforceClient->getRecordByExternalId(ACCOUNT, "SF_ExternalID__c", testExternalID);

    if (res is SObject) {
        test:assertNotEquals(res, (), msg = "Found null response!");
        test:assertEquals(res.Name, accountExIdRecord.Name, msg = "Record Name mismatched!");
        test:assertEquals(res["BillingCity"], accountExIdRecord.BillingCity, msg = "Record BillingCity mismatched!");
        test:assertEquals(res["SF_ExternalID__c"], accountExIdRecord.SF_ExternalID__c, 
            msg = "Record SF_ExternalID__c mismatched!");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateRecordWithExternalId", "testGetRecordByExternalId"]
}
function testUpsertSObjectByExternalId() {
    log:printInfo("salesforceClient -> upsertSObjectByExternalId()");

    json upsertRecord = { 
        Name: "Sample Org", 
        BillingCity: "Jaffna, Colombo 3" 
    };

    SObjectResult|ConnectorError res = salesforceClient->upsertSObjectByExternalId(ACCOUNT, "SF_ExternalID__c", 
        testExternalID, upsertRecord);

    if (res is SObjectResult) {
        test:assertNotEquals(res, (), msg = "Found null response!");
        test:assertTrue(res.success, msg = "Upserting failed!");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}


@test:Config {
    dependsOn: ["testCreateRecordWithExternalId", "testUpsertSObjectByExternalId", "testGetRecordByExternalId"]
}
function testDeleteRecordWithExternalId() {
    log:printInfo("salesforceClient -> DeleteRecordWithExternalID");
    boolean|ConnectorError response = salesforceClient->deleteRecord(ACCOUNT, testIdOfSampleOrg);

    if (response is boolean) {
        test:assertTrue(response, msg = "Expects true on success");
    } else {
        test:assertFail(msg = response.detail()?.message.toString());
    }
}

// ============================ ACCOUNT SObject: get, create, update, delete ===================== //

@test:Config {}
function testCreateAccount() {
    log:printInfo("salesforceClient -> createAccount()");
    string|ConnectorError stringAccount = salesforceClient->createAccount(accountAbc);

    if (stringAccount is string) {
        test:assertNotEquals(stringAccount, "", msg = "Found empty response!");
        log:printDebug("Account id: " + stringAccount);
        testAccountId = <@untainted> stringAccount;
    } else {
        test:assertFail(msg = stringAccount.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateAccount"]
}
function testGetAccountById() {
    log:printInfo("salesforceClient -> getAccountById()");
    SObject|ConnectorError res = salesforceClient->getAccountById(testAccountId);

    if (res is SObject) {
        test:assertTrue(res.Id.length() > 0, msg = "Found null Account ID!");
        test:assertTrue(res.Name == accountAbc.Name, msg = "Account Name mismatched!");
        test:assertTrue(res["BillingCity"] == accountAbc.BillingCity, msg = "Account BillingCity mismatched!");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateAccount"]
}
function testUpdateAccount() {
    log:printInfo("salesforceClient -> updateAccount()");
    json|ConnectorError jsonRes = salesforceClient->updateAccount(testAccountId, accountAbc);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateAccount", "testUpdateAccount", "testGetAccountById", "testSearchSOSLString"]
}
function testDeleteAccount() {
    log:printInfo("salesforceClient -> deleteAccount()");
    json|ConnectorError jsonRes = salesforceClient->deleteAccount(testAccountId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

// ============================ LEAD SObject: get, create, update, delete ===================== //

@test:Config {}
function testCreateLead() {
    log:printInfo("salesforceClient -> createLead()");
    string|ConnectorError stringLead = salesforceClient->createLead(lead);

    if (stringLead is string) {
        test:assertNotEquals(stringLead, "", msg = "Found empty response!");
        log:printDebug("Lead id: " + stringLead);
        testLeadId = <@untainted> stringLead;
    } else {
        test:assertFail(msg = stringLead.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateLead"]
}
function testGetLeadById() {
    log:printInfo("salesforceClient -> getLeadById()");
    SObject|ConnectorError res = salesforceClient->getLeadById(testLeadId);

    if (res is SObject) {
        test:assertEquals(res["LastName"], lead.LastName, msg = "Lead LastName mismatched!");
        test:assertEquals(res["Company"], lead.Company, msg = "Lead Company mismatched!");
        test:assertEquals(res["City"], lead.City, msg = "Lead City mismatched!");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateLead"]
}
function testUpdateLead() {
    log:printInfo("salesforceClient -> updateLead()");
    json updateLead = { LastName: "Carmen", Company: "WSO2 Lanka (Pvt) Ltd" };
    json|ConnectorError jsonRes = salesforceClient->updateLead(testLeadId, updateLead);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateLead", "testUpdateLead", "testGetLeadById"]
}
function testDeleteLead() {
    log:printInfo("salesforceClient -> deleteLead()");
    json|ConnectorError jsonRes = salesforceClient->deleteLead(testLeadId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

// ============================ CONTACTS SObject: get, create, update, delete ===================== //

@test:Config {}
function testCreateContact() {
    log:printInfo("salesforceClient -> createContact()");
    string|ConnectorError stringContact = salesforceClient->createContact(contact);

    if (stringContact is string) {
        test:assertNotEquals(stringContact, "", msg = "Found empty response!");
        log:printDebug("Contact id: " + stringContact);
        testContactId = <@untainted> stringContact;
    } else {
        test:assertFail(msg = stringContact.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateContact"]
}
function testGetContactById() {
    log:printInfo("salesforceClient -> getContactById()");
    SObject|ConnectorError res = salesforceClient->getContactById(testContactId);

    if (res is SObject) {
        test:assertNotEquals(res, (), msg = "Found null JSON response!");
        test:assertEquals(res["LastName"], contact.LastName, msg = "Contact LastName mismatched!");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateContact", "testGetContactById"]
}
function testUpdateContact() {
    log:printInfo("salesforceClient -> updateContact()");
    json updateContact = { LastName: "Rebert Patson" };
    json|ConnectorError jsonRes = salesforceClient->updateContact(testContactId, updateContact);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateContact", "testUpdateContact", "testGetContactById"]
}
function testDeleteContact() {
    log:printInfo("salesforceClient -> deleteContact()");
    json|ConnectorError jsonRes = salesforceClient->deleteContact(testContactId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

// ============================ PRODUCTS SObject: get, create, update, delete ===================== //

@test:Config {}
function testCreateProduct() {
    log:printInfo("salesforceClient -> createProduct()");
    string|ConnectorError stringProduct = salesforceClient->createProduct(product);

    if (stringProduct is string) {
        test:assertNotEquals(stringProduct, "", msg = "Found empty response!");
        log:printDebug("Product id: " + stringProduct);
        testProductId = <@untainted> stringProduct;
    } else {
        test:assertFail(msg = stringProduct.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateProduct"]
}
function testGetProductById() {
    log:printInfo("salesforceClient -> getProductById()");
    SObject|ConnectorError res = salesforceClient->getProductById(testProductId);

    if (res is SObject) {
        test:assertNotEquals(res, (), msg = "Found null JSON response!");
        test:assertEquals(res.Name, product.Name, msg = "Product Name mismatched!");
        test:assertEquals(res["Description"], product.Description, msg = "Product Description mismatched!");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateProduct"]
}
function testUpdateProduct() {
    log:printInfo("salesforceClient -> updateProduct()");
    json updateProduct = { Name: "APIM", Description: "APIM new product" };
    json|ConnectorError jsonRes = salesforceClient->updateProduct(testProductId, updateProduct);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateProduct", "testUpdateProduct", "testGetProductById"]
}
function testDeleteProduct() {
    log:printInfo("salesforceClient -> deleteProduct()");
    json|ConnectorError jsonRes = salesforceClient->deleteProduct(testProductId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

// ============================ OPPORTUNITY SObject: get, create, update, delete ===================== //

@test:Config {}
function testCreateOpportunity() {
    log:printInfo("salesforceClient -> createOpportunity()");
    string|ConnectorError stringResponse = salesforceClient->createOpportunity(opportunity);

    if (stringResponse is string) {
        test:assertNotEquals(stringResponse, "", msg = "Found empty response!");
        log:printDebug("Opportunity id: " + stringResponse);
        testOpportunityId = <@untainted> stringResponse;
    } else {
        test:assertFail(msg = stringResponse.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateOpportunity"]
}
function testGetOpportunityById() {
    log:printInfo("salesforceClient -> getOpportunityById()");
    SObject|ConnectorError res = salesforceClient->getOpportunityById(testOpportunityId);

    if (res is SObject) {
        test:assertNotEquals(res, (), msg = "Found null JSON response!");
        test:assertEquals(res.Name, opportunity.Name, msg = "Opportunity Name mismatched!");
        test:assertEquals(res["StageName"], opportunity.StageName, msg = "Opportunity StageName mismatched!");
        test:assertEquals(res["CloseDate"], opportunity.CloseDate, msg = "Opportunity CloseDate mismatched!");
    } else {
        test:assertFail(msg = res.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateOpportunity"]
}
function testUpdateOpportunity() {
    log:printInfo("salesforceClient -> updateOpportunity()");
    json updateOpportunity = { Name: "DevServices", StageName: "30 - Proposal/Price Quote", CloseDate: "2019-01-01" };
    json|ConnectorError jsonRes = salesforceClient->updateOpportunity(testOpportunityId, updateOpportunity);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateOpportunity", "testUpdateOpportunity", "testGetOpportunityById"]
}
function testDeleteOpportunity() {
    log:printInfo("salesforceClient -> deleteOpportunity()");
    json|ConnectorError jsonRes = salesforceClient->deleteOpportunity(testOpportunityId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

//================================== Test Error ==============================================//

@test:Config {}
function testCheckUpdateRecordWithInvalidId() {
    log:printInfo("salesforceClient -> CheckUpdateRecordWithInvalidId");
    json account = { Name: "WSO2 Inc", BillingCity: "Jaffna", Phone: "+94110000000" };
    boolean|ConnectorError response = salesforceClient->updateRecord(ACCOUNT, "000", account);

    if (response is boolean) {
        test:assertFail(msg = "Invalid account ID. But successful test!");
    } else {
        test:assertNotEquals(response.detail()?.message.toString(), "", msg = "Error message found null!");
        ErrorDetail errDetail = <ErrorDetail> response.detail();
        test:assertEquals(errDetail.errorCode.toString(), "NOT_FOUND", msg =
            "Invalid account ID. But successful test!");
    }
}
