////
//// Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
////
//// WSO2 Inc. licenses this file to you under the Apache License,
//// Version 2.0 (the "License"); you may not use this file except
//// in compliance with the License.
//// You may obtain a copy of the License at
////
//// http://www.apache.org/licenses/LICENSE-2.0
////
//// Unless required by applicable law or agreed to in writing,
//// software distributed under the License is distributed on an
//// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//// KIND, either express or implied.  See the License for the
//// specific language governing permissions and limitations
//// under the License.
////
//
package samples.salesforce;
import ballerina.io;
import ballerina.net.http;
import src.salesforce;

string sampleSObjectAccount = "Account";
string sampleSObjectLead = "Lead";
string sampleSObjectProduct = "Product";
string sampleSObjectContact = "Contact";
string sampleSObjectOpportunity = "Opportunity";
string sampleCustomObject = "Support_Account";
string apiVersion = "v37.0";

string url = "https://wso2--wsbox.cs8.my.salesforce.com";
string accessToken = "00DL0000002ASPS!ASAAQNTh1Gm.6ui_nkxaBfincHX.kUdAfp3ahxGKneXhA.jk_pmeSIxq5uj.ylL0H7pl25RKMjz7pzMdTVFN9NYFqNhowDzQ";
string clientId = "3MVG9MHOv_bskkhSA6dmoQao1M5bAQdCQ1ePbHYQKaoldqFSas7uechL0yHewu1QvISJZi2deUh5FvwMseYoF";
string clientSecret = "1164810542004702763";
string refreshToken = "5Aep86161DM2BuiV6zOy.J2C.tQMhSDLfkeFVGqMEInbvqLfxy2ig1dCvGm4y3JZHcnGuFZHWOs2ypVdbTwyZBL";
string refreshTokenEndpoint = "https://test.salesforce.com";
string refreshTokenPath = "/services/oauth2/token";

salesforce:SalesforceConnectorError connectorError;
json[] jsonArrayResponse;
json jsonResponse;
salesforce:SalesforceConnectorError err;

