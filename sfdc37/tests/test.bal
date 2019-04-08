import ballerina/test;
import ballerina/config;
import ballerina/log;
import ballerina/time;
import ballerina/system;
import ballerina/io;

string endpointUrl = config:getAsString("ENDPOINT");
string accessToken = config:getAsString("ACCESS_TOKEN");
string clientId = config:getAsString("CLIENT_ID");
string clientSecret = config:getAsString("CLIENT_SECRET");
string refreshToken = config:getAsString("REFRESH_TOKEN");
string refreshUrl = config:getAsString("REFRESH_URL");

string testAccountId = "";
string testLeadId = "";
string testContactId = "";
string testOpportunityId = "";
string testProductId = "";
string testRecordId = "";
string testExternalID = "";
string testIdOfSampleOrg = "";

SalesforceConfiguration salesforceConfig = {
    baseUrl: endpointUrl,
    clientConfig: {
        auth: {
            scheme: http:OAUTH2,
            config: {
                grantType: http:DIRECT_TOKEN,
                config: {
                    accessToken: accessToken,
                    refreshConfig: {
                        refreshUrl: refreshUrl,
                        refreshToken: refreshToken,
                        clientId: clientId,
                        clientSecret: clientSecret
                    }
                }
            }
        }
    }
};

Client salesforceClient = new(salesforceConfig);

