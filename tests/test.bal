//
// Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
//

package tests;

import ballerina/io;
import ballerina/net.http;
import ballerina/time;
import salesforce;

string url = "https://wso2--wsbox.cs8.my.salesforce.com";
string accessToken = "00DL0000002ASPS!ASAAQE8Fjy_aMAjn4G28QIZ7Qjm9c4D5PygH_dCS4CGUVo_zalVOzwZwYAcBUnCNwwFnolNjqEXntHEuZyZ3fmVPC8ZsVFoa";
string clientId = "3MVG9MHOv_bskkhSA6dmoQao1M5bAQdCQ1ePbHYQKaoldqFSas7uechL0yHewu1QvISJZi2deUh5FvwMseYoF";
string clientSecret = "1164810542004702763";
string refreshToken = "5Aep86161DM2BuiV6zOy.J2C.tQMhSDLfkeFVGqMEInbvqLfxwoof9fCkXwO4xihKfjTXkhSLyZRpv0yhBCJ69B";
string refreshTokenEndpoint = "https://test.salesforce.com";
string refreshTokenPath = "/services/oauth2/token";

public function main (string[] args) {
    error Error = {};
    json jsonResponse;
    string nextUrl;

    string sampleSObjectAccount = "Account";
    string sampleSObjectLead = "Lead";
    string sampleSObjectProduct = "Product";
    string sampleSObjectContact = "Contact";
    string sampleSObjectOpportunity = "Opportunity";
    string sampleCustomObject = "Support_Account";
    string apiVersion = "v37.0";

    json account = {Name:"ABC Inc", BillingCity:"New York", Global_POD__c:"UK"};
    json supportAccount = {DevelopmentSupportHours:"72"};
    json lead = {LastName:"Carmen", Company:"WSO2", City:"New York"};
    json contact = {LastName:"Patson"};
    json createOpportunity = {Name:"DevServices", StageName:"30 - Proposal/Price Quote", CloseDate:"2019-01-01"};
    json product = {Name:"APIM", Description:"APIM product"};
    string searchString = "FIND {John Keells Holdings PLC}";
    string accountId = "";
    string leadId = "";
    string contactId = "";
    string opportunityId = "006L0000008xmcU";
    string productId = "";
    string queryString = "SELECT name FROM Account";
    time:Time now = time:currentTime();
    string endDateTime = now.format("yyyy-MM-dd'T'HH:mm:ssZ");
    time:Time weekAgo = now.subtractDuration(0, 0, 7, 0, 0, 0, 0);
    string startDateTime = weekAgo.format("yyyy-MM-dd'T'HH:mm:ssZ");

    salesforce:SalesforceConnector salesforceConnector = {};
    salesforceConnector.init(url, accessToken, refreshToken, clientId, clientSecret, refreshTokenEndpoint, refreshTokenPath);

    json|salesforce:SalesforceConnectorError response;
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////

    io:println("\n------------------------MAIN METHOD: getAvailableApiVersions()----------------------");
    response = salesforceConnector.getAvailableApiVersions();
    checkErrors(response);

    io:println("\n------------------------MAIN METHOD: getResourcesByApiVersion()----------------------");
    response = salesforceConnector.getResourcesByApiVersion(apiVersion);
    checkErrors(response);

    io:println("\n------------------------MAIN METHOD: getOrganizationLimits ()----------------------");
    response = salesforceConnector.getOrganizationLimits();
    checkErrors(response);


    //======================================== Query ===============================================//

    io:println("\n--------------------------MAIN METHOD: getQueryResult ()-------------------------");
    response = salesforceConnector.getQueryResult("SELECT name FROM Account");
    checkErrors(response);

    io:println("\n----------------------MAIN METHOD: explainQueryOrReportOrListview ()---------------------");
    response = salesforceConnector.explainQueryOrReportOrListview(queryString);
    checkErrors(response);

    io:println("\n------------------------MAIN METHOD: Executing SOSl Searches ------------------");
    response = salesforceConnector.searchSOSLString(searchString);
    checkErrors(response);

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    // ============================ Describe SObjects available and their fields/metadata ===================== //

    io:println("\n-----------------------MAIN METHOD: getSObjectBasicInfo() --------------------------");
    response = salesforceConnector.getSObjectBasicInfo(sampleSObjectAccount);
    checkErrors(response);

    io:println("\n-----------------------MAIN METHOD: describeAvailableObjects() ---------------------------");
    checkErrors(response);

    io:println("\n-----------------------MAIN METHOD: describeSObject() ---------------------------");
    response = salesforceConnector.describeSObject(sampleSObjectAccount);
    checkErrors(response);

    io:println("\n-----------------------MAIN METHOD: sObjectPlatformAction() ---------------------------");
    response = salesforceConnector.sObjectPlatformAction();
    checkErrors(response);

    io:println("\n-----------------------MAIN METHOD: getDeletedRecords() ---------------------------");
    response = salesforceConnector.getDeletedRecords(sampleSObjectAccount, startDateTime, endDateTime);
    checkErrors(response);

    io:println("\n-----------------------MAIN METHOD: getUpdatedRecords() ---------------------------");
    response = salesforceConnector.getUpdatedRecords(sampleSObjectAccount, startDateTime, endDateTime);
    checkErrors(response);

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // ============================ ACCOUNT SObject: get, create, update, delete ===================== //

    io:println("\n------------------------ACCOUNT SObjecct Information----------------");
    string|salesforce:SalesforceConnectorError stringResponse = salesforceConnector.createAccount(account);
    match stringResponse {
        string id => {
            io:println("Account created with: " + id);
            accountId = id;
        }
        salesforce:SalesforceConnectorError err => {
            io:println("Error ocurred");
        }
    }

    io:println("\nReceived account details: ");
    response = salesforceConnector.getAccountById(accountId);
    checkErrors(response);

    io:println("\nUpdated account: ");
    response = salesforceConnector.updateAccount(accountId, account);
    checkErrors(response);

    io:println("\nDeleted account: ");
    response = salesforceConnector.deleteAccount(accountId);
    checkErrors(response);
}

public function checkErrors (json|salesforce:SalesforceConnectorError receivedResponse) {
    match receivedResponse {
        json payload => {
        //io:println(payload);
            io:println("Success!");
        }
        salesforce:SalesforceConnectorError err => {
            io:println(err);
        }
    }
}