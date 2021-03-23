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
//
import ballerina/io;
import ballerina/log;
import ballerina/test;
import ballerina/lang.runtime;

@test:Config {}
function insertCsv() {
   log:printInfo("baseClient -> insertCsv");
    string batchId = "";

    string contacts = 
    "description,FirstName,LastName,Title,Phone,Email,My_External_Id__c\n" + "Created_from_Ballerina_Sf_Bulk_API,Cuthbert,Binns,Professor Level 02,0332236677,john434@gmail.com,845\n" + "Created_from_Ballerina_Sf_Bulk_API,Burbage,Shane,Professor Level 02,0332211777,peter77@gmail.com,846";

    //create job
    error|BulkJob insertJob = baseClient->creatJob("insert", "Contact", "CSV");

    if (insertJob is BulkJob) {
        //add csv content
        error|BatchInfo batch = baseClient->addBatch(insertJob, contacts);
        if (batch is BatchInfo) {
            test:assertTrue(batch.id.length() > 0, msg = "Could not upload the contacts using CSV.");
            batchId = batch.id;
        } else {
            test:assertFail(msg = batch.message());
        }

        //get job info
        error|JobInfo jobInfo = baseClient->getJobInfo(insertJob);
        if (jobInfo is JobInfo) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = jobInfo.message());
        }

        //get batch info
        error|BatchInfo batchInfo = baseClient->getBatchInfo(insertJob, batchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.message());
        }

        //get all batches
        error|BatchInfo[] batchInfoList = baseClient->getAllBatches(insertJob);
        if (batchInfoList is BatchInfo[]) {
            test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = batchInfoList.message());
        }

        //get batch request
        var batchRequest = baseClient->getBatchRequest(insertJob, batchId);
        if (batchRequest is string) {
            test:assertTrue(checkCsvResult(batchRequest) == 2, msg = "Retrieving batch request failed.");
        } else if (batchRequest is error) {
            test:assertFail(msg = batchRequest.message());
        } else {
            test:assertFail(msg = "Invalid Batch Request!");
        }

        runtime:sleep(3.0);
        var batchResult = baseClient->getBatchResult(insertJob, batchId);
        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
            test:assertTrue(checkBatchResults(batchResult), msg = "Insert was not successful.");
        } else if (batchResult is error) {
            test:assertFail(msg = batchResult.message());
        } else {
            test:assertFail("Invalid Batch Result!");
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

@test:Config {}
function insertCsvFromFile() {
    log:printInfo("baseClient -> insertCsvFromFile");
    string batchId = "";

    string csvContactsFilePath = "sfdc/tests/resources/contacts.csv";

    //create job
    error|BulkJob insertJob = baseClient->creatJob("insert", "Contact", "CSV");

    if (insertJob is BulkJob) {
        //add csv content via file
        io:ReadableByteChannel|io:Error rbc = io:openReadableFile(csvContactsFilePath);
        if (rbc is io:ReadableByteChannel) {
            error|BatchInfo batchUsingXmlFile = baseClient->addBatch(insertJob, <@untainted>rbc);
            if (batchUsingXmlFile is BatchInfo) {

                test:assertTrue(batchUsingXmlFile.id.length() > 0, msg = "Could not upload the contacts using CSV file.");
                batchId = batchUsingXmlFile.id;
            } else {
                test:assertFail(msg = batchUsingXmlFile.message());
            }
            // close channel.
            closeRb(rbc);
        } else {
            test:assertFail(msg = rbc.message());
        }

        //get job info
        error|JobInfo jobInfo = baseClient->getJobInfo(insertJob);
        if (jobInfo is JobInfo) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = jobInfo.message());
        }

        //get batch info
        error|BatchInfo batchInfo = baseClient->getBatchInfo(insertJob, batchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.message());
        }

        //get all batches
        error|BatchInfo[] batchInfoList = baseClient->getAllBatches(insertJob);
        if (batchInfoList is BatchInfo[]) {
            test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = batchInfoList.message());
        }

        //get batch request
        var batchRequest = baseClient->getBatchRequest(insertJob, batchId);
        if (batchRequest is string) {
            test:assertTrue(checkCsvResult(batchRequest) == 2, msg = "Retrieving batch request failed.");
        } else if (batchRequest is error) {
            test:assertFail(msg = batchRequest.message());
        } else {
            test:assertFail(msg = "Invalid Batch Request!");
        }

        runtime:sleep(3.0);
        var batchResult = baseClient->getBatchResult(insertJob, batchId);
        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
            test:assertTrue(checkBatchResults(batchResult), msg = "Insert was not successful.");
        } else if (batchResult is error) {
            test:assertFail(msg = batchResult.message());
        } else {
            test:assertFail("Invalid Batch Result!");
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
