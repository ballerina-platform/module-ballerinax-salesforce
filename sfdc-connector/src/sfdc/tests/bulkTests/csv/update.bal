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

import ballerina/log;
import ballerina/test;

@test:Config {
    dependsOn: ["insertCsv", "upsertCsv"]
}
function updateCsv() {
    BulkClient bulkClient = baseClient->getBulkClient();
    log:printInfo("bulkClient -> updateCsv");
    string batchId = "";

    string johnsID = getContactIdByName("John", "Michael", "Professor Grade 04");
    string pedrosID = getContactIdByName("Pedro", "Guterez", "Professor Grade 04");

    string contacts = "Id,description,FirstName,LastName,Title,Phone,Email,My_External_Id__c\n" +
        johnsID + ",Created_from_Ballerina_Sf_Bulk_API,John,Michael,Professor Grade 04,0332236677,john.michael@gmail.com,301\n" +
        pedrosID + ",Created_from_Ballerina_Sf_Bulk_API,Pedro,Guterez,Professor Grade 04,0445567100,pedro.gut@gmail.com,303";

    //create job
    error|BulkJob updateJob = bulkClient->creatJob("update", "Contact", "CSV");

    if (updateJob is BulkJob) {
        //add csv content
        error|BatchInfo batch = updateJob->addBatch(<@untainted>contacts);
        if (batch is BatchInfo) {
            test:assertTrue(batch.id.length() > 0, msg = "Could not upload the contacts using CSV.");
            batchId = batch.id;
        } else {
            test:assertFail(msg = batch.message());
        }

        //get job info
        error|JobInfo jobInfo = bulkClient->getJobInfo(updateJob);
        if (jobInfo is JobInfo) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = jobInfo.message());
        }

        //get batch info
        error|BatchInfo batchInfo = updateJob->getBatchInfo(batchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.message());
        }

        //get all batches
        error|BatchInfo[] batchInfoList = updateJob->getAllBatches();
        if (batchInfoList is BatchInfo[]) {
            test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = batchInfoList.message());
        }

        //get batch request
        var batchRequest = updateJob->getBatchRequest(batchId);
        if (batchRequest is string) {
            test:assertTrue(checkCsvResult(batchRequest) == 2, msg = "Retrieving batch request failed.");
        } else if (batchRequest is error) {
            test:assertFail(msg = batchRequest.message());
        } else {
            test:assertFail(msg = "Invalid Batch Request!");
        }

        var batchResult = updateJob->getBatchResult(batchId);
        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
            test:assertTrue(checkBatchResults(batchResult), msg = "Update was not successful.");
        } else if (batchResult is error) {
            test:assertFail(msg = batchResult.message());
        } else {
            test:assertFail("Invalid Batch Result!");
        }

        //close job
        error|JobInfo closedJob = bulkClient->closeJob(updateJob);
        if (closedJob is JobInfo) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.message());
        }

    } else {
        test:assertFail(msg = updateJob.message());
    }
}
