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

import ballerinax/salesforce;
import ballerina/os;
import ballerina/lang.runtime;
import ballerina/io;

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
    // Insert contacts using a CSV file
    salesforce:Client baseClient = check new (sfConfig);
    string csvContactsFilePath = "contacts1.csv";

    //create job
    salesforce:BulkCreatePayload payload = {
        'object : "Contact",
        contentType : "CSV",
        operation : "insert",
        lineEnding : "LF"
    };
    error|salesforce:BulkJob insertJob = baseClient->createIngestJob(payload);

    if insertJob is salesforce:BulkJob {
        string[][] csvContent = check io:fileReadCsv(csvContactsFilePath);
        error? response = baseClient->addBatch(insertJob.id, csvContent);
        if response is error {
            io:println("Error occurred while adding batch to job: ", response.message());
        }
        runtime:sleep(5);
        //get job info
        error|salesforce:BulkJobInfo jobInfo = baseClient->getJobInfo(insertJob.id, "ingest");
        if jobInfo is error {
            io:println("Error occurred while getting job info: ", jobInfo.message());
        }
        runtime:sleep(5);
        //close job
        future<salesforce:BulkJobInfo|error> closedJob = check baseClient->closeIngestJobAndWait(insertJob.id);
        salesforce:BulkJobInfo|error closedJobInfo = wait closedJob;
        if closedJobInfo is error {
            io:println("Error occurred while closing job: ", closedJobInfo.message());
        }
        // check status of each job
        string[][] jobstatus = check baseClient->getJobStatus(insertJob.id, "successfulResults");
        io:println("Job status: ", jobstatus);
    }
}
