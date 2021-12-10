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

import ballerina/io;
import ballerina/log;
import ballerina/test;
import ballerina/lang.runtime;

const int maxIterations = 5;
const decimal delayInSecs = 5.0;

@test:Config {
    enable: true
}
function insertCsv() returns error? {
    log:printInfo("baseClient -> insertCsv");
    string batchId = "";
    string contacts = "description,FirstName,LastName,Title,Phone,Email,My_External_Id__c\n"
        + "Created_from_Ballerina_Sf_Bulk_API,Cuthbert,Binns,Professor Level 02,0332236677,john434@gmail.com,845\n"
        + "Created_from_Ballerina_Sf_Bulk_API,Burbage,Shane,Professor Level 02,0332211777,peter77@gmail.com,846";

    //create job
    BulkJob insertJob = check baseClient->createJob("insert", "Contact", "CSV");

    //add csv content
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo batch = baseClient->addBatch(insertJob, contacts);
        if (batch is BatchInfo) {
            test:assertTrue(batch.id.length() > 0, msg = "Could not upload the contacts using CSV.");
            batchId = batch.id;
            break;
        } else {
            if currentRetry != maxIterations {
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
        error|JobInfo jobInfo = baseClient->getJobInfo(insertJob);
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
        error|BatchInfo batchInfo = baseClient->getBatchInfo(insertJob, batchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
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
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo[] batchInfoList = baseClient->getAllBatches(insertJob);
        if (batchInfoList is BatchInfo[]) {
            test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
            break;
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
        var batchRequest = baseClient->getBatchRequest(insertJob, batchId);
        if (batchRequest is string) {
            test:assertTrue(checkCsvResult(batchRequest) == 2, msg = "Retrieving batch request failed.");
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
        var batchResult = baseClient->getBatchResult(insertJob, batchId);
        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
            foreach var item in batchResult {
                json|error itemId = item?.id;
                if (itemId is json) {
                    string id = itemId.toString();
                    csvInputResult = csvInputResult + "\n" + id;
                }
                test:assertTrue(checkBatchResults(item), msg = item?.errors.toString());
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
        error|JobInfo closedJob = baseClient->closeJob(insertJob);
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

@test:Config {
    enable: true
}
function insertCsvFromFile() {
    log:printInfo("baseClient -> insertCsvFromFile");
    string batchId = "";

    string csvContactsFilePath = "sfdc/modules/bulk/tests/resources/contacts.csv";

    //create job
    error|BulkJob insertJob = baseClient->createJob("insert", "Contact", "CSV");

    if (insertJob is BulkJob) {
        //add csv content via file
        io:ReadableByteChannel|io:Error rbc = io:openReadableFile(csvContactsFilePath);
        if (rbc is io:ReadableByteChannel) {
            foreach int currentRetry in 1 ..< maxIterations + 1 {
                error|BatchInfo batchUsingCsvFile = baseClient->addBatch(insertJob, rbc);
                if (batchUsingCsvFile is BatchInfo) {
                    test:assertTrue(batchUsingCsvFile.id.length() > 0, 
                    msg = "Could not upload the contacts using CSV file.");
                    batchId = batchUsingCsvFile.id;
                    break;
                } else {
                    if currentRetry != maxIterations {
                        log:printWarn("addBatch Operation Failed! Retrying...");
                        runtime:sleep(delayInSecs);
                    } else {
                        log:printWarn("addBatch Operation Failed! Giving up after 5 tries.");
                        test:assertFail(msg = batchUsingCsvFile.message());
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
            error|JobInfo jobInfo = baseClient->getJobInfo(insertJob);
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
            error|BatchInfo batchInfo = baseClient->getBatchInfo(insertJob, batchId);
            if (batchInfo is BatchInfo) {
                test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
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
            error|BatchInfo[] batchInfoList = baseClient->getAllBatches(insertJob);
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
            var batchRequest = baseClient->getBatchRequest(insertJob, batchId);
            if (batchRequest is string) {
                test:assertTrue(checkCsvResult(batchRequest) == 2, msg = "Retrieving batch request failed.");
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
            var batchResult = baseClient->getBatchResult(insertJob, batchId);
            if (batchResult is Result[]) {
                foreach var item in batchResult {
                    json|error itemId = item?.id;
                    if (itemId is json) {
                        string id = itemId.toString();
                        csvInputResult = csvInputResult + "\n" + id;
                    }
                    test:assertTrue(checkBatchResults(item), msg = item?.errors.toString());
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
