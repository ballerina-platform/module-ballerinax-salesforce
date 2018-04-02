package tests;

import ballerina/test;
import ballerina/config;
import ballerina/io;
import ballerina/time;
import salesforce as sf;

string|null url = config:getAsString("ENDPOINT");
string|null accessToken = config:getAsString("ACCESS_TOKEN");
string|null clientId = config:getAsString("CLIENT_ID");
string|null clientSecret = config:getAsString("CLIENT_SECRET");
string|null refreshToken = config:getAsString("REFRESH_TOKEN");
string|null refreshTokenEndpoint = config:getAsString("REFRESH_TOKEN_ENDPOINT");
string|null refreshTokenPath = config:getAsString("REFRESH_TOKEN_PATH");

json|sf:SalesforceConnectorError response;
string accountId = "";
string leadId = "";
string contactId = "";
string opportunityId = "";
string productId = "";

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
            test:assertNotEquals(jsonRes, null, msg = "Received API versions!");
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
            test:assertNotEquals(jsonRes, null, msg = "Received Resources!");
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
            test:assertNotEquals(jsonRes, null, msg = "Received Organization Limits!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testGetQueryResult () {
    io:println("\n-------------------------- getQueryResult () -------------------------");
    string sampleQuery = "SELECT name FROM Account";
    response = salesforceEP -> getQueryResult(sampleQuery);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Received Query Results!");
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
            test:assertNotEquals(jsonRes, null, msg = "Received Explanation!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testSearchSOSLString () {
    io:println("\n------------------------ Executing SOSl Searches ---------------------");
    string searchString = "FIND {ABC Inc}";
    response = salesforceEP -> searchSOSLString(searchString);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Received Search Results!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testGetSObjectBasicInfo () {
    io:println("\n----------------------- getSObjectBasicInfo() --------------------------");
    response = salesforceEP -> getSObjectBasicInfo("Account");
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Received Object Info!");
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
            test:assertNotEquals(jsonRes, null, msg = "Received Results!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

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
            test:assertNotEquals(jsonRes, null, msg = "Received Deleted Records!");
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
            test:assertNotEquals(jsonRes, null, msg = "Received Updated Records!");
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
            test:assertNotEquals(id, "", msg = "Account Created with new ID ");
            io:print(id);
            accountId = id;
        }
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config{
    dependsOn:["testCreateAccount"]
}
function testGetAccountById () {
    io:println("\nReceived account details: ");
    response = salesforceEP -> getAccountById(accountId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Success!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config{
    dependsOn:["testCreateAccount"]
}
function testUpdateAccount () {
    io:println("\nUpdated account: ");
    json account = {Name:"ABC Inc", BillingCity:"New York-USA"};
    response = salesforceEP -> updateAccount(accountId, account);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Success!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config{
    dependsOn:["testCreateAccount", "testUpdateAccount", "testGetAccountById"]
}
function testDeleteAccount () {
    io:println("\nDeleted account: ");
    response = salesforceEP -> deleteAccount(accountId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Success!");
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
            test:assertNotEquals(id, "", msg = "Lead Created with new ID ");
            io:print(id);
            leadId = id;
        }
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config{
    dependsOn:["testCreateLead"]
}
function testGetLeadById () {
    io:println("\nReceived Lead details: ");
    response = salesforceEP -> getLeadById(leadId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Success!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config{
    dependsOn:["testCreateLead"]
}
function testUpdateLead () {
    io:println("\nUpdated Lead: ");
    json updateLead = {LastName:"Carmen", Company:"WSO2 Lanka (Pvt) Ltd"};
    response = salesforceEP -> updateLead(leadId, updateLead);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Success!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config{
    dependsOn:["testCreateLead", "testUpdateLead", "testGetLeadById"]
}
function testDeleteLead () {
    io:println("\nDeleted Lead: ");
    response = salesforceEP -> deleteLead(leadId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Success!");
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
            test:assertNotEquals(id, "", msg = "Contact created with new ID ");
            io:print(id);
            contactId = id;
        }
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config{
    dependsOn:["testCreateContact"]
}
function testGetContactById () {
    io:println("\nReceived Contact details: ");
    response = salesforceEP -> getContactById(contactId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Success!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config{
    dependsOn:["testCreateContact"]
}
function testUpdateContact () {
    io:println("\nUpdated Contact: ");
    json updateContact = {LastName:"Rebert Patson"};
    response = salesforceEP -> updateContact(contactId, updateContact);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Success!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config{
    dependsOn:["testCreateContact", "testUpdateContact", "testGetContactById"]
}
function testDeleteContact () {
    io:println("\nDeleted Contact: ");
    response = salesforceEP -> deleteContact(contactId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Success!");
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
            test:assertNotEquals(id, "", msg = "Product created with new ID ");
            io:print(id);
            productId = id;
        }
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config{
    dependsOn:["testCreateProduct"]
}
function testGetProductById () {
    io:println("\nReceived Product details: ");
    response = salesforceEP -> getProductById(productId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Success!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config{
    dependsOn:["testCreateProduct"]
}
function testUpdateProduct () {
    io:println("\nUpdated Product: ");
    json updateProduct = {Name:"APIM", Description:"APIM new product"};
    response = salesforceEP -> updateProduct(productId, updateProduct);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Success!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config{
    dependsOn:["testCreateProduct", "testUpdateProduct", "testGetProductById"]
}
function testDeleteProduct () {
    io:println("\nDeleted Product: ");
    response = salesforceEP -> deleteProduct(productId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Success!");
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
            test:assertNotEquals(id, "", msg = "Opportunity created with new ID ");
            io:print(id);
            opportunityId = id;
        }
        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config{
    dependsOn:["testCreateOpportunity"]
}
function testGetOpportunityById () {
    io:println("\nReceived Opportunity details: ");
    response = salesforceEP -> getOpportunityById(opportunityId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Success!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config{
    dependsOn:["testCreateOpportunity"]
}
function testUpdateOpportunity () {
    io:println("\nUpdated Opportunity: ");
    json updateOpportunity = {Name:"DevServices", StageName:"30 - Proposal/Price Quote", CloseDate:"2019-01-01"};
    response = salesforceEP -> updateOpportunity(opportunityId, updateOpportunity);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Success!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config{
    dependsOn:["testCreateOpportunity", "testUpdateOpportunity", "testGetOpportunityById"]
}
function testDeleteOpportunity () {
    io:println("\nDeleted Opportunity: ");
    response = salesforceEP -> deleteOpportunity(opportunityId);
    match response {
        json jsonRes => {
            test:assertNotEquals(jsonRes, null, msg = "Success!");
        }

        sf:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}