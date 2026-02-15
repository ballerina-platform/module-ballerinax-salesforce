// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/io;
import ballerina/log;
import ballerina/test;
import ballerina/os;
import ballerinax/salesforce;

json[] jsonInsertResult = [];
xml xmlInsertResult = xml ``;
string csvInputResult = "Id";

const string MOCK_URL = "http://localhost:8089";

string envClientId = os:getEnv("CLIENT_ID");
string envClientSecret = os:getEnv("CLIENT_SECRET");
string envRefreshToken = os:getEnv("REFRESH_TOKEN");
string envRefreshUrl = os:getEnv("REFRESH_URL");
string envBaseUrl = os:getEnv("EP_URL");

// Create Salesforce client configuration by reading from environment.
string clientId = envClientId != "" ? envClientId : "mock-client-id";
string clientSecret = envClientSecret != "" ? envClientSecret : "mock-client-secret";
string refreshToken = envRefreshToken != "" ? envRefreshToken : "mock-refresh-token";
string refreshUrl = envRefreshUrl != "" ? envRefreshUrl : MOCK_URL + "/services/oauth2/token";
string baseUrl = envBaseUrl != "" ? envBaseUrl : MOCK_URL;

// Using direct-token config for client configuration
ConnectionConfig sfConfig = {
    baseUrl: baseUrl,
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
    }
};

Client? baseClient = ();
salesforce:Client? restClient = ();

isolated function closeRb(io:ReadableByteChannel ch) {
    io:Error? cr = ch.close();
    if cr is error {
        log:printError("Error occured while closing the channel: ", 'error = cr);
    }
}

isolated function checkBatchResults(Result result) returns boolean {
    if !result.success {
        return false;
    }
    return true;
}

isolated function checkCsvResult(string result) returns int {
    string[] lineArray = re `\n`.split(result);
    int arrLength = lineArray.length();
    return arrLength - 1;
}

type ResultValue record {|
    record{} value;
|};

function getContactIdByName(string firstName, string lastName, string title) returns string|error {
    salesforce:Client restClient = check new (sfConfig);
    string contactId = "";
    string sampleQuery = 
    string `SELECT Id FROM Contact WHERE FirstName='${firstName}' AND LastName='${lastName}' AND Title='${title}'`;
    stream<record{}, error?> queryResults = check restClient->query(sampleQuery);
    ResultValue|error? result = queryResults.next();
    if (result is ResultValue) {
        contactId = check result.value.get("Id").ensureType();
    } else {
        test:assertFail(msg = "Getting contact ID by name failed.");
    }
    return contactId;
}

isolated function getJsonContactsToDelete(json[] resultList) returns json[] {
    json[] contacts = [];
    foreach json item in resultList {
        json|error itemId = item.id;
        if itemId is json && itemId !== EMPTY_STRING {
            string id = itemId.toString();
            contacts[contacts.length()] = {"Id": id};
        }
    }
    return contacts;
}

@test:AfterSuite{
    alwaysRun: true
}
function afterSuite() returns error? {
    error? ignoreResult = deleteCsvResources(ignoreResult = true);
    ignoreResult = deleteXmlResources(ignoreResult = true);
    ignoreResult = deleteJsonResources(ignoreResult = true);
}
