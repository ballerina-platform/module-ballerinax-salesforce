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
import ballerina/lang.runtime;

@test:Config {
    enable: true,
    dependsOn: [insertJson]
}
function upsertJson() {
    log:printInfo("baseClient -> upsertJson");
    string batchId = "";
    json contacts = [{
        description: "Created_from_Ballerina_Sf_Bulk_API",
        FirstName: "Remus",
        LastName: "Lupin",
        Title: "Professor Level 03",
        Phone: "0552216170",
        Email: "lupin@gmail.com",
        My_External_Id__c: "848"
    }, {
        description: "Created_from_Ballerina_Sf_Bulk_API",
        FirstName: "Minerva",
        LastName: "McGonagall",
        Title: "Professor Level 03",
        Phone: "0113232445",
        Email: "minervas@gmail.com",
        My_External_Id__c: "849"
    }];

    //create job
    error|BulkJob upsertJob = baseClient->creatJob("upsert", "Contact", "JSON", "My_External_Id__c");

    if (upsertJob is BulkJob) {
        //add json content
        foreach var i in 1 ..< maxIterations {
            error|BatchInfo batch = baseClient->addBatch(upsertJob, contacts);
            if (batch is BatchInfo) {
                test:assertTrue(batch.id.length() > 0, msg = "Could not upload the contacts using json.");
                batchId = batch.id;
                break;
            } else {
                if i != 5 {
                    log:printWarn("addBatch Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("addBatch Operation Failed! Giving up...");
                    test:assertFail(msg = batch.message());
                }
            }
        }

        //get job info
        error|JobInfo jobInfo = baseClient->getJobInfo(upsertJob);
        if (jobInfo is JobInfo) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = jobInfo.message());
        }

        //get batch info
        foreach var i in 1 ..< maxIterations {
            error|BatchInfo batchInfo = baseClient->getBatchInfo(upsertJob, batchId);
            if (batchInfo is BatchInfo) {
                test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
                break;
            } else {
                if i != 5 {
                    log:printWarn("getBatchInfo Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("getBatchInfo Operation Failed! Giving up...");
                    test:assertFail(msg = batchInfo.message());
                }
            }
        }

        //get all batches
        foreach var i in 1 ..< maxIterations {
            error|BatchInfo[] batchInfoList = baseClient->getAllBatches(upsertJob);
            if (batchInfoList is BatchInfo[]) {
                test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
                break;
            } else {
                if i != 5 {
                    log:printWarn("getAllBatches Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("getAllBatches Operation Failed! Giving up...");
                    test:assertFail(msg = batchInfoList.message());
                }
            }
        }

        //get batch request
        foreach var i in 1 ..< maxIterations {
            var batchRequest = baseClient->getBatchRequest(upsertJob, batchId);
            if (batchRequest is json) {
                json[]|error batchRequestArr = <json[]>batchRequest;
                if (batchRequestArr is json[]) {
                    test:assertTrue(batchRequestArr.length() == 2, msg = "Retrieving batch request failed.");
                } else {
                    test:assertFail(msg = batchRequestArr.toString());
                }
                break;
            } else if (batchRequest is error) {
                if i != 5 {
                    log:printWarn("getBatchRequest Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("getBatchRequest Operation Failed! Giving up...");
                    test:assertFail(msg = batchRequest.message());
                }
            } else {
                test:assertFail(msg = "Invalid Batch Request!");
            }
        }

        //get batch result
        foreach var i in 1 ..< maxIterations {
            var batchResult = baseClient->getBatchResult(upsertJob, batchId);
            if (batchResult is Result[]) {
                test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
                test:assertTrue(checkBatchResults(batchResult), msg = "Upsert was not successful.");
                break;
            } else if (batchResult is error) {
                if i != 5 {
                    log:printWarn("getAllBatches Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("getAllBatches Operation Failed! Giving up...");
                    test:assertFail(msg = batchResult.message());
                }
            } else {
                test:assertFail("Invalid Batch Result!");
            }
        }

        //close job
        error|JobInfo closedJob = baseClient->closeJob(upsertJob);
        if (closedJob is JobInfo) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.message());
        }
    } else {
        test:assertFail(msg = upsertJob.message());
    }
}
