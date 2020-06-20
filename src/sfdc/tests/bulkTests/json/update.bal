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
    dependsOn: ["insertJson", "upsertJson"]
}
function updateJson() {
    BulkClient bulkClient = baseClient->getBulkClient();
    log:printInfo("bulkClient -> updateJson");
    string batchId = "";
    string mornsId = getContactIdByName("Morne", "Morkel", "Professor Grade 03");
    string andisId = getContactIdByName("Andi", "Flower", "Professor Grade 03");

    json contacts = [
            {
                description: "Created_from_Ballerina_Sf_Bulk_API",
                Id: mornsId,
                FirstName: "Morne",
                LastName: "Morkel",
                Title: "Professor Grade 03",
                Phone: "0552226670",
                Email: "morne@w3c.com",
                My_External_Id__c: "201"
            },
            {
                description: "Created_from_Ballerina_Sf_Bulk_API",
                Id: andisId,
                FirstName: "Andi",
                LastName: "Flower",
                Title: "Professor Grade 03",
                Phone: "0442216170",
                Email: "andie@w3c.com",
                My_External_Id__c: "203"
            }
        ];

    //create job
    error|BulkJob updateJob = bulkClient->creatJob("update", "Contact", "JSON");

    if (updateJob is BulkJob) {
        //add json content
        error|BatchInfo batch = updateJob->addBatch(<@untainted>contacts);
        if (batch is BatchInfo) {
            test:assertTrue(batch.id.length() > 0, msg = "Could not upload the contacts using json.");
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
        if (batchRequest is json) {
            json[]|error batchRequestArr = <json[]>batchRequest;
            if (batchRequestArr is json[]) {
                test:assertTrue(batchRequestArr.length() == 2, msg = "Retrieving batch request failed.");
            } else {
                test:assertFail(msg = batchRequestArr.toString());
            }
        } else if (batchRequest is error) {
            test:assertFail(msg = batchRequest.message());
        } else {
            test:assertFail(msg = "Invalid Batch Request!");
        }

        //get batch result
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
