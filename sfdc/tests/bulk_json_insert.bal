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
function insertJson() {
    log:printInfo("baseClient -> insertJson");
    string batchId = "";

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
    error|BulkJob insertJob = baseClient->creatJob("insert", "Contact", "JSON");

    if (insertJob is BulkJob) {
        //add json content
        foreach var i in 1 ..< maxIterations {
            error|BatchInfo batch = baseClient->addBatch(insertJob, contacts);
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
        foreach var i in 1 ..< maxIterations {
            error|JobInfo jobInfo = baseClient->getJobInfo(insertJob);
            if (jobInfo is JobInfo) {
                test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
                break;
            } else {
                if i != 5 {
                    log:printWarn("getJobInfo Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("getJobInfo Operation Failed! Giving up...");
                    test:assertFail(msg = jobInfo.message());
                }
            }
        }

        //get batch info
        foreach var i in 1 ..< maxIterations {
            error|BatchInfo batchInfo = baseClient->getBatchInfo(insertJob, batchId);
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
        foreach var i in 1 ..< 3 {
            error|BatchInfo[] batchInfoList = baseClient->getAllBatches(insertJob);
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
        foreach var i in 1 ..< maxIterations {
            var batchRequest = baseClient->getBatchRequest(insertJob, batchId);
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
                break;
            }
        }
        
        foreach var i in 1 ..< maxIterations {
            var batchResult = baseClient->getBatchResult(insertJob, batchId);
            if (batchResult is Result[]) {
                test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
                test:assertTrue(checkBatchResults(batchResult), msg = "Insert was not successful.");
                break;
            } else if (batchResult is error) {
                if i != 5 {
                    log:printWarn("getBatchResult Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("getBatchResult Operation Failed! Giving up...");
                    test:assertFail(msg = batchResult.message());
                }
            } else {
                test:assertFail("Invalid Batch Result!");
                break;
            }
        }
        
        //close job
        foreach var i in 1 ..< maxIterations {
            error|JobInfo closedJob = baseClient->closeJob(insertJob);
            if (closedJob is JobInfo) {
                test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
                break;
            } else {
                if i != 5 {
                    log:printWarn("closeJob Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("closeJob Operation Failed! Giving up...");
                    test:assertFail(msg = closedJob.message());
                }
            }
        }
    } else {
        test:assertFail(msg = insertJob.message());
    }
}

@test:Config {
    enable: true
}
function insertJsonFromFile() {
    log:printInfo("baseClient -> insertJsonFromFile");
    string batchId = "";
    string jsonContactsFilePath = "sfdc/tests/resources/contacts.json";

    //create job
    error|BulkJob insertJob = baseClient->creatJob("insert", "Contact", "JSON");

    if (insertJob is BulkJob) {
        //add json content
        io:ReadableByteChannel|io:Error rbc = io:openReadableFile(jsonContactsFilePath);
        if (rbc is io:ReadableByteChannel) {
            foreach var i in 1 ..< maxIterations {
                error|BatchInfo batchUsingJsonFile = baseClient->addBatch(insertJob, <@untainted>rbc);
                if (batchUsingJsonFile is BatchInfo) {
                    test:assertTrue(batchUsingJsonFile.id.length() > 0, msg = "Could not upload the contacts using json file.");
                    batchId = batchUsingJsonFile.id;
                    break;
                } else {
                    if i != 5 {
                        log:printWarn("addBatch Operation Failed! Retrying...");
                        runtime:sleep(delayInSecs);
                    } else {
                        log:printWarn("addBatch Operation Failed! Giving up...");
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
        foreach var i in 1 ..< maxIterations {
            error|JobInfo jobInfo = baseClient->getJobInfo(insertJob);
            if (jobInfo is JobInfo) {
                test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
            } else {
                if i != 5 {
                    log:printWarn("getJobInfo Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("getJobInfo Operation Failed! Giving up...");
                    test:assertFail(msg = jobInfo.message());
                }
            }
        }

        //get batch info
        foreach var i in 1 ..< maxIterations {
            error|BatchInfo batchInfo = baseClient->getBatchInfo(insertJob, batchId);
            if (batchInfo is BatchInfo) {
                test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
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
            error|BatchInfo[] batchInfoList = baseClient->getAllBatches(insertJob);
            if (batchInfoList is BatchInfo[]) {
                test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
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
            var batchRequest = baseClient->getBatchRequest(insertJob, batchId);
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
                break;
            }
        }

        foreach var i in 1 ..< maxIterations {
            var batchResult = baseClient->getBatchResult(insertJob, batchId);
            if (batchResult is Result[]) {
                test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
                test:assertTrue(checkBatchResults(batchResult), msg = "Insert was not successful.");
                break;
            } else if (batchResult is error) {
                if i != 5 {
                    log:printWarn("getBatchResult Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("getBatchResult Operation Failed! Giving up...");
                    test:assertFail(msg = batchResult.message());
                }
            } else {
                test:assertFail("Invalid Batch Result!");
            }
        }

        //close job
        error|JobInfo closedJob = baseClient->closeJob(insertJob);
        if (closedJob is JobInfo) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.message());
        }
    } else {
        test:assertFail(msg = insertJob.message());
    }
}
