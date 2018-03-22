//package samples.salesforce;

import ballerina.io;
import ballerina.net.http;
import src.salesforce;

string url = "https://wso2--wsbox.cs8.my.salesforce.com";
string accessToken = "00DL0000002ASPS!ASAAQHeqWoNZcLhSij5irvaZBXR9m0SFxcmZ90jKFMLVt0D8SgQLouhEZpvCTmDbcDgOajRCSR.Gl56uQQrDBE_H7JWQkWNH";
string clientId = "3MVG9MHOv_bskkhSA6dmoQao1M5bAQdCQ1ePbHYQKaoldqFSas7uechL0yHewu1QvISJZi2deUh5FvwMseYoF";
string clientSecret = "1164810542004702763";
string refreshToken = "5Aep86161DM2BuiV6zOy.J2C.tQMhSDLfkeFVGqMEInbvqLfxylW8qZmyAc0zMaw2zTPkk6W1GMsXikrYOdIdfS";
string refreshTokenEndpoint = "https://test.salesforce.com";
string refreshTokenPath = "/services/oauth2/token";

public function main (string[] args) {
    error Error = {};
    json jsonResponse;

    json account = {Name:"ABC Inc", BillingCity:"New York", Global_POD__c:"UK"};
    string accountId = "";

    salesforce:SalesforceConnector salesforceConnector = {};
    salesforceConnector.init(url, accessToken, refreshToken, clientId, clientSecret, refreshTokenEndpoint, refreshTokenPath);

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////

    io:println("\n------------------------MAIN METHOD: getAvailableApiVersions()----------------------");
    try {
        jsonResponse = salesforceConnector.getAvailableApiVersions();
        io:println("Success!");
        //io:println(jsonResponse);
    } catch (error e) {
        io:println(e);
    }

    io:println("\n------------------------MAIN METHOD: getResourcesByApiVersion()----------------------");
    try {
        jsonResponse = salesforceConnector.getResourcesByApiVersion("v37.0");
        io:println("Success!");
        //io:println(jsonResponse);
    } catch (error e) {
        io:println(e);
    }

    io:println("\n------------------------MAIN METHOD: getOrganizationLimits ()----------------------");
    try {
        jsonResponse = salesforceConnector.getOrganizationLimits();
        io:println("Success!");
        //io:println(jsonResponse);
    } catch (error e) {
        io:println(e);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // ============================ ACCOUNT SObject: get, create, update, delete ===================== //

    io:println("\n------------------------ACCOUNT SObjecct Information----------------");
    try {
        string response = salesforceConnector.createAccount(account);
        accountId = response;
        io:println("\n Account created with: " + response);
    } catch (error e) {
        io:println(e);
    }

    try {
        json j1 = salesforceConnector.getAccountById(accountId);
        io:println("\n Account details received successfully for: " + accountId);
    } catch (error e) {
        io:println(e);
    }

    try {
        boolean response = salesforceConnector.updateAccount(accountId, account);
        if (response) {
            io:println("\n Account successfully updated! ");
        }
    } catch (error e) {
        io:println(e);
    }

    try {
        boolean response = salesforceConnector.deleteAccount(accountId);
        if (response) {
            io:println("\n Account successfully deleted! ");
        }
    } catch (error e) {
        io:println(e);
    }

}