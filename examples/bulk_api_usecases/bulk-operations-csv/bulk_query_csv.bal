// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/log;
import ballerinax/salesforce.bulk;
import ballerina/os;

// Create Salesforce client configuration by reading from environemnt.
configurable string clientId = os:getEnv("CLIENT_ID");
configurable string clientSecret = os:getEnv("CLIENT_SECRET");
configurable string refreshToken = os:getEnv("REFRESH_TOKEN");
configurable string refreshUrl = os:getEnv("REFRESH_URL");
configurable string baseUrl = os:getEnv("EP_URL");

// Using direct-token config for client configuration
bulk:ConnectionConfig sfConfig = {
    baseUrl,
    auth: {
        clientId,
        clientSecret,
        refreshToken,
        refreshUrl
    }
};

public function main() returns error? {

    string batchId = "";

    // Create Salesforce client.
    bulk:Client bulkClient = check new (sfConfig);

    string queryStr = "SELECT Id, Name FROM Contact WHERE Title='Software Engineer Level 2'";

    bulk:BulkJob|error queryJob = bulkClient->createJob("query", "Contact", "CSV");

    if queryJob is bulk:BulkJob {
        error|bulk:BatchInfo batch = bulkClient->addBatch(queryJob, queryStr);
        if batch is bulk:BatchInfo {
            _ = batch.id.length() > 0 ? "Query Executed Successfully" : "Failed to Execute the Quesry";
            batchId = batch.id;
        } else {
            log:printError(batch.message());
        }

        //get batch info
        error|bulk:BatchInfo batchInfo = bulkClient->getBatchInfo(queryJob, batchId);
        if batchInfo is bulk:BatchInfo {
            string message = batchInfo.id == batchId ? "Batch Info Received Successfully" : "Failed to Retrieve Batch Info";
            log:printInfo(message);
        } else {
            log:printError(batchInfo.message());
        }

        //get all batches
        error|bulk:BatchInfo[] batchInfoList = bulkClient->getAllBatches(queryJob);
        if batchInfoList is bulk:BatchInfo[] {
            string message = batchInfoList.length() == 1 ? "All Batches Received Successfully" : "Failed to Retrieve All Batches";
            log:printInfo(message);
        } else {
            log:printError(batchInfoList.message());
        }

        //get batch request
        var batchRequest = bulkClient->getBatchRequest(queryJob, batchId);
        if batchRequest is string {
            string message = batchRequest.startsWith("SELECT") ? "Batch Request Received Successfully" : "Failed to Retrieve Batch Request";
            log:printInfo(message);

        } else if batchRequest is error {
            log:printError(batchRequest.message());
        } else {
            log:printError(batchRequest.toString());
        }

        //get batch result
        var batchResult = bulkClient->getBatchResult(queryJob, batchId);
        if batchResult is string {
            string[] records = re `\n`.split(batchResult);
            log:printInfo("Number of Records Received :" + (records.length() - 1).toString());

        } else if batchResult is error {
            string msg = batchResult.message();
            log:printError(msg);
        } else {
            log:printError("Invalid Batch Result!");
        }

        //close job
        error|bulk:JobInfo closedJob = bulkClient->closeJob(queryJob);
        if closedJob is bulk:JobInfo {
            string message = closedJob.state == "Closed" ? "Job Closed Successfully" : "Failed to Close the Job";
            log:printInfo(message);
        } else {
            log:printError(closedJob.message());
        }
    }

}

