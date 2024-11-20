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

import ballerina/log;
import ballerina/test;
import ballerina/lang.runtime;

@test:Config {
    enable: true,
    dependsOn: [insertCsvFromFile, insertCsv, insertCsvStringArrayFromFile, insertCsvStreamFromFile]
}
function queryCsv() returns error? {
    runtime:sleep(delayInSecs);
    log:printInfo("baseClient -> queryCsv");
    string queryStr = "SELECT Id, Name FROM Contact WHERE Title='Professor Level 02'";

    BulkCreatePayload payloadq = {
        operation : "query",
        query : queryStr
    };

    //create job
    BulkJob queryJob = check baseClient->createQueryJob(payloadq);

    //get batch result
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        string[][]|error batchResult = baseClient->getQueryResult(queryJob.id);
        if batchResult is string[][] {
            if batchResult.length() == 7 {
                test:assertTrue(batchResult.length() == 7, msg = "Retrieving batch result failed.");
                break;
            } else {
                if currentRetry != maxIterations {
                    log:printWarn("getBatchResult Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("getBatchResult Operation Failed! Giving up after 5 tries.");
                    test:assertFail(msg = batchResult.toString());
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
        }
    }
}


@test:Config {
    enable: true,
    dependsOn: [insertCsvFromFile, insertCsv, insertCsvStringArrayFromFile, insertCsvStreamFromFile]
}
function queryWithLowerMaxRecordsValue() returns error? {
    runtime:sleep(delayInSecs);
    log:printInfo("baseClient -> queryCsv");
    string queryStr = "SELECT Id, Name FROM Contact WHERE Title='Professor Level 02'";

    BulkCreatePayload payloadq = {
        operation : "query",
        query : queryStr
    };

    //create job
    BulkJob queryJob = check baseClient->createQueryJob(payloadq);
    int totalRecordsReceived = 0;
    int totalIterationsOfGetResult = 0;
    string[][]|error batchResult = [];

    //get batch result
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        while true {
            batchResult = baseClient->getQueryResult(queryJob.id, 5);
            if batchResult is error || batchResult.length() == 0 {
                break;
            } else {
                totalRecordsReceived += batchResult.length();
                totalIterationsOfGetResult += 1;
            }
        }
        
        if totalIterationsOfGetResult != 0 {
            if totalRecordsReceived == 7 {
                test:assertTrue(totalIterationsOfGetResult == 2, msg = "Retrieving batch result failed.");
                break;
            } else {
                if currentRetry != maxIterations {
                    log:printWarn("getBatchResult Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("getBatchResult Operation Failed! Giving up after 5 tries.");
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
        }
    }
}


@test:Config {
    enable: true,
    dependsOn: [insertCsvFromFile, insertCsv, insertCsvStringArrayFromFile, insertCsvStreamFromFile]
}
function queryWithHigherMaxRecordsValue() returns error? {
    runtime:sleep(delayInSecs);
    log:printInfo("baseClient -> queryCsv");
    string queryStr = "SELECT Id, Name FROM Contact WHERE Title='Professor Level 02'";

    BulkCreatePayload payloadq = {
        operation : "query",
        query : queryStr
    };

    //create job
    BulkJob queryJob = check baseClient->createQueryJob(payloadq);
    int totalRecordsReceived = 0;
    int totalIterationsOfGetResult = 0;
    string[][]|error batchResult = [];

    //get batch result
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        while true {
            batchResult = baseClient->getQueryResult(queryJob.id, 10);
            if batchResult is error || batchResult.length() == 0 {
                break;
            } else {
                totalRecordsReceived += batchResult.length();
                totalIterationsOfGetResult += 1;
            }
        }
        
        if totalIterationsOfGetResult != 0 {
            if totalRecordsReceived == 7 {
                test:assertTrue(totalIterationsOfGetResult == 1, msg = "Retrieving batch result failed.");
                break;
            } else {
                if currentRetry != maxIterations {
                    log:printWarn("getBatchResult Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("getBatchResult Operation Failed! Giving up after 5 tries.");
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
        }
    }
}

@test:Config {
    enable: true,
    dependsOn: [insertCsvFromFile, insertCsv, insertCsvStringArrayFromFile, insertCsvStreamFromFile]
}
function queryAndWaitCsv() returns error? {
    runtime:sleep(delayInSecs);
    log:printInfo("baseClient -> queryCsvWithWait");
    string queryStr = "SELECT Id, Name FROM Contact WHERE Title='Professor Level 03'";

    BulkCreatePayload payloadq = {
        operation : "query",
        query : queryStr
    };

    //create job
    future<BulkJobInfo|error> queryJob = check baseClient->createQueryJobAndWait(payloadq);
    BulkJobInfo bulkJobInfo = check wait queryJob;

    //get batch result
    string[][]|error batchResult = baseClient->getQueryResult(bulkJobInfo.id);
    if batchResult is string[][] {
        if batchResult.length() == 7 {
            test:assertTrue(batchResult.length() == 7, msg = "Retrieving batch result failed.");
        }
    } else if batchResult is error {
        log:printWarn("getBatchResult Operation Failed!");
        test:assertFail(msg = batchResult.message());
    }    

}
