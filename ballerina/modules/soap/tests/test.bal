// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.

// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/log;
import ballerina/os;
import ballerina/test;
import ballerinax/salesforce;

const string MOCK_URL = "http://host.docker.internal:8089";

string envClientId = os:getEnv("CLIENT_ID");
string envClientSecret = os:getEnv("CLIENT_SECRET");
string envRefreshToken = os:getEnv("REFRESH_TOKEN");
string envRefreshUrl = os:getEnv("REFRESH_URL");
string envBaseUrl = os:getEnv("EP_URL");
boolean isLiveServer = false;

configurable string clientId = envClientId != "" ? envClientId : "mock-client-id";
configurable string clientSecret = envClientSecret != "" ? envClientSecret : "mock-client-secret";
configurable string refreshToken = envRefreshToken != "" ? envRefreshToken : "mock-refresh-token";
configurable string refreshUrl = envRefreshUrl != "" ? envRefreshUrl : MOCK_URL + "/services/oauth2/token";
configurable string baseUrl = envBaseUrl != "" ? envBaseUrl : MOCK_URL;

ConnectionConfig sfConfig = {
    baseUrl: baseUrl,
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
    }
};

Client soapClient = check new (sfConfig);
salesforce:Client restClient = check new (sfConfig);

string leadId = salesforce:EMPTY_STRING;
string accountId = salesforce:EMPTY_STRING;
string contactId = salesforce:EMPTY_STRING;
string opportunityId = salesforce:EMPTY_STRING;

@test:BeforeSuite
function createLead() {
    log:printInfo("baseClient -> convertLead()");
    record{} leadRecord = {
        "FirstName": "Mark",
        "LastName": "Zucker",
        "Title": "Director",
        "Company": "IT World"
    };
    salesforce:CreationResponse|error res = restClient->create("Lead", leadRecord);
    if res is salesforce:CreationResponse {
        leadId = res.id;
    } else {
        test:assertFail("Lead Not Created");
    }
}

@test:Config {enable: false}
function testconvertLead() {
    ConvertedLead|error response = soapClient->convertLead({leadId: leadId, convertedStatus: "Closed - Converted"});
    if response is ConvertedLead {
        test:assertEquals(leadId, response.leadId, "Lead Not Converted");
        accountId = response.accountId;
        contactId = response.contactId;
        opportunityId = response?.opportunityId.toString();
    } else {
        test:assertFail(response.toString());
    }
}

@test:AfterSuite {
}
function testDeleteRecord() returns error? {
    if !isLiveServer {
        return;
    }
    check restClient->delete("Account", accountId);
    check restClient->delete("Lead", leadId);
}