@test:Config
function testGetAvailableApiVersions() {
    log:printInfo("salesforceClient -> getAvailableApiVersions()");
    json|SalesforceConnectorError jsonRes = salesforceClient->getAvailableApiVersions();

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
        json[] versions = <json[]>jsonRes;
        test:assertTrue(versions.length() > 0, msg = "Found 0 or No API versions");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config
function testGetResourcesByApiVersion() {
    log:printInfo("salesforceClient -> getResourcesByApiVersion()");
    string apiVersion = "v37.0";
    json|SalesforceConnectorError jsonRes = salesforceClient->getResourcesByApiVersion(apiVersion);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
        test:assertNotEquals(jsonRes["sobjects"], ());
        test:assertNotEquals(jsonRes["search"], ());
        test:assertNotEquals(jsonRes["query"], ());
        test:assertNotEquals(jsonRes["licensing"], ());
        test:assertNotEquals(jsonRes["connect"], ());
        test:assertNotEquals(jsonRes["tooling"], ());
        test:assertNotEquals(jsonRes["chatter"], ());
        test:assertNotEquals(jsonRes["recent"], ());
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config
function testGetOrganizationLimits() {
    log:printInfo("salesforceClient -> getOrganizationLimits()");
    json|SalesforceConnectorError jsonRes = salesforceClient->getOrganizationLimits();

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
        string[] keys = jsonRes.getKeys();
        test:assertTrue(keys.length() > 0, msg = "Response doesn't have enough keys");
        foreach var key in keys {
            test:assertNotEquals(jsonRes[key]["Max"], (), msg = "Max limit not found");
            test:assertNotEquals(jsonRes[key]["Remaining"], (), msg = "Remaining resources not found");
        }
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

//============================ Basic functions================================//

@test:Config
function testCreateRecord() {
    log:printInfo("salesforceClient -> createRecord()");
    json accountRecord = { Name: "John Keells Holdings", BillingCity: "Colombo 3" };
    string|SalesforceConnectorError stringResponse = salesforceClient->createRecord(ACCOUNT, accountRecord);

    if (stringResponse is string) {
        test:assertNotEquals(stringResponse, "", msg = "Found empty response!");
        testRecordId = untaint stringResponse;
    } else {
        test:assertFail(msg = stringResponse.message);
    }
}

@test:Config {
    dependsOn: ["testCreateRecord"]
}
function testGetRecord() {
    json|SalesforceConnectorError response;
    log:printInfo("salesforceClient -> getRecord()");
    string path = "/services/data/v37.0/sobjects/Account/" + testRecordId;
    response = salesforceClient->getRecord(path);

    if (response is json) {
        test:assertNotEquals(response, (), msg = "Found null JSON response!");
        test:assertNotEquals(response["Name"], (), msg = "Name key was missing in response");
        test:assertNotEquals(response["BillingCity"], (), msg = "BillingCity key was missing in response");
    } else {
        test:assertFail(msg = response.message);
    }
}

@test:Config {
    dependsOn: ["testCreateRecord"]

}
function testUpdateRecord() {
    log:printInfo("salesforceClient -> updateRecord()");
    json account = { Name: "WSO2 Inc", BillingCity: "Jaffna", Phone: "+94110000000" };
    boolean|SalesforceConnectorError response = salesforceClient->updateRecord(ACCOUNT, testRecordId, account);

    if (response is boolean) {
        test:assertTrue(response, msg = "Expects true on success");
    } else {
        log:printError(response == () ? "Null": "Ok");
        test:assertFail(msg = response.message);
    }
}

@test:Config {
    dependsOn: ["testCreateRecord", "testGetRecord", "testUpdateRecord",
    "testGetFieldValuesFromSObjectRecord"]
}
function testDeleteRecord() {
    log:printInfo("salesforceClient -> deleteRecord()");
    boolean|SalesforceConnectorError response = salesforceClient->deleteRecord(ACCOUNT, testRecordId);

    if (response is boolean) {
        test:assertTrue(response, msg = "Expects true on success");
    } else {
        test:assertFail(msg = response.message);
    }
}

//=============================== Query ==================================//
@test:Config
function testGetQueryResult() {
    log:printInfo("salesforceClient -> getQueryResult()");
    string sampleQuery = "SELECT name FROM Account";
    json|SalesforceConnectorError jsonRes = salesforceClient->getQueryResult(sampleQuery);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes["totalSize"], ());
        test:assertNotEquals(jsonRes["done"], ());
        test:assertNotEquals(jsonRes["records"], ());

        while (jsonRes.nextRecordsUrl != ()) {
            log:printDebug("Found new query result set!");
            string nextQueryUrl = jsonRes.nextRecordsUrl.toString();
            json|SalesforceConnectorError resp = salesforceClient->getNextQueryResult(nextQueryUrl);

            if (resp is json) {
                test:assertNotEquals(resp["totalSize"], ());
                test:assertNotEquals(resp["done"], ());
                test:assertNotEquals(resp["records"], ());
                jsonRes = resp;
            } else {
                test:assertFail(msg = resp.message);
            }
        }
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config {
    dependsOn: ["testGetQueryResult"]
}
function testGetAllQueries() {
    log:printInfo("salesforceClient -> getAllQueries()");
    string sampleQuery = "SELECT Name from Account WHERE isDeleted=TRUE";
    json|SalesforceConnectorError jsonRes = salesforceClient->getAllQueries(sampleQuery);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes["totalSize"], ());
        test:assertNotEquals(jsonRes["done"], ());
        test:assertNotEquals(jsonRes["records"], ());
        test:assertNotEquals(jsonRes["records"], ());
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config
function testExplainQueryOrReportOrListview() {
    log:printInfo("salesforceClient -> explainQueryOrReportOrListview()");
    string queryString = "SELECT name FROM Account";
    json|SalesforceConnectorError jsonRes = salesforceClient->explainQueryOrReportOrListview(queryString);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

//=============================== Search ==================================//

@test:Config
function testSearchSOSLString() {
    log:printInfo("salesforceClient -> searchSOSLString()");
    string searchString = "FIND {ABC Inc}";
    json|SalesforceConnectorError jsonRes = salesforceClient->searchSOSLString(searchString);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

//============================ SObject Information ===============================//

@test:Config
function testGetSObjectBasicInfo() {
    log:printInfo("salesforceClient -> getSObjectBasicInfo()");
    json|SalesforceConnectorError jsonRes = salesforceClient->getSObjectBasicInfo("Account");

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config
function testSObjectPlatformAction() {
    log:printInfo("salesforceClient -> sObjectPlatformAction()");
    json|SalesforceConnectorError jsonRes = salesforceClient->sObjectPlatformAction();

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config
function testDescribeAvailableObjects() {
    log:printInfo("salesforceClient -> describeAvailableObjects()");
    json|SalesforceConnectorError jsonRes = salesforceClient->describeAvailableObjects();

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}


@test:Config
function testDescribeSObject() {
    log:printInfo("salesforceClient -> describeSObject()");
    json|SalesforceConnectorError jsonRes = salesforceClient->describeSObject(ACCOUNT);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

//=============================== Records Related ==================================//

@test:Config
function testGetDeletedRecords() {
    log:printInfo("salesforceClient -> getDeletedRecords()");

    time:Time now = time:currentTime();
    string|error time1 = time:format(now, "yyyy-MM-dd'T'HH:mm:ssZ");
    string endDateTime = (time1 is string) ? time1 : "";
    time:Time weekAgo = time:subtractDuration(now, 0, 0, 1, 0, 0, 0, 0);
    string|error time2 = time:format(weekAgo, "yyyy-MM-dd'T'HH:mm:ssZ");
    string startDateTime = (time2 is string) ? time2 : "";

    json|SalesforceConnectorError jsonRes = salesforceClient->getDeletedRecords("Account", startDateTime, endDateTime);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config
function testGetUpdatedRecords() {
    log:printInfo("salesforceClient -> getUpdatedRecords()");

    time:Time now = time:currentTime();
    string|error time1 = time:format(now, "yyyy-MM-dd'T'HH:mm:ssZ");
    string endDateTime = (time1 is string) ? time1 : "";
    time:Time weekAgo = time:subtractDuration(now, 0, 0, 1, 0, 0, 0, 0);
    string|error time2 = time:format(weekAgo, "yyyy-MM-dd'T'HH:mm:ssZ");
    string startDateTime = (time2 is string) ? time2 : "";

    json|SalesforceConnectorError jsonRes = salesforceClient->getUpdatedRecords("Account", startDateTime, endDateTime);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config
function testCreateMultipleRecords() {
    log:printInfo("salesforceClient -> createMultipleRecords()");
    json|SalesforceConnectorError response;

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

    response = salesforceClient-> createMultipleRecords(ACCOUNT, multipleRecords);
    if (response is json) {
        test:assertEquals(response.hasErrors.toString(), "false", msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = response.message);
    }
}

@test:Config {
    dependsOn: ["testCreateRecord"]
}
function testGetFieldValuesFromSObjectRecord() {
    log:printInfo("salesforceClient -> getFieldValuesFromSObjectRecord()");
    json|SalesforceConnectorError jsonRes = salesforceClient->getFieldValuesFromSObjectRecord("Account", testRecordId,
                                            "Name,BillingCity");

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config
function testCreateRecordWithExternalId() {
    log:printInfo("CreateRecordWithExternalId");

    string uuidString = system:uuid();
    testExternalID = uuidString.substring(0, 32);

    json accountExIdRecord = { Name: "Sample Org", BillingCity: "CA", SF_ExternalID__c: testExternalID };

    string|SalesforceConnectorError stringResponse = salesforceClient->createRecord(ACCOUNT, accountExIdRecord);

    if (stringResponse is string) {
        test:assertNotEquals(stringResponse, "", msg = "Found empty response!");
        testIdOfSampleOrg = untaint stringResponse;
    } else {
        test:assertFail(msg = stringResponse.message);
    }
}

@test:Config {
    dependsOn: ["testCreateRecordWithExternalId"]
}
function testGetRecordByExternalId() {
    log:printInfo("salesforceClient -> getRecordByExternalId()");

    json|SalesforceConnectorError jsonRes = salesforceClient->getRecordByExternalId(ACCOUNT, "SF_ExternalID__c",
                                            testExternalID);
    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
        test:assertNotEquals(jsonRes["Name"], (), msg = "Name key was missing in response");
        test:assertNotEquals(jsonRes["BillingCity"], (), msg = "BillingCity key was missing in response");
        test:assertNotEquals(jsonRes["SF_ExternalID__c"], (), msg = "SF_ExternalID__c key was missing in response");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config {
    dependsOn: ["testCreateRecordWithExternalId"]
}
function testUpsertSObjectByExternalId() {
    log:printInfo("salesforceClient -> upsertSObjectByExternalId()");
    json upsertRecord = { Name: "Sample Org", BillingCity: "Jaffna, Colombo 3" };
    json|SalesforceConnectorError jsonRes = salesforceClient->upsertSObjectByExternalId(ACCOUNT,
                                            "SF_ExternalID__c", testExternalID, upsertRecord);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Expects true on success");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}


@test:Config {
    dependsOn: ["testCreateRecordWithExternalId", "testUpsertSObjectByExternalId", "testGetRecordByExternalId"]
}
function testDeleteRecordWithExternalId() {
    log:printInfo("salesforceClient -> DeleteRecordWithExternalID");
    boolean|SalesforceConnectorError response = salesforceClient->deleteRecord(ACCOUNT, testIdOfSampleOrg);

    if (response is boolean) {
        test:assertTrue(response, msg = "Expects true on success");
    } else {
        test:assertFail(msg = response.message);
    }
}

// ============================ ACCOUNT SObject: get, create, update, delete ===================== //

@test:Config
function testCreateAccount() {
    log:printInfo("salesforceClient -> createAccount()");
    json account = { Name: "ABC Inc", BillingCity: "New York" };
    string|SalesforceConnectorError stringAccount = salesforceClient->createAccount(account);

    if (stringAccount is string) {
        test:assertNotEquals(stringAccount, "", msg = "Found empty response!");
        log:printDebug("Account id: " + stringAccount);
        testAccountId = stringAccount;
    } else {
        test:assertFail(msg = stringAccount.message);
    }
}

@test:Config {
    dependsOn: ["testCreateAccount"]
}
function testGetAccountById() {
    log:printInfo("salesforceClient -> getAccountById()");
    json|SalesforceConnectorError jsonRes = salesforceClient->getAccountById(testAccountId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config {
    dependsOn: ["testCreateAccount"]
}
function testUpdateAccount() {
    log:printInfo("salesforceClient -> updateAccount()");
    json account = { Name: "ABC Inc", BillingCity: "New York-USA" };
    json|SalesforceConnectorError jsonRes = salesforceClient->updateAccount(testAccountId, account);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config {
    dependsOn: ["testCreateAccount", "testUpdateAccount", "testGetAccountById"]
}
function testDeleteAccount() {
    log:printInfo("salesforceClient -> deleteAccount()");
    json|SalesforceConnectorError jsonRes = salesforceClient->deleteAccount(testAccountId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

// ============================ LEAD SObject: get, create, update, delete ===================== //

@test:Config
function testCreateLead() {
    log:printInfo("salesforceClient -> createLead()");
    json lead = { LastName: "Carmen", Company: "WSO2", City: "New York" };
    string|SalesforceConnectorError stringLead = salesforceClient->createLead(lead);

    if (stringLead is string) {
        test:assertNotEquals(stringLead, "", msg = "Found empty response!");
        log:printDebug("Lead id: " + stringLead);
        testLeadId = stringLead;
    } else {
        test:assertFail(msg = stringLead.message);
    }
}

@test:Config {
    dependsOn: ["testCreateLead"]
}
function testGetLeadById() {
    log:printInfo("salesforceClient -> getLeadById()");
    json|SalesforceConnectorError jsonRes = salesforceClient->getLeadById(testLeadId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config {
    dependsOn: ["testCreateLead"]
}
function testUpdateLead() {
    log:printInfo("salesforceClient -> updateLead()");
    json updateLead = { LastName: "Carmen", Company: "WSO2 Lanka (Pvt) Ltd" };
    json|SalesforceConnectorError jsonRes = salesforceClient->updateLead(testLeadId, updateLead);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config {
    dependsOn: ["testCreateLead", "testUpdateLead", "testGetLeadById"]
}
function testDeleteLead() {
    log:printInfo("salesforceClient -> deleteLead()");
    json|SalesforceConnectorError jsonRes = salesforceClient->deleteLead(testLeadId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

// ============================ CONTACTS SObject: get, create, update, delete ===================== //

@test:Config
function testCreateContact() {
    log:printInfo("salesforceClient -> createContact()");
    json contact = { LastName: "Patson" };
    string|SalesforceConnectorError stringContact = salesforceClient->createContact(contact);

    if (stringContact is string) {
        test:assertNotEquals(stringContact, "", msg = "Found empty response!");
        log:printDebug("Contact id: " + stringContact);
        testContactId = stringContact;
    } else {
        test:assertFail(msg = stringContact.message);
    }
}

@test:Config {
    dependsOn: ["testCreateContact"]
}
function testGetContactById() {
    log:printInfo("salesforceClient -> getContactById()");
    json|SalesforceConnectorError jsonRes = salesforceClient->getContactById(testContactId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config {
    dependsOn: ["testCreateContact"]
}
function testUpdateContact() {
    log:printInfo("salesforceClient -> updateContact()");
    json updateContact = { LastName: "Rebert Patson" };
    json|SalesforceConnectorError jsonRes = salesforceClient->updateContact(testContactId, updateContact);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config {
    dependsOn: ["testCreateContact", "testUpdateContact", "testGetContactById"]
}
function testDeleteContact() {
    log:printInfo("salesforceClient -> deleteContact()");
    json|SalesforceConnectorError jsonRes = salesforceClient->deleteContact(testContactId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

// ============================ PRODUCTS SObject: get, create, update, delete ===================== //

@test:Config
function testCreateProduct() {
    log:printInfo("salesforceClient -> createProduct()");
    json product = { Name: "APIM", Description: "APIM product" };
    string|SalesforceConnectorError stringProduct = salesforceClient->createProduct(product);

    if (stringProduct is string) {
        test:assertNotEquals(stringProduct, "", msg = "Found empty response!");
        log:printDebug("Product id: " + stringProduct);
        testProductId = stringProduct;
    } else {
        test:assertFail(msg = stringProduct.message);
    }
}

@test:Config {
    dependsOn: ["testCreateProduct"]
}
function testGetProductById() {
    log:printInfo("salesforceClient -> getProductById()");
    json|SalesforceConnectorError jsonRes = salesforceClient->getProductById(testProductId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config {
    dependsOn: ["testCreateProduct"]
}
function testUpdateProduct() {
    log:printInfo("salesforceClient -> updateProduct()");
    json updateProduct = { Name: "APIM", Description: "APIM new product" };
    json|SalesforceConnectorError jsonRes = salesforceClient->updateProduct(testProductId, updateProduct);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config {
    dependsOn: ["testCreateProduct", "testUpdateProduct", "testGetProductById"]
}
function testDeleteProduct() {
    log:printInfo("salesforceClient -> deleteProduct()");
    json|SalesforceConnectorError jsonRes = salesforceClient->deleteProduct(testProductId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

// ============================ OPPORTUNITY SObject: get, create, update, delete ===================== //

@test:Config
function testCreateOpportunity() {
    log:printInfo("salesforceClient -> createOpportunity()");
    json createOpportunity = { Name: "DevServices", StageName: "30 - Proposal/Price Quote", CloseDate: "2019-01-01" };
    string|SalesforceConnectorError stringResponse = salesforceClient->createOpportunity(createOpportunity);
    io:println("stringResponse: ", stringResponse);
    if (stringResponse is string) {
        test:assertNotEquals(stringResponse, "", msg = "Found empty response!");
        log:printDebug("Opportunity id: " + stringResponse);
        testOpportunityId = stringResponse;
    } else {
        test:assertFail(msg = stringResponse.message);
    }
}

@test:Config {
    dependsOn: ["testCreateOpportunity"]
}
function testGetOpportunityById() {
    log:printInfo("salesforceClient -> getOpportunityById()");
    json|SalesforceConnectorError jsonRes = salesforceClient->getOpportunityById(testOpportunityId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Found null JSON response!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config {
    dependsOn: ["testCreateOpportunity"]
}
function testUpdateOpportunity() {
    log:printInfo("salesforceClient -> updateOpportunity()");
    json updateOpportunity = { Name: "DevServices", StageName: "30 - Proposal/Price Quote", CloseDate: "2019-01-01" };
    json|SalesforceConnectorError jsonRes = salesforceClient->updateOpportunity(testOpportunityId, updateOpportunity);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

@test:Config {
    dependsOn: ["testCreateOpportunity", "testUpdateOpportunity", "testGetOpportunityById"]
}
function testDeleteOpportunity() {
    log:printInfo("salesforceClient -> deleteOpportunity()");
    json|SalesforceConnectorError jsonRes = salesforceClient->deleteOpportunity(testOpportunityId);

    if (jsonRes is json) {
        test:assertNotEquals(jsonRes, (), msg = "Failed!");
    } else {
        test:assertFail(msg = jsonRes.message);
    }
}

//================================== Test Error ==============================================//

@test:Config
function testCheckUpdateRecordWithInvalidId() {
    log:printInfo("salesforceClient -> CheckUpdateRecordWithInvalidId");
    json account = { Name: "WSO2 Inc", BillingCity: "Jaffna", Phone: "+94110000000" };
    boolean|SalesforceConnectorError response = salesforceClient->updateRecord(ACCOUNT, "000", account);

    if (response is boolean) {
        test:assertFail(msg = "Invalid account ID. But successful test!");
    } else {
        test:assertNotEquals(response.message, "", msg = "Error message found null!");
        test:assertEquals(response.salesforceErrors[0].errorCode, "NOT_FOUND", msg =
        "Invalid account ID. But successful test!");
    }
}