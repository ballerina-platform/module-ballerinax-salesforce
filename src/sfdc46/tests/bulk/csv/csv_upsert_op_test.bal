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
    dependsOn: ["testCsvQueryOperator"]
}
function testCsvUpsertOperator() {
    log:printInfo("salesforceBulkClient -> CsvUpsertOperator");

    string contacts = "description,FirstName,LastName,Title,Phone,Email,My_External_Id__c
Created_from_Ballerina_Sf_Bulk_API,John,Michael,Professor Grade 04,0332236677,john.michael@gmail.com,301
Created_from_Ballerina_Sf_Bulk_API,Pedro,Guterez,Professor Grade 04,0445567100,pedro.gut@gmail.com,303";

    // Create JSON upsert operator.
    CsvUpsertOperator|SalesforceError csvUpsertOperator = 
        sfBulkClient->createCsvUpsertOperator("Contact", "My_External_Id__c");

    if (csvUpsertOperator is CsvUpsertOperator) {
        string batchId = EMPTY_STRING;

        // Upload the csv contacts.
        Batch|SalesforceError batch = csvUpsertOperator->upsert(contacts);
        if (batch is Batch) {
            test:assertTrue(batch.id.length() > 0, msg = "Could not upload the contacts using json.");
            batchId = batch.id;
        } else {
            test:assertFail(msg = batch.message);
        }

        // Get job information.
        Job|SalesforceError job = csvUpsertOperator->getJobInfo();
        if (job is Job) {
            test:assertTrue(job.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = job.message);
        }

        // Close job.
        Job|SalesforceError closedJob = csvUpsertOperator->closeJob();
        if (closedJob is Job) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.message);
        }

        // Get batch information.
        Batch|SalesforceError batchInfo = csvUpsertOperator->getBatchInfo(batchId);
        if (batchInfo is Batch) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.message);
        }

        // Get informations of all batches of this job.
        BatchInfo|SalesforceError allBatchInfo = csvUpsertOperator->getAllBatches();
        if (allBatchInfo is BatchInfo) {
            test:assertTrue(allBatchInfo.batchInfoList.length() > 0, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = allBatchInfo.message);
        }

        // Retrieve the csv batch request.
        string|SalesforceError batchRequest = csvUpsertOperator->getBatchRequest(batchId);
        if (batchRequest is string) {
            test:assertTrue(batchRequest.length() > 0, msg = "Retrieving batch request failed.");                
        } else {
            test:assertFail(msg = batchRequest.message);
        }

        // Get the results of the batch
        Result[]|SalesforceError batchResult = csvUpsertOperator->getBatchResults(batchId, noOfRetries);
        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Getting batch results failed.");
            test:assertTrue(checkBatchResults(batchResult), "Insert result was not successful.");
        } else {
            test:assertFail(msg = batchResult.message);
        }

        // Abort job.
        Job|SalesforceError abortedJob = csvUpsertOperator->abortJob();
        if (abortedJob is Job) {
            test:assertTrue(abortedJob.state == "Aborted", msg = "Aborting job failed.");
        } else {
            test:assertFail(msg = abortedJob.message);
        }
    } else {
        test:assertFail(msg = csvUpsertOperator.message);
    }
}
