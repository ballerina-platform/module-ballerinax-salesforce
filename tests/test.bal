package tests;

import ballerina.test;
import ballerina.config;
import config;


string url = config:getAsString(ENDPOINT);
string accessToken = config:getAsString(ACCESS_TOKEN);
string clientId = config:getAsString(CLIENT_ID);
string clientSecret = config:getAsString(CLIENT_SECRET);
string refreshToken = config:getAsString(REFRESH_TOKEN);
string refreshTokenEndpoint = config:getAsString(REFRESH_TOKEN_ENDPOINT);
string refreshTokenPath = config:getAsString(REFRESH_TOKEN_PATH);

json|salesforce:SalesforceConnectorError response;
string accountId = "";
string leadId = "";
string contactId = "";
string opportunityId = "";
string productId = "";

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
    io:println("\n------------------------ getAvailableApiVersions() ----------------------");
    response = salesforceEP -> getAvailableApiVersions();
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError err => {
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
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testGetOrganizationLimits () {
    io:println("\n------------------------ getOrganizationLimits () ----------------------");
    response = salesforceEP -> getOrganizationLimits();
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
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
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
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
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testSearchSOSLString () {
    io:println("\n------------------------ Executing SOSl Searches ---------------------");
    string searchString = "SELECT name FROM Account";
    response = salesforceEP -> searchSOSLString(searchString);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testGetSObjectBasicInfo () {
    io:println("\n----------------------- getSObjectBasicInfo() --------------------------");
    string sObjectAccount = "Account";
    response = salesforceEP -> getSObjectBasicInfo(sObjectAccount);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testSObjectPlatformAction () {
    io:println("\n----------------------- sObjectPlatformAction() ---------------------------");
    response = salesforceEP -> sObjectPlatformAction();
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testGetDeletedRecords () {
    io:println("\n----------------------- getDeletedRecords() ---------------------------");

    time:Time now = time:currentTime();
    string endDateTime = now.format("yyyy-MM-dd'T'HH:mm:ssZ");
    time:Time weekAgo = now.subtractDuration(0, 0, 7, 0, 0, 0, 0);
    string startDateTime = weekAgo.format("yyyy-MM-dd'T'HH:mm:ssZ");

    response = salesforceEP -> getDeletedRecords(sObjectAccount, startDateTime, endDateTime);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testSObjectPlatformAction () {
    io:println("\n----------------------- getUpdatedRecords() ---------------------------");

    time:Time now = time:currentTime();
    string endDateTime = now.format("yyyy-MM-dd'T'HH:mm:ssZ");
    time:Time weekAgo = now.subtractDuration(0, 0, 7, 0, 0, 0, 0);
    string startDateTime = weekAgo.format("yyyy-MM-dd'T'HH:mm:ssZ");

    response = salesforceEP -> getUpdatedRecords(sObjectAccount, startDateTime, endDateTime);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

// ============================ ACCOUNT SObject: get, create, update, delete ===================== //

@test:Config
function testCreateAccount () {
    io:println("\n------------------------ACCOUNT SObjecct Information----------------");
    json account = {Name:"ABC Inc", BillingCity:"New York"};
    string|salesforce:SalesforceConnectorError stringAccount = salesforceEP -> createAccount(account);
    match stringAccount {
        string id => {
            io:println("Account created with: " + id);
            accountId = id;
        }
        salesforce:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testGetAccountById () {
    io:println("\nReceived account details: ");
    response = salesforceEP -> getAccountById(accountId);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testUpdateAccount () {
    io:println("\nUpdated account: ");
    json account = {Name:"ABC Inc", BillingCity:"New York-USA"};
    response = salesforceEP -> updateAccount(accountId, account);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testDeleteAccount () {
    io:println("\nDeleted account: ");
    response = salesforceEP -> deleteAccount(accountId);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

// ============================ LEAD SObject: get, create, update, delete ===================== //

@test:Config
function testCreateLead () {
    io:println("\n------------------------LEAD SObjecct Information----------------");
    json lead = {LastName:"Carmen", Company:"WSO2", City:"New York"};
    string|salesforce:SalesforceConnectorError stringLead = salesforceEP -> createLead(lead);
    match stringLead {
        string id => {
            io:println("Lead created with: " + id);
            leadId = id;
        }
        salesforce:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testGetLeadById () {
    io:println("\nReceived Lead details: ");
    response = salesforceEP -> getLeadById(leadId);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testUpdateLead () {
    io:println("\nUpdated Lead: ");
    json lead = {LastName:"Carmen", Company:"WSO2 Lanka (Pvt) Ltd"};
    response = salesforceEP -> updateLead(leadId, lead);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testDeleteLead () {
    io:println("\nDeleted Lead: ");
    response = salesforceEP -> deleteLead(leadId);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

// ============================ CONTACTS SObject: get, create, update, delete ===================== //

@test:Config
function testCreateContact () {
    io:println("\n------------------------CONTACT SObjecct Information----------------");
    json contact = {LastName:"Patson"};
    string|salesforce:SalesforceConnectorError stringContact = salesforceEP -> createContact(contact);
    match stringContact {
        string id => {
            io:println("Contact created with: " + id);
            contactId = id;
        }
        salesforce:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testGetContactById () {
    io:println("\nReceived Contact details: ");
    response = salesforceEP -> getContactById(contactId);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testUpdateContact () {
    io:println("\nUpdated Contact: ");
    response = salesforceEP -> updateContact(contactId, contact);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testDeleteContact () {
    io:println("\nDeleted Contact: ");
    response = salesforceEP -> deleteContact(contactId);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

// ============================ PRODUCTS SObject: get, create, update, delete ===================== //

@test:Config
function testCreateProduct () {
    io:println("\n------------------------PRODUCTS SObjecct Information----------------");
    json product = {Name:"APIM", Description:"APIM product"};
    string|salesforce:SalesforceConnectorError stringProduct = salesforceEP -> createProduct(product);
    match stringProduct {
        string id => {
            io:println("Products created with: " + id);
            productId = id;
        }
        salesforce:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testGetProductById () {
    io:println("\nReceived Product details: ");
    response = salesforceEP -> getProductById(productId);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testUpdateProduct () {
    io:println("\nUpdated Product: ");
    response = salesforceEP -> updateProduct(productId, product);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testDeleteProduct () {
    io:println("\nDeleted Product: ");
    response = salesforceEP -> deleteProduct(productId);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

// ============================ OPPORTUNITY SObject: get, create, update, delete ===================== //

@test:Config
function testCreateOpportunity () {
    io:println("\n------------------------OPPORTUNITY SObjecct Information----------------");
    json createOpportunity = {Name:"DevServices", StageName:"30 - Proposal/Price Quote", CloseDate:"2019-01-01"};
    string|salesforce:SalesforceConnectorError stringResponse = salesforceEP -> createOpportunity(createOpportunity);
    match stringResponse {
        string id => {
            io:println("Opportunity created with: " + id);
            opportunityId = id;
        }
        salesforce:SalesforceConnectorError err => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testGetOpportunityById () {
    io:println("\nReceived Opportunity details: ");
    response = salesforceEP -> getOpportunityById(opportunityId);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testUpdateOpportunity () {
    io:println("\nUpdated Opportunity: ");
    response = salesforceEP -> updateOpportunity(opportunityId, createOpportunity);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}

@test:Config
function testDeleteOpportunity () {
    io:println("\nDeleted Opportunity: ");
    response = salesforceEP -> deleteOpportunity( opportunityId);
    match response {
        json => {
            test:assertSuccess("Success!");
        }

        SalesforceConnectorError => {
            test:assertFail(msg = err.messages[0]);
        }
    }
}