function main (string[] args) {
    //time:Time now = time:currentTime();
    //string endDateTime = now.format("yyyy-MM-dd'T'HH:mm:ssZ");
    //time:Time weekAgo = now.subtractDuration(0, 0, 7, 0, 0, 0, 0);
    //string startDateTime = weekAgo.format("yyyy-MM-dd'T'HH:mm:ssZ");

    salesforce:SalesforceConnector salesforceConnector = {};
    salesforceConnector.init(url, accessToken, refreshToken, clientId, clientSecret, refreshTokenEndpoint, refreshTokenPath);

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////

    io:println("------------------------MAIN METHOD: API Versions----------------------");
    json[] apiVersions;
    apiVersions, err = salesforceConnector.getAvailableApiVersions();
    checkErrors(err);
    io:println("Found " + lengthof apiVersions + " API versions");

    jsonResponse, err = salesforceConnector.getResourcesByApiVersion(salesforce:API_VERSION);
    checkErrors(err);
    io:println(string `Number of resources by API Version {{apiVersion}}: {{lengthof jsonResponse.getKeys()}}`);

    io:println("\n------------------------MAIN METHOD: Organizational Limits-------------------------");
    jsonResponse, err = salesforceConnector.getOrganizationLimits();
    checkErrors(err);
    io:println(string `There are resource limits for {{lengthof jsonResponse.getKeys()}} resources`);


    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    // ============================ Describe SObjects available and their fields/metadata ===================== //

    io:println("\n-----------------------MAIN METHOD: Describe global and sobject metadata---------------------------");
    jsonResponse, err = salesforceConnector.describeAvailableObjects();
    checkErrors(err);
    io:println(string `Global has {{lengthof jsonResponse.sobjects}} sobjects`);

    jsonResponse, err = salesforceConnector.getSObjectBasicInfo(sampleSObjectAccount);
    checkErrors(err);
    io:println(string `SObject '{{sampleSObjectAccount}}' has {{lengthof jsonResponse.objectDescribe.getKeys()}} keys and {{lengthof jsonResponse.recentItems}} recent items`);

    jsonResponse, err = salesforceConnector.describeSObject(sampleSObjectAccount);
    checkErrors(err);
    io:println(string `Describe {{sampleSObjectAccount}} has {{lengthof jsonResponse.fields}} fields and {{lengthof jsonResponse.childRelationships}} child relationships`);

    jsonResponse, err = salesforceConnector.sObjectPlatformAction();
    checkErrors(err);
    io:println(string `SObject Platform Action response is:`);
    io:println(jsonResponse.toString());


    //////////////////////////////////////////////////////////////////////////////////////////////////////////

    io:println("\n------------------------MAIN METHOD: Handling Records---------------------------");
    json account = {Name:"ABC Inc", BillingCity:"New York", Global_POD__c:"UK"};
    json supportAccount = {DevelopmentSupportHours:"72"};
    json lead = {LastName:"Carmen", Company:"WSO2", City:"New York"};
    json contact = {LastName:"Patson"};
    json createOpportunity = {Name:"DevServices", StageName:"30 - Proposal/Price Quote", CloseDate:"2019-01-01"};
    json product = {Name:"APIM", Description:"APIM product"};
    string searchString = "FIND {John Keells Holdings PLC}";
    string accountId;
    string leadId;
    string contactId;
    string opportunityId = "006L0000008xmcU";
    string productId;


    /////////////////////////////////////////////////////////////////////////////////////////////////
    // ============================ Get, create, update, delete records ========================== //

    accountId, err = salesforceConnector.createRecord(sampleSObjectAccount, account);
    if (err == null) {
        io:println(string `Created {{sampleSObjectAccount}} with id: {{accountId}}`);
    } else {
        io:println(string `Error occurred when creating {{sampleSObjectAccount}}: {{err.messages[0]}}`);
        return;
    }

    jsonResponse, err = salesforceConnector.getRecord(sampleSObjectAccount, accountId);
    checkErrors(err);
    io:println(string `Name of {{sampleSObjectAccount}} with id {{accountId}} is {{jsonResponse.Name.toString()}}`);

    account.Name = "ABC Pvt Ltd";
    boolean isUpdated;
    isUpdated, err = salesforceConnector.updateRecord(sampleSObjectAccount, accountId, account);
    if (isUpdated) {
        io:println(string `{{sampleSObjectAccount}} successfully updated`);
    } else {
        io:println(string `Error occurred when updating {{sampleSObjectAccount}}: {{err.messages[0]}}`);
    }

    boolean isDeleted;
    isDeleted, err = salesforceConnector.deleteRecord(sampleSObjectAccount, accountId);
    if (isDeleted) {
        io:println(string `{{sampleSObjectAccount}}[{{accountId}}] successfully deleted`);
    } else {
        io:println(string `Error occurred when deleting {{sampleSObjectAccount}}[{{accountId}}]: {{err.messages[0]}}`);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // ============================ Get updated and deleted records ============================= //

    io:println("\n------------------------MAIN METHOD: Get updated and deleted----------------");
    jsonResponse, err = salesforceConnector.getDeletedRecords(sampleSObjectAccount, startDateTime, endDateTime);
    checkErrors(err);
    io:println(string `Found {{lengthof jsonResponse.deletedRecords}} deleted records`);

    jsonResponse, err = salesforceConnector.getUpdatedRecords(sampleSObjectAccount, startDateTime, endDateTime);
    checkErrors(err);
    io:println(string `Found {{lengthof jsonResponse.ids}} ids of updated records`);


    ////////////////////////////////////////////////////////////////////////////////////////////////
    // ============================ Executing Queries and Searches ============================= //

    io:println("\n------------------------MAIN METHOD: Executing SOQL queries ------------------");
    salesforce:QueryResult queryResult;

    queryResult, err = salesforceConnector.getQueryResult("SELECT name FROM Account");
    checkErrors(err);
    io:println(string `Found {{lengthof queryResult.records}} results. Next result URL: {{queryResult.nextRecordsUrl}}`);

    while (queryResult.nextRecordsUrl != null) {
        queryResult, err = queryResult.getNextQueryResult();
        io:println(string `Found {{lengthof queryResult.records}} results. Next result URL: {{queryResult.nextRecordsUrl}}`);
    }

    salesforce:QueryPlan[] queryPlans;

    queryPlans, err = salesforceConnector.explainQueryOrReportOrListview("SELECT name FROM Account");
    checkErrors(err);
    io:println(string `Found {{lengthof queryPlans}} query plans`);
    io:println(queryPlans);

    io:println("\n------------------------MAIN METHOD: Executing SOSl Searches ------------------");
    salesforce:SearchResult[] searchResults;
    searchResults, err = salesforceConnector.searchSOSLString(searchString);
    checkErrors(err);
    io:println(string `Found {{lengthof searchResults}} results for "{{searchString}}" SOSL search.`);

    // ============================ Create, update, delete records by External IDs ===================== //

    io:println("\n------------------------MAIN METHOD: Handling records by External IDs-----------");
    account.Name = "Updated Logistics and Transport";
    jsonResponse, err = salesforceConnector.upsertSObjectByExternalId(sampleCustomObject, "JIRA_Key__c", "ABSOLUTEDSVCSDEVSVC", supportAccount);
    if (err == null) {
        io:println("Upsert successful: " + jsonResponse.toString());
    } else {
        io:println(string `Error occurred when upserting {{sampleSObjectAccount}}: {{err.messages[0]}}`);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // ============================ ACCOUNT SObject: get, create, update, delete ===================== //

    io:println("\n------------------------ACCOUNT SObjecct Information----------------");
    accountId, err = salesforceConnector.createAccount(account);
    if (err == null) {
        io:println(string `Created {{sampleSObjectAccount}} with id: {{accountId}}`);
    } else {
        io:println(string `Error occurred when creating {{sampleSObjectAccount}}: {{err.messages[0]}}`);
        return;
    }

    jsonResponse, err = salesforceConnector.getAccountById(accountId);
    io:println(string `Name of {{sampleSObjectAccount}} with id {{accountId}} is {{jsonResponse.Name.toString()}}`);

    account.Name = "ABC Pvt Ltd";
    isUpdated, err = salesforceConnector.updateAccount(accountId, account);
    if (isUpdated) {
        io:println(string `{{sampleSObjectAccount}} successfully updated`);
    } else {
        io:println(string `Error occurred when updating {{sampleSObjectAccount}}: {{err.messages[0]}}`);
    }

    isDeleted, err = salesforceConnector.deleteAccount(accountId);
    if (isDeleted) {
        io:println(string `{{sampleSObjectAccount}}[{{accountId}}] successfully deleted`);
    } else {
        io:println(string `Error occurred when deleting {{sampleSObjectAccount}}[{{accountId}}]: {{err.messages[0]}}`);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    //// ============================ LEAD SObject: get, create, update, delete ===================== //

    io:println("\n------------------------LEAD SObjecct Information-----------------------");
    leadId, err = salesforceConnector.createLead(lead);
    if (err == null) {
        io:println(string `Created {{sampleSObjectLead}} with id: {{leadId}}`);
    } else {
        io:println(string `Error occurred when creating {{sampleSObjectLead}}: {{err.messages[0]}}`);
        return;
    }

    jsonResponse, err = salesforceConnector.getLeadById(leadId);
    io:println(string `Name of {{sampleSObjectLead}} with id {{leadId}} is {{jsonResponse.LastName.toString()}}`);

    lead.City = "Colombo";
    isUpdated, err = salesforceConnector.updateLead(leadId, lead);
    if (isUpdated) {
        io:println(string `{{sampleSObjectLead}} successfully updated`);
    } else {
        io:println(string `Error occurred when updating {{sampleSObjectLead}}: {{err.messages[0]}}`);
    }

    isDeleted, err = salesforceConnector.deleteLead(leadId);
    if (isDeleted) {
        io:println(string `{{sampleSObjectLead}}[{{leadId}}] successfully deleted`);
    } else {
        io:println(string `Error occurred when deleting {{sampleSObjectLead}}[{{leadId}}]: {{err.messages[0]}}`);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    //// ============================ Contact SObject: get, create, update, delete ===================== //

    io:println("\n------------------------CONTACT SObjecct Information-----------------------");
    contactId, err = salesforceConnector.createContact(contact);
    if (err == null) {
        io:println(string `Created {{sampleSObjectContact}} with id: {{contactId}}`);
    } else {
        io:println(string `Error occurred when creating {{sampleSObjectContact}}: {{err.messages[0]}}`);
        return;
    }

    jsonResponse, err = salesforceConnector.getContactById(contactId);
    io:println(string `Name of {{sampleSObjectContact}} with id {{contactId}} is {{jsonResponse.LastName.toString()}}`);

    contact.LastName = "Perterson";
    isUpdated, err = salesforceConnector.updateContact(contactId, contact);
    if (isUpdated) {
        io:println(string `{{sampleSObjectContact}} successfully updated`);
    } else {
        io:println(string `Error occurred when updating {{sampleSObjectContact}}: {{err.messages[0]}}`);
    }

    isDeleted, err = salesforceConnector.deleteContact(contactId);
    if (isDeleted) {
        io:println(string `{{sampleSObjectContact}}[{{contactId}}] successfully deleted`);
    } else {
        io:println(string `Error occurred when deleting {{sampleSObjectContact}}[{{contactId}}]: {{err.messages[0]}}`);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    //// ============================ Product SObject: get, create, update, delete ===================== //

    io:println("\n------------------------PRODUCT SObjecct Information-----------------------");
    productId, err = salesforceConnector.createProduct(product);
    if (err == null) {
        io:println(string `Created {{sampleSObjectProduct}} with id: {{productId}}`);
    } else {
        io:println(string `Error occurred when creating {{sampleSObjectProduct}}: {{err.messages[0]}}`);
        return;
    }

    jsonResponse, err = salesforceConnector.getProductById(productId);
    io:println(string `Name of {{sampleSObjectProduct}} with id {{productId}} is {{jsonResponse.Description.toString()}}`);

    contact.Description = "APIM and IS product";
    isUpdated, err = salesforceConnector.updateProduct(productId, product);
    if (isUpdated) {
        io:println(string `{{sampleSObjectProduct}} successfully updated`);
    } else {
        io:println(string `Error occurred when updating {{sampleSObjectProduct}}: {{err.messages[0]}}`);
    }

    isDeleted, err = salesforceConnector.deleteProduct(productId);
    if (isDeleted) {
        io:println(string `{{sampleSObjectProduct}}[{{productId}}] successfully deleted`);
    } else {
        io:println(string `Error occurred when deleting {{sampleSObjectProduct}}[{{productId}}]: {{err.messages[0]}}`);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //// ========================= Opportunities SObject: get, create, update, delete =================== //

    io:println("\n------------------------OPPORTUNITY SObjecct Information-----------------------");
    //
    //contactId, err = salesforceConnector.createOpportunity(createOpportunity);
    //if (err == null) {
    //    io:println(string `Created {{sampleSObjectContact}} with id: {{contactId}}`);
    //} else {
    //    io:println(string `Error occurred when creating {{sampleSObjectContact}}: {{err.messages[0]}}`);
    //    return;
    //}

    jsonResponse, err = salesforceConnector.getOpportunityById(opportunityId);
    io:println(string `Name of {{sampleSObjectOpportunity}} with id: {{opportunityId}}'s Stage Name is: {{jsonResponse.StageName.toString()}} `);

    json updateOpportunity = {StageName:"19 - Pre-BANT"};
    isUpdated, err = salesforceConnector.updateOpportunity(opportunityId, updateOpportunity);
    if (isUpdated) {
        io:println(string `{{sampleSObjectOpportunity}} successfully updated`);
    } else {
        io:println(string `Error occurred when updating {{sampleSObjectOpportunity}}: {{err.messages[0]}}`);
    }

    // ========= deleteOpportunity() is commented because Opportunity will be deleted from staging environment===========//
    //isDeleted, err = salesforceConnector.deleteOpportunity(opportunityId);
    //if (isDeleted) {
    //    io:println(string `{{sampleSObjectOpportunity}}[{{opportunityId}}] successfully deleted`);
    //} else {
    //    io:println(string `Error occurred when deleting {{sampleSObjectOpportunity}}[{{contactId}}]: {{err.messages[0]}}`);
    //}
}

function checkErrors (salesforce:SalesforceConnectorError err) {
    if (err != null) {
        if (err.salesforceErrors != null) {
            io:println(string `Salesforce Error {{err.salesforceErrors[0].message}} with error code: {{err.salesforceErrors[0].errorCode}}`);
        } else {
            io:println(string `Connector error: {{err.errors[0].message}}`);
        }
    }
}