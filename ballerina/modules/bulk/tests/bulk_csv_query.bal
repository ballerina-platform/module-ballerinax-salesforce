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
    dependsOn: [updateCsv, insertCsvFromFile, insertCsv, insertCsvStringArrayFromFile, insertCsvStreamFromFile]
}
function queryCsv() returns error? {
    runtime:sleep(delayInSecs);
    log:printInfo("baseClient -> queryCsv");
    string batchId = "";
    string queryStr = "SELECT Id, Name FROM Contact WHERE Title='Professor Level 02'";

    //create job
    BulkJob queryJob = check baseClient->createJob("query", "Contact", "CSV");

    //add query string
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo batch = baseClient->addBatch(queryJob, queryStr);
        if batch is BatchInfo {
            test:assertTrue(batch.id.length() > 0, msg = "Could not add batch.");
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
        error|JobInfo jobInfo = baseClient->getJobInfo(queryJob);
        if jobInfo is JobInfo {
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
        error|BatchInfo batchInfo = baseClient->getBatchInfo(queryJob, batchId);
        if batchInfo is BatchInfo {
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
        error|BatchInfo[] batchInfoList = baseClient->getAllBatches(queryJob);
        if batchInfoList is BatchInfo[] {
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
        error|json|xml|string batchRequest = baseClient->getBatchRequest(queryJob, batchId);
        if batchRequest is string {
            test:assertTrue(batchRequest.startsWith("SELECT"), msg = "Retrieving batch request failed.");
            break;
        } else if batchRequest is error {
            if currentRetry != maxIterations {
                log:printWarn("getBatchRequest Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchRequest Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchRequest.message());
            }
        } else {
            test:assertFail(msg = "Invalid Batch Request!");
        }
    }

    //get batch result
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|json|xml|string|Result[] batchResult = baseClient->getBatchResult(queryJob, batchId);
        if batchResult is string {
            if checkCsvResult(batchResult) == 7 {
                test:assertTrue(checkCsvResult(batchResult) == 7, msg = "Retrieving batch result failed.");
                break;
            } else {
                if currentRetry != maxIterations {
                    log:printWarn("getBatchResult Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("getBatchResult Operation Failed! Giving up after 5 tries.");
                    test:assertFail(msg = batchResult);
                }
            }
        } else if batchResult is error {
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
    error|JobInfo closedJob = baseClient->closeJob(queryJob);
    if closedJob is JobInfo {
        test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
    } else {
        test:assertFail(msg = closedJob.message());
    }
}
