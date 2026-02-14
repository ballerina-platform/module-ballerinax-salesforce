// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/log;
import ballerina/os;
import ballerina/test;
import ballerina/lang.runtime;

const string MOCK_URL = "http://host.docker.internal:8089";

string envClientId = os:getEnv("CLIENT_ID");
string envClientSecret = os:getEnv("CLIENT_SECRET");
string envRefreshToken = os:getEnv("REFRESH_TOKEN");
string envRefreshUrl = os:getEnv("REFRESH_URL");
string envBaseUrl = os:getEnv("EP_URL");

// Create Salesforce client configuration by reading from environment.
configurable string clientId = envClientId != "" ? envClientId : "mock-client-id";
configurable string clientSecret = envClientSecret != "" ? envClientSecret : "mock-client-secret";
configurable string refreshToken = envRefreshToken != "" ? envRefreshToken : "mock-refresh-token";
configurable string refreshUrl = envRefreshUrl != "" ? envRefreshUrl : MOCK_URL + "/services/oauth2/token";
configurable string baseUrl = envBaseUrl != "" ? envBaseUrl : MOCK_URL;

// Using direct-token config for client configuration
ConnectionConfig sfConfigRefreshCodeFlow = {
    baseUrl: baseUrl,
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
    }
};

Client baseClient = check new (sfConfigRefreshCodeFlow);

@test:Config {
    enable: true
}
function testApex() returns error? {
    log:printInfo("baseClient -> executeApex()");
    string|error caseId = baseClient->apexRestExecute("Cases", "POST", 
        {"subject" : "Bigfoot Sighting9!",
            "status" : "New",
            "origin" : "Phone",
            "priority" : "Low"});
    if caseId is error {
        test:assertFail(msg = caseId.message());
    }
    runtime:sleep(5);
    record{}|error case = baseClient->apexRestExecute(string `Cases/${caseId}`, "GET", {});
    if case is error {
        test:assertFail(msg = case.message());
    }
    runtime:sleep(5);
    error? deleteResponse = baseClient->apexRestExecute(string `Cases/${caseId}`, "DELETE", {});
    if deleteResponse is error {
        test:assertFail(msg = deleteResponse.message());
    }
}
