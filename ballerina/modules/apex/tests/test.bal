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

// Create Salesforce client configuration by reading from environemnt.
configurable string clientId = os:getEnv("CLIENT_ID");
configurable string clientSecret = os:getEnv("CLIENT_SECRET");
configurable string refreshToken = os:getEnv("REFRESH_TOKEN");
configurable string refreshUrl = os:getEnv("REFRESH_URL");
configurable string baseUrl = os:getEnv("EP_URL");

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
