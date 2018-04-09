import ballerina/test;
import ballerina/config;
import ballerina/log;
import ballerina/time;
import ballerina/util;

string url = setConfParams(config:getAsString("ENDPOINT"));
string accessToken = setConfParams(config:getAsString("ACCESS_TOKEN"));
string clientId = setConfParams(config:getAsString("CLIENT_ID"));
string clientSecret = setConfParams(config:getAsString("CLIENT_SECRET"));
string refreshToken = setConfParams(config:getAsString("REFRESH_TOKEN"));
string refreshTokenEndpoint = setConfParams(config:getAsString("REFRESH_TOKEN_ENDPOINT"));
string refreshTokenPath = setConfParams(config:getAsString("REFRESH_TOKEN_PATH"));

json|SalesforceConnectorError response;
string accountId = "";
string leadId = "";
string contactId = "";
string opportunityId = "";
string productId = "";
string recordId = "";
string externalID = "";

endpoint SalesforceEndpoint salesforceEP {
    oauth2Config:{
                     accessToken:accessToken,
                     baseUrl:url,
                     clientId:clientId,
                     clientSecret:clientSecret,
                     refreshToken:refreshToken,
                     refreshTokenEP:refreshTokenEndpoint,
                     refreshTokenPath:refreshTokenPath,
                     clientConfig:{}
                 }
};

@test:Config
function testGetAvailableApiVersions () {
    log:printInfo("salesforceEP -> getAvailableApiVersions()");
    response = salesforceEP -> getAvailableApiVersions();
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
            //json[] versions = <json[]>jsonRes;
            //test:assertTrue(lengthof versions > 0, msg = "Found 0 or No API versions");
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testGetResourcesByApiVersion () {
    log:printInfo("salesforceEP -> getResourcesByApiVersion()");
    string apiVersion = "v37.0";
    response = salesforceEP -> getResourcesByApiVersion(apiVersion);
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
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testGetOrganizationLimits () {
    log:printInfo("salesforceEP -> getOrganizationLimits()");
    response = salesforceEP -> getOrganizationLimits();
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
            //test:assertTrue(lengthof jsonRes.getKeys() > 0, msg = "Response doesn't have enough keys");
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
            test:assertFail(msg = err.messages[0]);
        }
    }
}

//============================ Basic functions================================//

