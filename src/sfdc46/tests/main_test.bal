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
    },
    secureSocketConfig: {
        trustStore: {
            path: config:getAsString("TRUSTSTORE_PATH"),
            password: config:getAsString("TRUSTSTORE_PASSWORD")
        }
    }
};

string testAccountId = "";
string testLeadId = "";
string testContactId = "";
string testOpportunityId = "";
string testProductId = "";
string testRecordId = "";
string testExternalID = "";
string testIdOfSampleOrg = "";

Client salesforceClient = new(sfConfig);

// Create salesforce bulk client.
SalesforceBulkClient sfBulkClient = salesforceClient->createSalesforceBulkClient();
// No of retries to get bulk results.
int noOfRetries = 25;

@test:Config {}
function testGetAvailableApiVersions() {
    log:printInfo("salesforceClient -> getAvailableApiVersions()");
    json|ConnectorError jsonRes = salesforceClient->getAvailableApiVersions();

    if (jsonRes is json) {
        json[] versions = <json[]>jsonRes;
        test:assertTrue(versions.length() > 0, msg = "Found 0 or No API versions");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {}
function testGetResourcesByApiVersion() {
    log:printInfo("salesforceClient -> getResourcesByApiVersion()");
    json|ConnectorError jsonRes = salesforceClient->getResourcesByApiVersion(API_VERSION);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
        test:assertNotEquals(jsonRes.sobjects, ());
        test:assertNotEquals(jsonRes.search, ());
        test:assertNotEquals(jsonRes.'query, ());
        test:assertNotEquals(jsonRes.licensing, ());
        test:assertNotEquals(jsonRes.connect, ());
        test:assertNotEquals(jsonRes.tooling, ());
        test:assertNotEquals(jsonRes.chatter, ());
        test:assertNotEquals(jsonRes.recent, ());
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {}
function testGetOrganizationLimits() {
    log:printInfo("salesforceClient -> getOrganizationLimits()");
    json|ConnectorError jsonRes = salesforceClient->getOrganizationLimits();

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
        map<json>|error jsonMap = map<json>.constructFrom(jsonRes);
        if (jsonMap is map<json>) {
            string[] keys = jsonMap.keys();     
            test:assertTrue(keys.length() > 0, msg = "Response doesn't have enough keys");
            foreach var key in keys {
                test:assertNotEquals(jsonMap[key].Max, (), msg = "Max limit not found");
                test:assertNotEquals(jsonMap[key].Remaining, (), msg = "Remaining resources not found");
            }       
        } else {
            test:assertFail(msg = "jsonRes could not convert to map<json>.");
        }
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

//============================ Basic functions================================//

@test:Config {}
function testCreateRecord() {
    log:printInfo("salesforceClient -> createRecord()");
    json accountRecord = { Name: "John Keells Holdings", BillingCity: "Colombo 3" };
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
        test:assertNotEquals(response.Name, (), msg = "Name key was missing in response");
        test:assertNotEquals(response.BillingCity, (), msg = "BillingCity key was missing in response");
    } else {
        test:assertFail(msg = response.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateRecord"]
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
    json|ConnectorError jsonRes = salesforceClient->getQueryResult(sampleQuery);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes.totalSize, ());
        test:assertNotEquals(jsonRes.'done, ());
        test:assertNotEquals(jsonRes.records, ());

        json|error nextRecordsUrl = jsonRes.nextRecordsUrl;

        while (nextRecordsUrl is json) {
            log:printDebug("Found new query result set!");
            string nextQueryUrl = jsonRes.nextRecordsUrl.toString();
            string untaintedNextQueryUrl = <@untainted> nextQueryUrl;
            json|ConnectorError resp = salesforceClient->getNextQueryResult(untaintedNextQueryUrl);

            if (resp is json) {
                test:assertNotEquals(resp.totalSize, ());
                test:assertNotEquals(resp.'done, ());
                test:assertNotEquals(resp.records, ());
                jsonRes = resp;
            } else {
                test:assertFail(msg = resp.detail()?.message.toString());
            }
        }
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testGetQueryResult"]
}
function testGetAllQueries() {
    log:printInfo("salesforceClient -> getAllQueries()");
    string sampleQuery = "SELECT Name from Account WHERE isDeleted=TRUE";
    json|ConnectorError jsonRes = salesforceClient->getAllQueries(sampleQuery);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes.totalSize, ());
        test:assertNotEquals(jsonRes.'done, ());
        test:assertNotEquals(jsonRes.records, ());
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {}
function testExplainQueryOrReportOrListview() {
    log:printInfo("salesforceClient -> explainQueryOrReportOrListview()");
    string queryString = "SELECT name FROM Account";
    json|ConnectorError jsonRes = salesforceClient->explainQueryOrReportOrListview(queryString);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

//=============================== Search ==================================//

@test:Config {}
function testSearchSOSLString() {
    log:printInfo("salesforceClient -> searchSOSLString()");
    string searchString = "FIND {ABC Inc}";
    json|ConnectorError jsonRes = salesforceClient->searchSOSLString(searchString);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

//============================ SObject Information ===============================//

@test:Config {}
function testGetSObjectBasicInfo() {
    log:printInfo("salesforceClient -> getSObjectBasicInfo()");
    json|ConnectorError jsonRes = salesforceClient->getSObjectBasicInfo("Account");

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {}
function testSObjectPlatformAction() {
    log:printInfo("salesforceClient -> sObjectPlatformAction()");
    json|ConnectorError jsonRes = salesforceClient->sObjectPlatformAction();

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {}
function testDescribeAvailableObjects() {
    log:printInfo("salesforceClient -> describeAvailableObjects()");
    json|ConnectorError jsonRes = salesforceClient->describeAvailableObjects();

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}


@test:Config {}
function testDescribeSObject() {
    log:printInfo("salesforceClient -> describeSObject()");
    json|ConnectorError jsonRes = salesforceClient->describeSObject(ACCOUNT);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

//=============================== Records Related ==================================//

@test:Config {}
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

    json|ConnectorError jsonRes = salesforceClient->getDeletedRecords("Account", startDateTime, endDateTime);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {}
function testGetUpdatedRecords() {
    log:printInfo("salesforceClient -> getUpdatedRecords()");

    time:Time now = time:currentTime();
    string|error time1 = time:format(now, "yyyy-MM-dd'T'HH:mm:ssZ");
    string endDateTime = (time1 is string) ? time1 : "";
    time:Time weekAgo = time:subtractDuration(now, 0, 0, 1, 0, 0, 0, 0);
    string|error time2 = time:format(weekAgo, "yyyy-MM-dd'T'HH:mm:ssZ");
    string startDateTime = (time2 is string) ? time2 : "";

    json|ConnectorError jsonRes = salesforceClient->getUpdatedRecords("Account", startDateTime, endDateTime);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {}
function testCreateMultipleRecords() {
    log:printInfo("salesforceClient -> createMultipleRecords()");
    json|ConnectorError response;

    json multipleRecords = { "records": [{
        "attributes": { "type": "Account", "referenceId": "ref1" },
        "name": "SampleAccount1",
        "phone": "1111111111",
        "website": "www.sfdc.com",
        "numberOfEmployees": "100",
        "industry": "Banking"
    }, {
        "attributes": { "type": "Account", "referenceId": "ref2" },
        "name": "SampleAccount2",
        "phone": "2222222222",
        "website": "www.salesforce2.com",
        "numberOfEmployees": "250",
        "industry": "Banking"
    }]
    };

    response = salesforceClient-> createMultipleRecords(<@untainted> ACCOUNT, multipleRecords);
    if (response is json) {
        test:assertEquals(response.hasErrors.toString(), "false", msg = "Found null JSON response!");
        // Delete created records.
        deleteCreatedMultipleRecords(response);
    } else {
        test:assertFail(msg = response.detail()?.message.toString());
    }
}

function deleteCreatedMultipleRecords(json res) {
    json[] resArr = <json[]>res.results;
    string sampleAcc1ID = resArr[0].id.toString();
    string sampleAcc2ID = resArr[1].id.toString();

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
    json|ConnectorError jsonRes = salesforceClient->getFieldValuesFromSObjectRecord("Account", 
        <@untainted>testRecordId, "Name,BillingCity");

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {}
function testCreateRecordWithExternalId() {
    log:printInfo("CreateRecordWithExternalId");

    string uuidString = system:uuid();
    testExternalID = uuidString.substring(0, 32);

    json accountExIdRecord = { Name: "Sample Org", BillingCity: "CA", SF_ExternalID__c: testExternalID };

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

    json|ConnectorError jsonRes = salesforceClient->getRecordByExternalId(ACCOUNT, "SF_ExternalID__c",
                                            testExternalID);
    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
        test:assertNotEquals(jsonRes.Name, (), msg = "Name key was missing in response");
        test:assertNotEquals(jsonRes.BillingCity, (), msg = "BillingCity key was missing in response");
        test:assertNotEquals(jsonRes.SF_ExternalID__c, (), msg = "SF_ExternalID__c key was missing in response");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateRecordWithExternalId"]
}
function testUpsertSObjectByExternalId() {
    log:printInfo("salesforceClient -> upsertSObjectByExternalId()");
    json upsertRecord = { Name: "Sample Org", BillingCity: "Jaffna, Colombo 3" };
    json|ConnectorError jsonRes = salesforceClient->upsertSObjectByExternalId(ACCOUNT,
                                            "SF_ExternalID__c", testExternalID, upsertRecord);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Expects true on success");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
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
    json account = { Name: "ABC Inc", BillingCity: "New York" };
    string|ConnectorError stringAccount = salesforceClient->createAccount(account);

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
    json|ConnectorError jsonRes = salesforceClient->getAccountById(testAccountId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateAccount"]
}
function testUpdateAccount() {
    log:printInfo("salesforceClient -> updateAccount()");
    json account = { Name: "ABC Inc", BillingCity: "New York-USA" };
    json|ConnectorError jsonRes = salesforceClient->updateAccount(testAccountId, account);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateAccount", "testUpdateAccount", "testGetAccountById"]
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
    json lead = { LastName: "Carmen", Company: "WSO2", City: "New York" };
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
    json|ConnectorError jsonRes = salesforceClient->getLeadById(testLeadId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
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
    json contact = { LastName: "Patson" };
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
    json|ConnectorError jsonRes = salesforceClient->getContactById(testContactId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
    }
}

@test:Config {
    dependsOn: ["testCreateContact"]
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
    json product = { Name: "APIM", Description: "APIM product" };
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
    json|ConnectorError jsonRes = salesforceClient->getProductById(testProductId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
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
    json createOpportunity = { Name: "DevServices", StageName: "30 - Proposal/Price Quote", CloseDate: "2019-01-01" };
    string|ConnectorError stringResponse = salesforceClient->createOpportunity(createOpportunity);

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
    json|ConnectorError jsonRes = salesforceClient->getOpportunityById(testOpportunityId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.detail()?.message.toString());
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
