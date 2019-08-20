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

@test:Config {
    dependsOn: ["testCsvUpdateOperator"]
}
function testCsvDeleteOperator() {
    log:printInfo("salesforceBulkClient -> CsvDeleteOperator");
    
    // Create csv delete operator.
    CsvDeleteOperator|SalesforceError csvDeleteOperator = sfBulkClient->createCsvDeleteOperator("Contact");
    // Get contacts to be deleted.
    string deleteContacts = getDeleteContactsAsText();

    if (csvDeleteOperator is CsvDeleteOperator) {
        string batchId = EMPTY_STRING;

        // Create csv delete batch.
        Batch|SalesforceError batch = csvDeleteOperator->upload(<@untainted> deleteContacts);
        if (batch is Batch) {
            test:assertTrue(batch.id.length() > 0, msg = "Creating query batch failed.");
            batchId = batch.id;
        } else {
            test:assertFail(msg = batch.message);
        }

        // Get job information.
        Job|SalesforceError jobInfo = csvDeleteOperator->getJobInfo();
        if (jobInfo is Job) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = jobInfo.message);
        }

        // Close job.
        Job|SalesforceError closedJob = csvDeleteOperator->closeJob();
        if (closedJob is Job) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.message);
        }

        // Get batch information.
        Batch|SalesforceError batchInfo = csvDeleteOperator->getBatchInfo(batchId);
        if (batchInfo is Batch) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.message);
        }

        // Get informations of all batches of this job.
        BatchInfo|SalesforceError allBatchInfo = csvDeleteOperator->getAllBatches();
        if (allBatchInfo is BatchInfo) {
            test:assertTrue(allBatchInfo.batchInfoList.length() == 1, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = allBatchInfo.message);
        }

        // Get the batch request.
        string|SalesforceError batchRequest = csvDeleteOperator->getBatchRequest(batchId);
        if (batchRequest is string) {
            test:assertTrue(batchRequest.length() > 0, msg = "Getting batch request failed.");
        } else {
            test:assertFail(msg = batchRequest.message);
        }

        // Get batch results.
        string|SalesforceError batchResults = csvDeleteOperator->getBatchResults(batchId, noOfRetries);
        if (batchResults is string) {
            test:assertTrue(batchResults.length() > 0, msg = "Getting batch results failed.");
            test:assertTrue(checkCsvBatchResult(batchResults), "Delete result was not successful.");
        } else {
            test:assertFail(msg = batchResults.message);
        }

        // Abort job.
        Job|SalesforceError abortedJob = csvDeleteOperator->abortJob();
        if (abortedJob is Job) {
            test:assertTrue(abortedJob.state == "Aborted", msg = "Aborting job failed.");
        } else {
            test:assertFail(msg = abortedJob.message);
        }
    } else {
        test:assertFail(msg = csvDeleteOperator.message);
    }
}