@test:Config
function testCreateRecord () {
    log:printInfo("salesforceEP -> createRecord()");
    json accountRecord = {Name:"John Keells Holdings", BillingCity:"Colombo 3"};
    string|SalesforceConnectorError stringResponse = salesforceEP -> createRecord(ACCOUNT, accountRecord);
    match stringResponse {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            recordId = id;
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateRecord"]
}
function testGetRecord () {
    log:printInfo("salesforceEP -> getRecord()");
    string path = "/services/data/v37.0/sobjects/Account/" + recordId;
    response = salesforceEP -> getRecord(path);
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
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateRecord"]

}
function testUpdateRecord () {
    log:printInfo("salesforceEP -> updateRecord()");
    json account = {Name:"WSO2 Inc", BillingCity:"Jaffna", Phone:"+94110000000"};
    boolean|SalesforceConnectorError response = salesforceEP -> updateRecord(ACCOUNT, recordId, account);
    match response {
        boolean success => {
            test:assertTrue(success, msg = "Expects true on success");
        }
        SalesforceConnectorError err => {
            log:printError(err==null ? "Null": "Ok");
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateRecord", "testGetRecord", "testUpdateRecord",
               "testGetFieldValuesFromSObjectRecord"]
}
function testDeleteRecord () {
    log:printInfo("salesforceEP -> deleteRecord()");
    boolean|SalesforceConnectorError response = salesforceEP -> deleteRecord("Account", recordId);
    match response {
        boolean success => {
            test:assertTrue(success, msg = "Expects true on success");
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

//=============================== Query ==================================//

@test:Config
function testGetQueryResult () {
    log:printInfo("salesforceEP -> getQueryResult()");
    string sampleQuery = "SELECT name FROM Account";
    response = salesforceEP -> getQueryResult(sampleQuery);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes["totalSize"], null);
            test:assertNotEquals(jsonRes["done"], null);
            test:assertNotEquals(jsonRes["records"], null);

            if (jsonRes.nextRecordsUrl != null) {
                log:printInfo("salesforceEP -> getNextQueryResult()");

                while (jsonRes.nextRecordsUrl != null) {
                    log:printDebug("Found new query result set!");
                    string nextQueryUrl = jsonRes.nextRecordsUrl.toString()?:"";
                    response = salesforceEP -> getNextQueryResult(nextQueryUrl);
                    match response {
                        json jsonNextRes => {
                            test:assertNotEquals(jsonNextRes["totalSize"], null);
                            test:assertNotEquals(jsonNextRes["done"], null);
                            test:assertNotEquals(jsonNextRes["records"], null);

                            jsonRes = jsonNextRes;
                        }
                        SalesforceConnectorError err => {
                            test:assertFail(msg = err.messages[0]);
                        }
                    }
                }
            }
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testGetQueryResult"]
}
function testGetAllQueries () {
    log:printInfo("salesforceEP -> getAllQueries()");
    string sampleQuery = "SELECT Name from Account WHERE isDeleted=TRUE";
    response = salesforceEP -> getAllQueries(sampleQuery);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes["totalSize"], null);
            test:assertNotEquals(jsonRes["done"], null);
            test:assertNotEquals(jsonRes["records"], null);
            test:assertNotEquals(jsonRes["records"], null);
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testExplainQueryOrReportOrListview () {
    log:printInfo("salesforceEP -> explainQueryOrReportOrListview()");
    string queryString = "SELECT name FROM Account";
    response = salesforceEP -> explainQueryOrReportOrListview(queryString);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

//=============================== Search ==================================//

@test:Config
function testSearchSOSLString () {
    log:printInfo("salesforceEP -> searchSOSLString()");
    string searchString = "FIND {ABC Inc}";
    response = salesforceEP -> searchSOSLString(searchString);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

//============================ SObject Information ===============================//

@test:Config
function testGetSObjectBasicInfo () {
    log:printInfo("salesforceEP -> getSObjectBasicInfo()");
    response = salesforceEP -> getSObjectBasicInfo("Account");
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testSObjectPlatformAction () {
    log:printInfo("salesforceEP -> sObjectPlatformAction()");
    response = salesforceEP -> sObjectPlatformAction();
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testDescribeAvailableObjects () {
    log:printInfo("salesforceEP -> describeAvailableObjects()");
    response = salesforceEP -> describeAvailableObjects();
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}


@test:Config
function testDescribeSObject () {
    log:printInfo("salesforceEP -> describeSObject()");
    response = salesforceEP -> describeSObject(ACCOUNT);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

//=============================== Records Related ==================================//

@test:Config
function testGetDeletedRecords () {
    log:printInfo("salesforceEP -> getDeletedRecords()");

    time:Time now = time:currentTime();
    string endDateTime = now.format("yyyy-MM-dd'T'HH:mm:ssZ");
    time:Time weekAgo = now.subtractDuration(0, 0, 1, 0, 0, 0, 0);
    string startDateTime = weekAgo.format("yyyy-MM-dd'T'HH:mm:ssZ");

    response = salesforceEP -> getDeletedRecords("Account", startDateTime, endDateTime);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testGetUpdatedRecords () {
    log:printInfo("salesforceEP -> getUpdatedRecords()");

    time:Time now = time:currentTime();
    string endDateTime = now.format("yyyy-MM-dd'T'HH:mm:ssZ");
    time:Time weekAgo = now.subtractDuration(0, 0, 1, 0, 0, 0, 0);
    string startDateTime = weekAgo.format("yyyy-MM-dd'T'HH:mm:ssZ");

    response = salesforceEP -> getUpdatedRecords("Account", startDateTime, endDateTime);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testCreateMultipleRecords () {
    log:printInfo("salesforceEP -> createMultipleRecords()");

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

    response = salesforceEP -> createMultipleRecords(ACCOUNT, multipleRecords);
    match response {
        json jsonRes => {
            test:assertEquals(jsonRes.hasErrors.toString(), "false", msg = "Found null JSON response!");
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateRecord"]
}
function testGetFieldValuesFromSObjectRecord () {
    log:printInfo("salesforceEP -> getFieldValuesFromSObjectRecord()");
    response = salesforceEP -> getFieldValuesFromSObjectRecord("Account", recordId, "Name,BillingCity");
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testCreateRecordWithExternalId () {
    log:printInfo("CreateRecordWithExternalId");

    externalID = util:uuid();
    json accountExIdRecord = {Name:"Sample Org", BillingCity:"CA", SF_ExternalID__c:externalID};

    string|SalesforceConnectorError stringResponse = salesforceEP -> createRecord(ACCOUNT, accountExIdRecord);
    match stringResponse {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateRecordWithExternalId"]
}
function testGetRecordByExternalId () {
    log:printInfo("salesforceEP -> getRecordByExternalId()");

    response = salesforceEP -> getRecordByExternalId(ACCOUNT, "SF_ExternalID__c", externalID);
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
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateRecordWithExternalId"]
}
function testUpsertSObjectByExternalId () {
    log:printInfo("salesforceEP -> upsertSObjectByExternalId()");
    json upsertRecord = {Name:"Sample Org", BillingCity:"Jaffna, Colombo 3"};
    json|SalesforceConnectorError response = salesforceEP -> upsertSObjectByExternalId(ACCOUNT,
                                                                                       "SF_ExternalID__c",
                                                                                       externalID, upsertRecord);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Expects true on success");
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

// ============================ ACCOUNT SObject: get, create, update, delete ===================== //

@test:Config
function testCreateAccount () {
    log:printInfo("salesforceEP -> createAccount()");
    json account = {Name:"ABC Inc", BillingCity:"New York"};
    string|SalesforceConnectorError stringAccount = salesforceEP -> createAccount(account);
    match stringAccount {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            log:printDebug("Account id: " + id);
            accountId = id;
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateAccount"]
}
function testGetAccountById () {
    log:printInfo("salesforceEP -> getAccountById()");
    response = salesforceEP -> getAccountById(accountId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateAccount"]
}
function testUpdateAccount () {
    log:printInfo("salesforceEP -> updateAccount()");
    json account = {Name:"ABC Inc", BillingCity:"New York-USA"};
    response = salesforceEP -> updateAccount(accountId, account);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateAccount", "testUpdateAccount", "testGetAccountById"]
}
function testDeleteAccount () {
    log:printInfo("salesforceEP -> deleteAccount()");
    response = salesforceEP -> deleteAccount(accountId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

// ============================ LEAD SObject: get, create, update, delete ===================== //

@test:Config
function testCreateLead () {
    log:printInfo("salesforceEP -> createLead()");
    json lead = {LastName:"Carmen", Company:"WSO2", City:"New York"};
    string|SalesforceConnectorError stringLead = salesforceEP -> createLead(lead);
    match stringLead {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            log:printDebug("Lead id: " + id);
            leadId = id;
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateLead"]
}
function testGetLeadById () {
    log:printInfo("salesforceEP -> getLeadById()");
    response = salesforceEP -> getLeadById(leadId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateLead"]
}
function testUpdateLead () {
    log:printInfo("salesforceEP -> updateLead()");
    json updateLead = {LastName:"Carmen", Company:"WSO2 Lanka (Pvt) Ltd"};
    response = salesforceEP -> updateLead(leadId, updateLead);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateLead", "testUpdateLead", "testGetLeadById"]
}
function testDeleteLead () {
    log:printInfo("salesforceEP -> deleteLead()");
    response = salesforceEP -> deleteLead(leadId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

// ============================ CONTACTS SObject: get, create, update, delete ===================== //

@test:Config
function testCreateContact () {
    log:printInfo("salesforceEP -> createContact()");
    json contact = {LastName:"Patson"};
    string|SalesforceConnectorError stringContact = salesforceEP -> createContact(contact);
    match stringContact {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            log:printDebug("Contact id: " + id);
            contactId = id;
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateContact"]
}
function testGetContactById () {
    log:printInfo("salesforceEP -> getContactById()");
    response = salesforceEP -> getContactById(contactId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateContact"]
}
function testUpdateContact () {
    log:printInfo("salesforceEP -> updateContact()");
    json updateContact = {LastName:"Rebert Patson"};
    response = salesforceEP -> updateContact(contactId, updateContact);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateContact", "testUpdateContact", "testGetContactById"]
}
function testDeleteContact () {
    log:printInfo("salesforceEP -> deleteContact()");
    response = salesforceEP -> deleteContact(contactId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

// ============================ PRODUCTS SObject: get, create, update, delete ===================== //

@test:Config
function testCreateProduct () {
    log:printInfo("salesforceEP -> createProduct()");
    json product = {Name:"APIM", Description:"APIM product"};
    string|SalesforceConnectorError stringProduct = salesforceEP -> createProduct(product);
    match stringProduct {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            log:printDebug("Product id: " + id);
            productId = id;
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateProduct"]
}
function testGetProductById () {
    log:printInfo("salesforceEP -> getProductById()");
    response = salesforceEP -> getProductById(productId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateProduct"]
}
function testUpdateProduct () {
    log:printInfo("salesforceEP -> updateProduct()");
    json updateProduct = {Name:"APIM", Description:"APIM new product"};
    response = salesforceEP -> updateProduct(productId, updateProduct);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateProduct", "testUpdateProduct", "testGetProductById"]
}
function testDeleteProduct () {
    log:printInfo("salesforceEP -> deleteProduct()");
    response = salesforceEP -> deleteProduct(productId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

// ============================ OPPORTUNITY SObject: get, create, update, delete ===================== //

@test:Config
function testCreateOpportunity () {
    log:printInfo("salesforceEP -> createOpportunity()");
    json createOpportunity = {Name:"DevServices", StageName:"30 - Proposal/Price Quote", CloseDate:"2019-01-01"};
    string|SalesforceConnectorError stringResponse = salesforceEP -> createOpportunity(createOpportunity);
    match stringResponse {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            log:printDebug("Opportunity id: " + id);
            opportunityId = id;
        }
        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateOpportunity"]
}
function testGetOpportunityById () {
    log:printInfo("salesforceEP -> getOpportunityById()");
    response = salesforceEP -> getOpportunityById(opportunityId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateOpportunity"]
}
function testUpdateOpportunity () {
    log:printInfo("salesforceEP -> updateOpportunity()");
    json updateOpportunity = {Name:"DevServices", StageName:"30 - Proposal/Price Quote", CloseDate:"2019-01-01"};
    response = salesforceEP -> updateOpportunity(opportunityId, updateOpportunity);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateOpportunity", "testUpdateOpportunity", "testGetOpportunityById"]
}
function testDeleteOpportunity () {
    log:printInfo("salesforceEP -> deleteOpportunity()");
    response = salesforceEP -> deleteOpportunity(opportunityId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

function setConfParams (string|() confParam) returns string {
                                                     match confParam {
string param => {
                    return param;
                }
() => {
        log:printInfo("Empty value, found nil!!");
          return "";
       }
   }
}