// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
    dependsOn: ["testCsvUpdateOperator"]
}
function testCsvDeleteOperator() {
    log:printInfo("salesforceBulkClient -> CsvDeleteOperator");
    
    // Create csv delete operator.
    CsvDeleteOperator|ConnectorError csvDeleteOperator = sfBulkClient->createCsvDeleteOperator("Contact");
    // Get contacts to be deleted.
    string deleteContacts = getDeleteContactsAsText();

    if (csvDeleteOperator is CsvDeleteOperator) {
        string batchId = EMPTY_STRING;

        // Create csv delete batch.
        BatchInfo|ConnectorError batch = csvDeleteOperator->delete(<@untainted> deleteContacts);
        if (batch is BatchInfo) {
            test:assertTrue(batch.id.length() > 0, msg = "Creating query batch failed.");
            batchId = batch.id;
        } else {
            test:assertFail(msg = batch.detail()?.message.toString());
        }

        // Get job information.
        JobInfo|ConnectorError jobInfo = csvDeleteOperator->getJobInfo();
        if (jobInfo is JobInfo) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = jobInfo.detail()?.message.toString());
        }

        // Close job.
        JobInfo|ConnectorError closedJob = csvDeleteOperator->closeJob();
        if (closedJob is JobInfo) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.detail()?.message.toString());
        }

        // Get batch information.
        BatchInfo|ConnectorError batchInfo = csvDeleteOperator->getBatchInfo(batchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.detail()?.message.toString());
        }

        // Get informations of all batches of this job.
        BatchInfo[]|ConnectorError allBatchInfo = csvDeleteOperator->getAllBatches();
        if (allBatchInfo is BatchInfo[]) {
            test:assertTrue(allBatchInfo.length() == 1, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = allBatchInfo.detail()?.message.toString());
        }

        // Get the batch request.
        string|ConnectorError batchRequest = csvDeleteOperator->getBatchRequest(batchId);
        if (batchRequest is string) {
            test:assertTrue(batchRequest.length() > 0, msg = "Getting batch request failed.");
        } else {
            test:assertFail(msg = batchRequest.detail()?.message.toString());
        }

        // Get batch results.
        Result[]|ConnectorError batchResults = csvDeleteOperator->getResult(batchId, noOfRetries);
        if (batchResults is Result[]) {
            test:assertTrue(batchResults.length() > 0, msg = "Getting batch results failed.");
            test:assertTrue(checkBatchResults(batchResults), "Delete result was not successful.");
        } else {
            test:assertFail(msg = batchResults.detail()?.message.toString());
        }

        // Abort job.
        JobInfo|ConnectorError abortedJob = csvDeleteOperator->abortJob();
        if (abortedJob is JobInfo) {
            test:assertTrue(abortedJob.state == "Aborted", msg = "Aborting job failed.");
        } else {
            test:assertFail(msg = abortedJob.detail()?.message.toString());
        }
    } else {
        test:assertFail(msg = csvDeleteOperator.detail()?.message.toString());
    }
}
