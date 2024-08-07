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
import ballerina/test;
import ballerina/os;

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
function abortAndDeleteJob() returns error? {
    log:printInfo("baseClient -> deleteCsv");
    //create job
    BulkCreatePayload payload = {
        'object: "Contact",
        contentType: "CSV",
        operation: "delete",
        lineEnding: "LF"
    };
    BulkJob abortJob = check baseClient->createIngestJob(payload);

    log:printInfo("baseClient -> abortJob");
    BulkJobInfo|error abortJobInfo = baseClient->abortJob(abortJob.id, INGEST);
    if abortJobInfo is error {
        test:assertFail(msg = abortJobInfo.message());
    }
    log:printInfo("baseClient -> deleteJob");
    error? deleteJobError = baseClient->deleteJob(abortJob.id, INGEST);
    if deleteJobError is error {
        test:assertFail(msg = deleteJobError.message());
    }
}
