// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
import ballerinax/salesforce;
import ballerina/os;
import ballerina/lang.runtime;

// Create Salesforce client configuration by reading from environemnt.
configurable string clientId = os:getEnv("CLIENT_ID");
configurable string clientSecret = os:getEnv("CLIENT_SECRET");
configurable string refreshToken = os:getEnv("REFRESH_TOKEN");
configurable string refreshUrl = os:getEnv("REFRESH_URL");
configurable string baseUrl = os:getEnv("EP_URL");

// Using direct-token config for client configuration
salesforce:ConnectionConfig sfConfig = {
    baseUrl,
    auth: {
        clientId,
        clientSecret,
        refreshToken,
        refreshUrl
    }
};

public function main() returns error? {
    // Create Case using user defined APEX method
    salesforce:Client baseClient = check new (sfConfig);

    string|error caseId = baseClient->apexRestExecute("Cases", "POST", 
        {"subject" : "Item Fault!",
            "status" : "New",
            "priority" : "High"});
    if caseId is error {
        log:printError("Error occurred while creating the case. ");
        return;
    }
    runtime:sleep(5);
    record{}|error case = baseClient->apexRestExecute(string `Cases/${caseId}`, "GET", {});
    if case is error {
        log:printError("Error occurred while retrieving the case. ");
        return;
    }
}
