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
//under the License.

import ballerina/io;
import ballerina/log;
import ballerina/test;
import ballerina/lang.runtime;

@test:Config {
    enable: true
}
function insertJson() returns error? {
    log:printInfo("baseClient -> insertJson");
    string jsonBatchId = "";

    json contacts = [{
        description: "Created_from_Ballerina_Sf_Bulk_API",
        FirstName: "Remus",
        LastName: "Lupin",
        Title: "Professor Level 03",
        Phone: "0442226670",
        Email: "lupinWolf@gmail.com",
        My_External_Id__c: "848"
    }, {
        description: "Created_from_Ballerina_Sf_Bulk_API",
        FirstName: "Minerva",
        LastName: "McGonagall",
        Title: "Professor Level 03",
        Phone: "0442216170",
        Email: "minerva@gmail.com",
        My_External_Id__c: "849"
    }];

    //create job
    BulkJob jsonInsertJob = check baseClient->createJob("insert", "Contact", "JSON");

    //add json content
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo batch = baseClient->addBatch(jsonInsertJob, contacts);
        if (batch is BatchInfo) {
            test:assertTrue(batch.id.length() > 0, msg = "Could not upload the contacts using json.");
            jsonBatchId = batch.id;
            break;
        } else {
            if currentRetry != 5 {
                log:printWarn("addBatch Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("addBatch Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batch.message());
            }
        }
    }

    //get job info
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|JobInfo jobInfo = baseClient->getJobInfo(jsonInsertJob);

        if (jobInfo is JobInfo) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
            break;
        } else {
            if currentRetry != maxIterations {
                log:printWarn("getJobInfo Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getJobInfo Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = jobInfo.message());
            }
        }
    }

    //get batch info
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo batchInfo = baseClient->getBatchInfo(jsonInsertJob, jsonBatchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == jsonBatchId, msg = "Getting batch info failed.");
            break;
        } else {
            if currentRetry != maxIterations {
                log:printWarn("getBatchInfo Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchInfo Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchInfo.message());
            }
        }
    }

    //get all batches
    foreach var i in 1 ..< 3 {
        error|BatchInfo[] batchInfoList = baseClient->getAllBatches(jsonInsertJob);
        if (batchInfoList is BatchInfo[]) {
            test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
            break;
        } else {
            if i == 2 {
                test:assertFail(msg = batchInfoList.message());
            } else {
                log:printInfo("Batch Operation Failed! Retrying...");
                runtime:sleep(5.0);
            }
        }
    }

    //get batch request
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        var batchRequest = baseClient->getBatchRequest(jsonInsertJob, jsonBatchId);
        if (batchRequest is json) {
            json[]|error batchRequestArr = <json[]>batchRequest;
            if (batchRequestArr is json[]) {
                test:assertTrue(batchRequestArr.length() == 2, msg = "Retrieving batch request failed.");
            } else {
                test:assertFail(msg = batchRequestArr.toString());
            }
            break;
        } else if (batchRequest is error) {
            if currentRetry != maxIterations {
                log:printWarn("getBatchRequest Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchRequest Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchRequest.message());
            }
        } else {
            test:assertFail(msg = "Invalid Batch Request!");
            break;
        }
    }

    foreach int currentRetry in 1 ..< maxIterations + 1 {
        var batchResult = baseClient->getBatchResult(jsonInsertJob, jsonBatchId);
        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
            foreach json res in batchResult {
                jsonInsertResult.push(res);
                test:assertTrue(checkBatchResults(res), msg = res?.errors.toString());
            }
            break;
        } else if (batchResult is error) {
            if currentRetry != maxIterations {
                log:printWarn("getBatchResult Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchResult Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchResult.message());
            }
        } else {
            test:assertFail("Invalid Batch Result!");
            break;
        }
    }

    //close job
    foreach int currentRetry in 1 ..< maxIterations + 1 {

        error|JobInfo closedJob = baseClient->closeJob(jsonInsertJob);
        if (closedJob is JobInfo) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
            break;
        } else {
            if currentRetry != maxIterations {
                log:printWarn("closeJob Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("closeJob Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = closedJob.message());
            }
        }
    }
}

