import ballerina/test;
import ballerina/config;
import ballerina/log;
import ballerina/time;
import ballerina/system;

string url = config:getAsString("ENDPOINT");
string accessToken = config:getAsString("ACCESS_TOKEN");
string clientId = config:getAsString("CLIENT_ID");
string clientSecret = config:getAsString("CLIENT_SECRET");
string refreshToken = config:getAsString("REFRESH_TOKEN");
string refreshUrl = config:getAsString("REFRESH_URL");

json|SalesforceConnectorError response;
string accountId = "";
string leadId = "";
string contactId = "";
string opportunityId = "";
string productId = "";
string recordId = "";
string externalID = "";
string idOfSampleOrg = "";

endpoint Client salesforceClient {
    clientConfig:{
        url:url,
        auth:{
            scheme:"oauth",
            accessToken:accessToken,
            refreshToken:refreshToken,
            clientId:clientId,
            clientSecret:clientSecret,
            refreshUrl:refreshUrl
        }
    }
};

@test:Config
function testGetAvailableApiVersions() {
    log:printInfo("salesforceClient -> getAvailableApiVersions()");
    response = salesforceClient -> getAvailableApiVersions();
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
            try {
                var res = < json[]>jsonRes;
                json[] versions = check res;
                test:assertTrue(lengthof versions > 0, msg = "Found 0 or No API versions");
            } catch (error err){
                test:assertFail(msg = err.message);
            }
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config
function testGetResourcesByApiVersion() {
    log:printInfo("salesforceClient -> getResourcesByApiVersion()");
    string apiVersion = "v37.0";
    response = salesforceClient -> getResourcesByApiVersion(apiVersion);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
            try {
                test:assertNotEquals(jsonRes["sobjects"], null);
                test:assertNotEquals(jsonRes["search"], null);
                test:assertNotEquals(jsonRes["query"], null);
                test:assertNotEquals(jsonRes["licensing"], null);
                test:assertNotEquals(jsonRes["connect"], null);
                test:assertNotEquals(jsonRes["tooling"], null);
                test:assertNotEquals(jsonRes["chatter"], null);
                test:assertNotEquals(jsonRes["recent"], null);
            } catch (error e) {
                test:assertFail(msg = "Response doesn't have required keys");
            }
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config
function testGetOrganizationLimits() {
    log:printInfo("salesforceClient -> getOrganizationLimits()");
    response = salesforceClient -> getOrganizationLimits();
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
            string[] keys = jsonRes.getKeys();
            test:assertTrue(lengthof keys > 0, msg = "Response doesn't have enough keys");
            foreach key in jsonRes {
                try {
                    test:assertNotEquals(key["Max"], null, msg = "Max limit not found");
                    test:assertNotEquals(key["Remaining"], null, msg = "Remaining resources not found");
                } catch (error e) {
                    test:assertFail(msg = "Response is invalid");
                }
            }
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

//============================ Basic functions================================//

@test:Config
function testCreateRecord() {
    log:printInfo("salesforceClient -> createRecord()");
    json accountRecord = {Name:"John Keells Holdings", BillingCity:"Colombo 3"};
    string|SalesforceConnectorError stringResponse = salesforceClient -> createRecord(ACCOUNT, accountRecord);
    match stringResponse {
        string createdRecordId => {
            test:assertNotEquals(createdRecordId, "", msg = "Found empty response!");
            recordId = createdRecordId;
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateRecord"]
}
function testGetRecord() {
    log:printInfo("salesforceClient -> getRecord()");
    string path = "/services/data/v37.0/sobjects/Account/" + recordId;
    response = salesforceClient -> getRecord(path);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
            try {
                test:assertNotEquals(jsonRes["Name"], null, msg = "Found null JSON response!");
                test:assertNotEquals(jsonRes["BillingCity"], null, msg = "Found null JSON response!");
            } catch (error e) {
                test:assertFail(msg = "A required key was missing in response");
            }
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateRecord"]

}
function testUpdateRecord() {
    log:printInfo("salesforceClient -> updateRecord()");
    json account = {Name:"WSO2 Inc", BillingCity:"Jaffna", Phone:"+94110000000"};
    boolean|SalesforceConnectorError response = salesforceClient -> updateRecord(ACCOUNT, recordId, account);
    match response {
        boolean success => {
            test:assertTrue(success, msg = "Expects true on success");
        }
        SalesforceConnectorError err => {
            log:printError(err == null ? "Null": "Ok");
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateRecord", "testGetRecord", "testUpdateRecord",
    "testGetFieldValuesFromSObjectRecord"]
}
function testDeleteRecord() {
    log:printInfo("salesforceClient -> deleteRecord()");
    boolean|SalesforceConnectorError response = salesforceClient -> deleteRecord(ACCOUNT, recordId);
    match response {
        boolean success => {
            test:assertTrue(success, msg = "Expects true on success");
        }
        SalesforceConnectorError err => {
        }
    }
}

//=============================== Query ==================================//
@test:Config
function testGetQueryResult() {
    log:printInfo("salesforceClient -> getQueryResult()");
    string sampleQuery = "SELECT name FROM Account";
    response = salesforceClient -> getQueryResult(sampleQuery);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes["totalSize"], null);
            test:assertNotEquals(jsonRes["done"], null);
            test:assertNotEquals(jsonRes["records"], null);

            while (jsonRes.nextRecordsUrl != null) {
                log:printDebug("Found new query result set!");
                string nextQueryUrl = jsonRes.nextRecordsUrl.toString();
                response = salesforceClient -> getNextQueryResult(nextQueryUrl);

                match response {
                    json jsonNextRes => {
                        test:assertNotEquals(jsonNextRes["totalSize"], null);
                        test:assertNotEquals(jsonNextRes["done"], null);
                        test:assertNotEquals(jsonNextRes["records"], null);
                        jsonRes = jsonNextRes;
                    }
                    SalesforceConnectorError err => {
                        test:assertFail(msg = err.message);
                    }
                }
            }
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testGetQueryResult"]
}
function testGetAllQueries() {
    log:printInfo("salesforceClient -> getAllQueries()");
    string sampleQuery = "SELECT Name from Account WHERE isDeleted=TRUE";
    response = salesforceClient -> getAllQueries(sampleQuery);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes["totalSize"], null);
            test:assertNotEquals(jsonRes["done"], null);
            test:assertNotEquals(jsonRes["records"], null);
            test:assertNotEquals(jsonRes["records"], null);
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config
function testExplainQueryOrReportOrListview() {
    log:printInfo("salesforceClient -> explainQueryOrReportOrListview()");
    string queryString = "SELECT name FROM Account";
    response = salesforceClient -> explainQueryOrReportOrListview(queryString);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

//=============================== Search ==================================//

@test:Config
function testSearchSOSLString() {
    log:printInfo("salesforceClient -> searchSOSLString()");
    string searchString = "FIND {ABC Inc}";
    response = salesforceClient -> searchSOSLString(searchString);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

//============================ SObject Information ===============================//

@test:Config
function testGetSObjectBasicInfo() {
    log:printInfo("salesforceClient -> getSObjectBasicInfo()");
    response = salesforceClient -> getSObjectBasicInfo("Account");
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config
function testSObjectPlatformAction() {
    log:printInfo("salesforceClient -> sObjectPlatformAction()");
    response = salesforceClient -> sObjectPlatformAction();
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config
function testDescribeAvailableObjects() {
    log:printInfo("salesforceClient -> describeAvailableObjects()");
    response = salesforceClient -> describeAvailableObjects();
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}


@test:Config
function testDescribeSObject() {
    log:printInfo("salesforceClient -> describeSObject()");
    response = salesforceClient -> describeSObject(ACCOUNT);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

//=============================== Records Related ==================================//

@test:Config
function testGetDeletedRecords() {
    log:printInfo("salesforceClient -> getDeletedRecords()");

    time:Time now = time:currentTime();
    string endDateTime = now.format("yyyy-MM-dd'T'HH:mm:ssZ");
    time:Time weekAgo = now.subtractDuration(0, 0, 1, 0, 0, 0, 0);
    string startDateTime = weekAgo.format("yyyy-MM-dd'T'HH:mm:ssZ");

    response = salesforceClient -> getDeletedRecords("Account", startDateTime, endDateTime);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config
function testGetUpdatedRecords() {
    log:printInfo("salesforceClient -> getUpdatedRecords()");

    time:Time now = time:currentTime();
    string endDateTime = now.format("yyyy-MM-dd'T'HH:mm:ssZ");
    time:Time weekAgo = now.subtractDuration(0, 0, 1, 0, 0, 0, 0);
    string startDateTime = weekAgo.format("yyyy-MM-dd'T'HH:mm:ssZ");

    response = salesforceClient -> getUpdatedRecords("Account", startDateTime, endDateTime);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config
function testCreateMultipleRecords() {
    log:printInfo("salesforceClient -> createMultipleRecords()");

    json multipleRecords = {"records":[{
        "attributes":{"type":"Account", "referenceId":"ref1"},
        "name":"SampleAccount1",
        "phone":"1111111111",
        "website":"www.sfdc.com",
        "numberOfEmployees":"100",
        "industry":"Banking"
    }, {
        "attributes":{"type":"Account", "referenceId":"ref2"},
        "name":"SampleAccount2",
        "phone":"2222222222",
        "website":"www.salesforce2.com",
        "numberOfEmployees":"250",
        "industry":"Banking"
    }]
    };

    response = salesforceClient -> createMultipleRecords(ACCOUNT, multipleRecords);
    match response {
        json jsonRes => {
            test:assertEquals(jsonRes.hasErrors.toString(), "false", msg = "Found null JSON response!");
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateRecord"]
}
function testGetFieldValuesFromSObjectRecord() {
    log:printInfo("salesforceClient -> getFieldValuesFromSObjectRecord()");
    response = salesforceClient -> getFieldValuesFromSObjectRecord("Account", recordId, "Name,BillingCity");
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config
function testCreateRecordWithExternalId() {
    log:printInfo("CreateRecordWithExternalId");

    string uuidString = system:uuid();
    externalID = uuidString.substring(0,32);

    json accountExIdRecord = {Name:"Sample Org", BillingCity:"CA", SF_ExternalID__c:externalID};

    string|SalesforceConnectorError stringResponse = salesforceClient -> createRecord(ACCOUNT, accountExIdRecord);
    match stringResponse {
        string createdExternalId => {
            test:assertNotEquals(createdExternalId, "", msg = "Found empty response!");
            idOfSampleOrg = createdExternalId;
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateRecordWithExternalId"]
}
function testGetRecordByExternalId() {
    log:printInfo("salesforceClient -> getRecordByExternalId()");

    response = salesforceClient -> getRecordByExternalId(ACCOUNT, "SF_ExternalID__c", externalID);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
            try {
                test:assertNotEquals(jsonRes["Name"], null, msg = "Found null JSON response!");
                test:assertNotEquals(jsonRes["BillingCity"], null, msg = "Found null JSON response!");
                test:assertNotEquals(jsonRes["SF_ExternalID__c"], null, msg = "Found null JSON response!");
            } catch (error e) {
                test:assertFail(msg = "A required key was missing in response");
            }
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateRecordWithExternalId"]
}
function testUpsertSObjectByExternalId() {
    log:printInfo("salesforceClient -> upsertSObjectByExternalId()");
    json upsertRecord = {Name:"Sample Org", BillingCity:"Jaffna, Colombo 3"};
    json|SalesforceConnectorError response = salesforceClient -> upsertSObjectByExternalId(ACCOUNT,
        "SF_ExternalID__c",
        externalID, upsertRecord);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Expects true on success");
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}


@test:Config {
    dependsOn:["testCreateRecordWithExternalId", "testUpsertSObjectByExternalId", "testGetRecordByExternalId"]
}
function testDeleteRecordWithExternalId() {
    log:printInfo("salesforceClient -> DeleteRecordWithExternalID");
    boolean|SalesforceConnectorError response = salesforceClient -> deleteRecord(ACCOUNT, idOfSampleOrg);
    match response {
        boolean success => {
            test:assertTrue(success, msg = "Expects true on success");
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

// ============================ ACCOUNT SObject: get, create, update, delete ===================== //

@test:Config
function testCreateAccount() {
    log:printInfo("salesforceClient -> createAccount()");
    json account = {Name:"ABC Inc", BillingCity:"New York"};
    string|SalesforceConnectorError stringAccount = salesforceClient -> createAccount(account);
    match stringAccount {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            log:printDebug("Account id: " + id);
            accountId = id;
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateAccount"]
}
function testGetAccountById() {
    log:printInfo("salesforceClient -> getAccountById()");
    response = salesforceClient -> getAccountById(accountId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateAccount"]
}
function testUpdateAccount() {
    log:printInfo("salesforceClient -> updateAccount()");
    json account = {Name:"ABC Inc", BillingCity:"New York-USA"};
    response = salesforceClient -> updateAccount(accountId, account);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateAccount", "testUpdateAccount", "testGetAccountById"]
}
function testDeleteAccount() {
    log:printInfo("salesforceClient -> deleteAccount()");
    response = salesforceClient -> deleteAccount(accountId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

// ============================ LEAD SObject: get, create, update, delete ===================== //

@test:Config
function testCreateLead() {
    log:printInfo("salesforceClient -> createLead()");
    json lead = {LastName:"Carmen", Company:"WSO2", City:"New York"};
    string|SalesforceConnectorError stringLead = salesforceClient -> createLead(lead);
    match stringLead {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            log:printDebug("Lead id: " + id);
            leadId = id;
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateLead"]
}
function testGetLeadById() {
    log:printInfo("salesforceClient -> getLeadById()");
    response = salesforceClient -> getLeadById(leadId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateLead"]
}
function testUpdateLead() {
    log:printInfo("salesforceClient -> updateLead()");
    json updateLead = {LastName:"Carmen", Company:"WSO2 Lanka (Pvt) Ltd"};
    response = salesforceClient -> updateLead(leadId, updateLead);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateLead", "testUpdateLead", "testGetLeadById"]
}
function testDeleteLead() {
    log:printInfo("salesforceClient -> deleteLead()");
    response = salesforceClient -> deleteLead(leadId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

// ============================ CONTACTS SObject: get, create, update, delete ===================== //

@test:Config
function testCreateContact() {
    log:printInfo("salesforceClient -> createContact()");
    json contact = {LastName:"Patson"};
    string|SalesforceConnectorError stringContact = salesforceClient -> createContact(contact);
    match stringContact {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            log:printDebug("Contact id: " + id);
            contactId = id;
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateContact"]
}
function testGetContactById() {
    log:printInfo("salesforceClient -> getContactById()");
    response = salesforceClient -> getContactById(contactId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateContact"]
}
function testUpdateContact() {
    log:printInfo("salesforceClient -> updateContact()");
    json updateContact = {LastName:"Rebert Patson"};
    response = salesforceClient -> updateContact(contactId, updateContact);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateContact", "testUpdateContact", "testGetContactById"]
}
function testDeleteContact() {
    log:printInfo("salesforceClient -> deleteContact()");
    response = salesforceClient -> deleteContact(contactId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

// ============================ PRODUCTS SObject: get, create, update, delete ===================== //

@test:Config
function testCreateProduct() {
    log:printInfo("salesforceClient -> createProduct()");
    json product = {Name:"APIM", Description:"APIM product"};
    string|SalesforceConnectorError stringProduct = salesforceClient -> createProduct(product);
    match stringProduct {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            log:printDebug("Product id: " + id);
            productId = id;
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateProduct"]
}
function testGetProductById() {
    log:printInfo("salesforceClient -> getProductById()");
    response = salesforceClient -> getProductById(productId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateProduct"]
}
function testUpdateProduct() {
    log:printInfo("salesforceClient -> updateProduct()");
    json updateProduct = {Name:"APIM", Description:"APIM new product"};
    response = salesforceClient -> updateProduct(productId, updateProduct);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateProduct", "testUpdateProduct", "testGetProductById"]
}
function testDeleteProduct() {
    log:printInfo("salesforceClient -> deleteProduct()");
    response = salesforceClient -> deleteProduct(productId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

// ============================ OPPORTUNITY SObject: get, create, update, delete ===================== //

@test:Config
function testCreateOpportunity() {
    log:printInfo("salesforceClient -> createOpportunity()");
    json createOpportunity = {Name:"DevServices", StageName:"30 - Proposal/Price Quote", CloseDate:"2019-01-01"};
    string|SalesforceConnectorError stringResponse = salesforceClient -> createOpportunity(createOpportunity);
    match stringResponse {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            log:printDebug("Opportunity id: " + id);
            opportunityId = id;
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateOpportunity"]
}
function testGetOpportunityById() {
    log:printInfo("salesforceClient -> getOpportunityById()");
    response = salesforceClient -> getOpportunityById(opportunityId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateOpportunity"]
}
function testUpdateOpportunity() {
    log:printInfo("salesforceClient -> updateOpportunity()");
    json updateOpportunity = {Name:"DevServices", StageName:"30 - Proposal/Price Quote", CloseDate:"2019-01-01"};
    response = salesforceClient -> updateOpportunity(opportunityId, updateOpportunity);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

@test:Config {
    dependsOn:["testCreateOpportunity", "testUpdateOpportunity", "testGetOpportunityById"]
}
function testDeleteOpportunity() {
    log:printInfo("salesforceClient -> deleteOpportunity()");
    response = salesforceClient -> deleteOpportunity(opportunityId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.message);
        }
    }
}

//================================== Test Error ==============================================//

@test:Config
function testCheckUpdateRecordWithInvalidId() {
    log:printInfo("salesforceClient -> CheckUpdateRecordWithInvalidId");
    json account = {Name:"WSO2 Inc", BillingCity:"Jaffna", Phone:"+94110000000"};
    boolean|SalesforceConnectorError response = salesforceClient -> updateRecord(ACCOUNT, "000", account);
    match response {
        boolean success => {
            test:assertFail(msg = "Invalid account ID. But successful test!");
        }
        SalesforceConnectorError err => {
            test:assertNotEquals(err.message, "", msg = "Error message found null!");
            test:assertEquals(err.salesforceErrors[0].errorCode, "NOT_FOUND", msg = "Invalid account ID. But successful test!");
        }
    }
}