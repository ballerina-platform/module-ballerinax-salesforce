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
import ballerinax/sfdc;

public function main(){

    string batchId = "";

    // Create Salesforce client configuration by reading from config file.
    sfdc:SalesforceConfiguration sfConfig = {
        baseUrl: "<BASE_URL>",
        clientConfig: {
            clientId: "<CLIENT_ID>",
            clientSecret: "<CLIENT_SECRET>",
            refreshToken: "<REFESH_TOKEN>",
            refreshUrl: "<REFRESH_URL>"
        }
    };

    // Create Salesforce client.
    sfdc:Client baseClient = checkpanic new(sfConfig);
    
    string queryStr = "SELECT Id, Name FROM Contact WHERE Title='Software Engineer Level 3'";

    sfdc:BulkJob|error queryJob = baseClient->creatJob("query", "Contact", "XML");

    if (queryJob is sfdc:BulkJob){
        error|sfdc:BatchInfo batch = baseClient->addBatch(queryJob, queryStr);
        if (batch is sfdc:BatchInfo) {
           string message = batch.id.length() > 0 ? "Query Executed Successfully" :"Failed to Execute the Quesry";
           batchId = batch.id;
        } else {
           log:printError(batch.message());
        }

        //get job info
        error|sfdc:JobInfo jobInfo = baseClient->getJobInfo(queryJob);
        if (jobInfo is sfdc:JobInfo) {
            string message = jobInfo.id.length() > 0 ? "Jon Info Received Successfully" :"Failed Retrieve Job Info";
            log:print(message);
        } else {
            log:printError(jobInfo.message());
        }

        //get batch info
        error|sfdc:BatchInfo batchInfo = baseClient->getBatchInfo(queryJob, batchId);
        if (batchInfo is sfdc:BatchInfo) {
            string message = batchInfo.id == batchId ? "Batch Info Received Successfully" :"Failed to Retrieve Batch Info";
            log:print(message);
        } else {
            log:printError(batchInfo.message());
        }

        //get all batches
        error|sfdc:BatchInfo[] batchInfoList = baseClient->getAllBatches(queryJob);
        if (batchInfoList is sfdc:BatchInfo[]) {
            string message = batchInfoList.length() == 1 ? "All Batches Received Successfully" :"Failed to Retrieve All Batches";
            log:print(message);
        } else {
            log:printError(batchInfoList.message());
        }

        //get batch request
        var batchRequest = baseClient->getBatchRequest(queryJob, batchId);
        if (batchRequest is string) {
            string message = batchRequest.startsWith("SELECT") ? "Batch Request Received Successfully" :"Failed to Retrieve Batch Request";
            log:print(message);
            
        } else if (batchRequest is error) {
            log:printError(batchRequest.message());
        } else {
            log:printError(batchRequest.toString());
        }

        //get batch result
        var batchResult = baseClient->getBatchResult(queryJob, batchId);
        if (batchResult is xml) {
            log:print("Number of Records Received :" + ((batchResult/<*>).length().toString()));
        } else if (batchResult is error) {
           string msg = batchResult.message();
           log:printError(msg);
        } else {
            log:printError("Invalid Batch Result!");
        }

        //close job
        error|sfdc:JobInfo closedJob = baseClient->closeJob(queryJob);
        if (closedJob is sfdc:JobInfo) {
            string message = closedJob.state == "Closed" ? "Job Closed Successfully" :"Failed to Close the Job";
            log:print(message);
        } else {
            log:printError(closedJob.message());
        }
    }
}