@test:Config {enable: true}
function insertJsonFromFile() returns error? {
    log:printInfo("baseClient -> insertJsonFromFile");
    string jsonBatchId = "";
    string jsonContactsFilePath = "sfdc/modules/bulk/tests/resources/contacts.json";

    //create job
    BulkJob jsonInsertJob = check baseClient->createJob("insert", "Contact", "JSON");

    //add json content
    io:ReadableByteChannel|io:Error rbc = io:openReadableFile(jsonContactsFilePath);
    if (rbc is io:ReadableByteChannel) {
        foreach int currentRetry in 1 ..< maxIterations + 1 {
            error|BatchInfo batchUsingJsonFile = baseClient->addBatch(jsonInsertJob, rbc);
            if (batchUsingJsonFile is BatchInfo) {
                test:assertTrue(batchUsingJsonFile.id.length() > 0, 
                    msg = "Could not upload the contacts using json file.");
                jsonBatchId = batchUsingJsonFile.id;
                break;
            } else {
                if currentRetry != maxIterations {
                    log:printWarn("addBatch Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("addBatch Operation Failed! Giving up after 5 tries.");
                    test:assertFail(msg = batchUsingJsonFile.message());
                }
            }
        }
        // close channel.
        closeRb(rbc);
    } else {
        test:assertFail(msg = rbc.message());
    }

    //get job info
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|JobInfo jobInfo = baseClient->getJobInfo(jsonInsertJob);
        if (jobInfo is JobInfo) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            if currentRetry != maxIterations {
                log:printWarn("getJobInfo Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getJobInfo Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = jobInfo.message());
            }
        }
    }

    //get batch info
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo batchInfo = baseClient->getBatchInfo(jsonInsertJob, jsonBatchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == jsonBatchId, msg = "Getting batch info failed.");
        } else {
            if currentRetry != maxIterations {
                log:printWarn("getBatchInfo Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchInfo Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchInfo.message());
            }
        }
    }

    //get all batches
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo[] batchInfoList = baseClient->getAllBatches(jsonInsertJob);
        if (batchInfoList is BatchInfo[]) {
            test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
        } else {
            if currentRetry != maxIterations {
                log:printWarn("getAllBatches Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getAllBatches Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchInfoList.message());
            }
        }
    }

    //get batch request
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        var batchRequest = baseClient->getBatchRequest(jsonInsertJob, jsonBatchId);
        if (batchRequest is json) {
            json[]|error batchRequestArr = <json[]>batchRequest;
            if (batchRequestArr is json[]) {
                test:assertTrue(batchRequestArr.length() == 2, msg = "Retrieving batch request failed.");
            } else {
                test:assertFail(msg = batchRequestArr.toString());
            }
            break;
        } else if (batchRequest is error) {
            if currentRetry != maxIterations {
                log:printWarn("getBatchRequest Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchRequest Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchRequest.message());
            }
        } else {
            test:assertFail(msg = "Invalid Batch Request!");
            break;
        }
    }

    foreach int currentRetry in 1 ..< maxIterations + 1 {
        var batchResult = baseClient->getBatchResult(jsonInsertJob, jsonBatchId);
        if (batchResult is Result[]) {
            foreach json res in batchResult {
                jsonInsertResult.push(res);
            }
            test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
            break;
        } else if (batchResult is error) {
            if currentRetry != maxIterations {
                log:printWarn("getBatchResult Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchResult Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchResult.message());
            }
        } else {
            test:assertFail("Invalid Batch Result!");
        }
    }

    //close job
    JobInfo closedJob = check baseClient->closeJob(jsonInsertJob);
    test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
}
