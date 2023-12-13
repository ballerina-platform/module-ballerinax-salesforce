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
public string insertJobId = "";

@test:Config {
    enable: true
}
function insertCsv() returns error? {
    log:printInfo("baseClient -> insertCsv");
    string batchId = "";
    string contacts = "description,FirstName,LastName,Title,Phone,Email,My_External_Id__c\n"
        + "Created_from_Ballerina_Sf_Bulk_API_V2,Cuthbert,Binns,Professor Level 02,0332236677,john434@gmail.com,845\n"
        + "Created_from_Ballerina_Sf_Bulk_API_V2,Burbage,Shane,Professor Level 02,0332211777,peter77@gmail.com,846";

    //create job
    BulkCreatePayload payload = {
        'object : "Account",
        contentType : "CSV",
        operation : "insert",
        lineEnding : "LF"
    };
    BulkJob insertJob = check baseClient->createJob(payload, INGEST);
    insertJobId = insertJob.id;

    //add csv content
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error? response = baseClient->addBatch(insertJob.id, contacts);
        if response is error {
            if currentRetry == maxIterations {
                log:printWarn("addBatch Operation Failed!");
                test:assertFail(msg = "Could not upload the contacts using CSV. " + response.message());
            } else {
                log:printWarn("addBatch Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            }
        } else {
            break;
        }
    }

    //get job info
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BulkJobInfo jobInfo = baseClient->getJobInfo(insertJob.id, INGEST);
        if jobInfo is BulkJobInfo {
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

    //close job
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        future<BulkJobInfo|error> closedJob = check baseClient->closeJob(insertJob.id);
        BulkJobInfo|error closedJobInfo = wait closedJob;
        if closedJobInfo is BulkJobInfo {
            test:assertTrue(closedJobInfo.state == "JobComplete", msg = "Closing job failed.");
            break;
        } else {
            test:assertFail(msg = closedJobInfo.message());
        }
    }
}

@test:Config {
    enable: true
}
function insertCsvFromFile() returns error? {
    log:printInfo("baseClient -> insertCsvFromFile");
    string batchId = "";

    string csvContactsFilePath = "ballerina/modules/bulk/tests/resources/contacts1.csv";

    //create job
    BulkCreatePayload payload = {
        'object : "Account",
        contentType : "CSV",
        operation : "insert",
        lineEnding : "LF"
    };
    error|BulkJob insertJob = baseClient->createJob(payload, INGEST);

    if insertJob is BulkJob {
        string[][] csvContent = check io:fileReadCsv(csvContactsFilePath);
        foreach int currentRetry in 1 ..< maxIterations + 1 {
            error? response = baseClient->addBatch(insertJob.id, csvContent);
            if response is error {
                test:assertFail(response.message());
            }
        }

        //get job info
        foreach int currentRetry in 1 ..< maxIterations + 1 {
            error|BulkJobInfo jobInfo = baseClient->getJobInfo(insertJob.id, INGEST);
            if jobInfo is BulkJobInfo {
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

        //close job
        future<BulkJobInfo|error> closedJob = check baseClient->closeJob(insertJob.id);
        BulkJobInfo|error closedJobInfo = wait closedJob;
        if closedJobInfo is BulkJobInfo {
            test:assertTrue(closedJobInfo.state == "JobComplete", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJobInfo.message());
        }

    } else {
        test:assertFail(msg = insertJob.message());
    }
}

@test:Config {
    enable: true
}
function insertCsvStringArrayFromFile() returns error? {
    log:printInfo("baseClient -> insertCsvStringArrayFromFile");
    string batchId = "";

    string csvContactsFilePath = "ballerina/modules/bulk/tests/resources/contacts2.csv";

    //create job
    BulkCreatePayload payload = {
        'object : "Account",
        contentType : "CSV",
        operation : "insert",
        lineEnding : "LF"
    };
    error|BulkJob insertJob = baseClient->createJob(payload, INGEST);

    if insertJob is BulkJob {
        io:ReadableByteChannel|io:Error rbc = io:openReadableFile(csvContactsFilePath);
        if rbc is io:ReadableByteChannel {
            foreach int currentRetry in 1 ..< maxIterations + 1 {
                error? response = baseClient->addBatch(insertJob.id, rbc);
                if response is error {
                    test:assertFail(response.message());
                }
            }
            // close channel.
                _ = check rbc.close();
        } else {
            test:assertFail(msg = rbc.message());
        }

        //get job info
        foreach int currentRetry in 1 ..< maxIterations + 1 {
            error|BulkJobInfo jobInfo = baseClient->getJobInfo(insertJob.id, INGEST);
            if jobInfo is BulkJobInfo {
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

        //close job
        future<BulkJobInfo|error> closedJob = check baseClient->closeJob(insertJob.id);
        BulkJobInfo|error closedJobInfo = wait closedJob;
        if closedJobInfo is BulkJobInfo {
            test:assertTrue(closedJobInfo.state == "JobComplete", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJobInfo.message());
        }

    } else {
        test:assertFail(msg = insertJob.message());
    }
    //create job
       
}

@test:Config {
    enable: true
}
function insertCsvStreamFromFile() returns error? {
    log:printInfo("baseClient -> insertCsvStreamFromFile");
    string batchId = "";

    string csvContactsFilePath = "ballerina/modules/bulk/tests/resources/contacts3.csv";

    stream<string[], io:Error?> csvStream = check io:fileReadCsvAsStream(csvContactsFilePath);
    //create job
    BulkCreatePayload payload = {
        'object : "Account",
        contentType : "CSV",
        operation : "insert",
        lineEnding : "LF"
    };
    BulkJob insertJob = check baseClient->createJob(payload, INGEST);

    //add csv content
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error? response = baseClient->addBatch(insertJob.id, csvStream);
        if response is error {
            if currentRetry == maxIterations {
                log:printWarn("addBatch Operation Failed!");
                test:assertFail(msg = "Could not upload the contacts using CSV. " + response.message());
            } else {
                log:printWarn("addBatch Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            }
        } else {
            break;
        }
    }

    //get job info
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BulkJobInfo jobInfo = baseClient->getJobInfo(insertJob.id, INGEST);
        if jobInfo is BulkJobInfo {
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

    //close job
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        future<BulkJobInfo|error> closedJob = check baseClient->closeJob(insertJob.id);
        BulkJobInfo|error closedJobInfo = wait closedJob;
        if closedJobInfo is BulkJobInfo {
            test:assertTrue(closedJobInfo.state == "JobComplete", msg = "Closing job failed.");
            break;
        } else {
            test:assertFail(msg = closedJobInfo.message());
        }
    }
}
