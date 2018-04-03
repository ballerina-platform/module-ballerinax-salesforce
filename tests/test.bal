package tests;

import ballerina/test;
import ballerina/config;
import ballerina/io;
import ballerina/time;
import salesforce as sf;

string url = setConfParams(config:getAsString("ENDPOINT"));
string accessToken = setConfParams(config:getAsString("ACCESS_TOKEN"));
string clientId = setConfParams(config:getAsString("CLIENT_ID"));
string clientSecret = setConfParams(config:getAsString("CLIENT_SECRET"));
string refreshToken = setConfParams(config:getAsString("REFRESH_TOKEN"));
string refreshTokenEndpoint = setConfParams(config:getAsString("REFRESH_TOKEN_ENDPOINT"));
string refreshTokenPath = setConfParams(config:getAsString("REFRESH_TOKEN_PATH"));

json|sf:SalesforceConnectorError response;
string accountId = "";
string leadId = "";
string contactId = "";
string opportunityId = "";
string productId = "";
string recordId = "";

endpoint sf:SalesforceEndpoint salesforceEP {
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
    io:println("\n------------------------ getAvailableApiVersions() ----------------------");
    response = salesforceEP -> getAvailableApiVersions();
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
            json[] versions =? <json[]>jsonRes;
            test:assertTrue(lengthof versions > 0, msg = "Found 0 or No API versions");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testGetResourcesByApiVersion () {
    io:println("\n------------------------ getResourcesByApiVersion() ----------------------");
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
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testGetOrganizationLimits () {
    io:println("\n------------------------ getOrganizationLimits () ----------------------");
    response = salesforceEP -> getOrganizationLimits();
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
            test:assertTrue(lengthof jsonRes.getKeys() > 0, msg = "Response doesn't have enough keys");
            foreach key in jsonRes {
                try {
                    test:assertNotEquals(key["Max"], null, msg = "Max limit not found");
                    test:assertNotEquals(key["Remaining"], null, msg = "Remaining resources not found");
                } catch (error e) {
                    test:assertFail(msg = "Response is invalid");
                }
            }
        }
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

//============================ Basic functions================================//

@test:Config
function testCreateRecord () {
    io:println("\n------------------------ SObjecct Record Information----------------");
    json accountRecord = {Name:"John Keells Holdings", BillingCity:"Colombo 3"};
    string|sf:SalesforceConnectorError stringResponse = salesforceEP -> createRecord(sf:ACCOUNT, accountRecord);
    match stringResponse {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            recordId = id;
        }
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateRecord"]
}
function testGetRecord () {
    io:println("\nReceived Record details!");
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
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateRecord"]
}
function testUpdateRecord () {
    io:println("\nUpdated Record!");
    json account = {Name:"WSO2 Inc", BillingCity:"Jaffna", Phone:"+94110000000"};
    boolean|sf:SalesforceConnectorError response = salesforceEP -> updateRecord(sf:ACCOUNT, recordId, account);
    match response {
        boolean success => {
            test:assertTrue(success, msg = "Expects true on success");
        }
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateRecord", "testGetRecord", "testUpdateRecord", "testGetFieldValuesFromSObjectRecord"]
}
function testDeleteRecord () {
    io:println("\nDeleted Record! ");
    boolean|sf:SalesforceConnectorError response = salesforceEP -> deleteRecord("Account", recordId);
    match response {
        boolean success => {
            test:assertTrue(success, msg = "Expects true on success");
        }
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

//=============================== Query ==================================//

@test:Config
function testGetQueryResult () {
    io:println("\n-------------------------- getQueryResult () -------------------------");
    string sampleQuery = "SELECT name FROM Account";
    response = salesforceEP -> getQueryResult(sampleQuery);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testExplainQueryOrReportOrListview () {
    io:println("\n------------------ explainQueryOrReportOrListview () ------------------");
    string queryString = "SELECT name FROM Account";
    response = salesforceEP -> explainQueryOrReportOrListview(queryString);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

//=============================== Search ==================================//

@test:Config
function testSearchSOSLString () {
    io:println("\n------------------------ Executing SOSl Searches ---------------------");
    string searchString = "FIND {ABC Inc}";
    response = salesforceEP -> searchSOSLString(searchString);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

//============================ SObject Information ===============================//

@test:Config
function testGetSObjectBasicInfo () {
    io:println("\n----------------------- getSObjectBasicInfo() --------------------------");
    response = salesforceEP -> getSObjectBasicInfo("Account");
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testSObjectPlatformAction () {
    io:println("\n----------------------- sObjectPlatformAction() ---------------------------");
    response = salesforceEP -> sObjectPlatformAction();
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testDescribeAvailableObjects () {
    io:println("\n----------------------- describeAvailableObjects() ---------------------------");
    response = salesforceEP -> describeAvailableObjects();
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}


@test:Config
function testDescribeSObject () {
    io:println("\n----------------------- describeSObject() ---------------------------");
    response = salesforceEP -> describeSObject(sf:ACCOUNT);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

//=============================== Records Related ==================================//

@test:Config
function testGetDeletedRecords () {
    io:println("\n----------------------- getDeletedRecords() ---------------------------");

    time:Time now = time:currentTime();
    string endDateTime = now.format("yyyy-MM-dd'T'HH:mm:ssZ");
    time:Time weekAgo = now.subtractDuration(0, 0, 0, 1, 0, 0, 0);
    string startDateTime = weekAgo.format("yyyy-MM-dd'T'HH:mm:ssZ");

    response = salesforceEP -> getDeletedRecords("Account", startDateTime, endDateTime);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testGetUpdatedRecords () {
    io:println("\n----------------------- getUpdatedRecords() ---------------------------");

    time:Time now = time:currentTime();
    string endDateTime = now.format("yyyy-MM-dd'T'HH:mm:ssZ");
    time:Time weekAgo = now.subtractDuration(0, 0, 0, 1, 0, 0, 0);
    string startDateTime = weekAgo.format("yyyy-MM-dd'T'HH:mm:ssZ");

    response = salesforceEP -> getUpdatedRecords("Account", startDateTime, endDateTime);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testCreateMultipleRecords () {
    io:println("\n------------------------ createMultipleRecords() ----------------");

    json multipleRecords = {"records":[{
                                           "attributes":{"type":"Account", "referenceId":"ref1"},
                                           "name":"SampleAccount1",
                                           "phone":"1111111111",
                                           "website":"www.salesforce.com",
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

    response = salesforceEP -> createMultipleRecords(sf:ACCOUNT, multipleRecords);
    match response {
        json jsonRes => {
            test:assertEquals(jsonRes.hasErrors.toString(), "false", msg = "Found null JSON response!");
        }
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateRecord"]
}
function testGetFieldValuesFromSObjectRecord () {
    io:println("\n--------------------- getFieldValuesFromSObjectRecord() ------------------------");
    response = salesforceEP -> getFieldValuesFromSObjectRecord("Account", recordId, "Name,BillingCity");
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

// ============================ ACCOUNT SObject: get, create, update, delete ===================== //

@test:Config
function testCreateAccount () {
    io:println("\n------------------------ACCOUNT SObjecct Information----------------");
    json account = {Name:"ABC Inc", BillingCity:"New York"};
    string|sf:SalesforceConnectorError stringAccount = salesforceEP -> createAccount(account);
    match stringAccount {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            io:print("Account id: " + id);
            accountId = id;
        }
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateAccount"]
}
function testGetAccountById () {
    io:println("\nReceived account details: ");
    response = salesforceEP -> getAccountById(accountId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateAccount"]
}
function testUpdateAccount () {
    io:println("\nUpdated account: ");
    json account = {Name:"ABC Inc", BillingCity:"New York-USA"};
    response = salesforceEP -> updateAccount(accountId, account);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateAccount", "testUpdateAccount", "testGetAccountById"]
}
function testDeleteAccount () {
    io:println("\nDeleted account: ");
    response = salesforceEP -> deleteAccount(accountId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

// ============================ LEAD SObject: get, create, update, delete ===================== //

@test:Config
function testCreateLead () {
    io:println("\n------------------------LEAD SObjecct Information----------------");
    json lead = {LastName:"Carmen", Company:"WSO2", City:"New York"};
    string|sf:SalesforceConnectorError stringLead = salesforceEP -> createLead(lead);
    match stringLead {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            io:print("Lead id: " + id);
            leadId = id;
        }
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateLead"]
}
function testGetLeadById () {
    io:println("\nReceived Lead details: ");
    response = salesforceEP -> getLeadById(leadId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateLead"]
}
function testUpdateLead () {
    io:println("\nUpdated Lead: ");
    json updateLead = {LastName:"Carmen", Company:"WSO2 Lanka (Pvt) Ltd"};
    response = salesforceEP -> updateLead(leadId, updateLead);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateLead", "testUpdateLead", "testGetLeadById"]
}
function testDeleteLead () {
    io:println("\nDeleted Lead: ");
    response = salesforceEP -> deleteLead(leadId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

// ============================ CONTACTS SObject: get, create, update, delete ===================== //

@test:Config
function testCreateContact () {
    io:println("\n------------------------CONTACT SObjecct Information----------------");
    json contact = {LastName:"Patson"};
    string|sf:SalesforceConnectorError stringContact = salesforceEP -> createContact(contact);
    match stringContact {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            io:print("Contact id: " + id);
            contactId = id;
        }
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateContact"]
}
function testGetContactById () {
    io:println("\nReceived Contact details: ");
    response = salesforceEP -> getContactById(contactId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateContact"]
}
function testUpdateContact () {
    io:println("\nUpdated Contact: ");
    json updateContact = {LastName:"Rebert Patson"};
    response = salesforceEP -> updateContact(contactId, updateContact);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateContact", "testUpdateContact", "testGetContactById"]
}
function testDeleteContact () {
    io:println("\nDeleted Contact: ");
    response = salesforceEP -> deleteContact(contactId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

// ============================ PRODUCTS SObject: get, create, update, delete ===================== //

@test:Config
function testCreateProduct () {
    io:println("\n------------------------PRODUCTS SObjecct Information----------------");
    json product = {Name:"APIM", Description:"APIM product"};
    string|sf:SalesforceConnectorError stringProduct = salesforceEP -> createProduct(product);
    match stringProduct {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            io:print("Product id: " + id);
            productId = id;
        }
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateProduct"]
}
function testGetProductById () {
    io:println("\nReceived Product details: ");
    response = salesforceEP -> getProductById(productId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateProduct"]
}
function testUpdateProduct () {
    io:println("\nUpdated Product: ");
    json updateProduct = {Name:"APIM", Description:"APIM new product"};
    response = salesforceEP -> updateProduct(productId, updateProduct);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateProduct", "testUpdateProduct", "testGetProductById"]
}
function testDeleteProduct () {
    io:println("\nDeleted Product: ");
    response = salesforceEP -> deleteProduct(productId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

// ============================ OPPORTUNITY SObject: get, create, update, delete ===================== //

@test:Config
function testCreateOpportunity () {
    io:println("\n------------------------OPPORTUNITY SObjecct Information----------------");
    json createOpportunity = {Name:"DevServices", StageName:"30 - Proposal/Price Quote", CloseDate:"2019-01-01"};
    string|sf:SalesforceConnectorError stringResponse = salesforceEP -> createOpportunity(createOpportunity);
    match stringResponse {
        string id => {
            test:assertNotEquals(id, "", msg = "Found empty response!");
            io:print("Opportunity id: " + id);
            opportunityId = id;
        }
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateOpportunity"]
}
function testGetOpportunityById () {
    io:println("\nReceived Opportunity details: ");
    response = salesforceEP -> getOpportunityById(opportunityId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Found null JSON response!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateOpportunity"]
}
function testUpdateOpportunity () {
    io:println("\nUpdated Opportunity: ");
    json updateOpportunity = {Name:"DevServices", StageName:"30 - Proposal/Price Quote", CloseDate:"2019-01-01"};
    response = salesforceEP -> updateOpportunity(opportunityId, updateOpportunity);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config {
    dependsOn:["testCreateOpportunity", "testUpdateOpportunity", "testGetOpportunityById"]
}
function testDeleteOpportunity () {
    io:println("\nDeleted Opportunity: ");
    response = salesforceEP -> deleteOpportunity(opportunityId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Failed!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

function setConfParams (string|null confParam) returns string {
    match confParam {
        string param => {
            return param;
        }
    null => {
    io:println("Empty value!");
    return "";
}
}
}