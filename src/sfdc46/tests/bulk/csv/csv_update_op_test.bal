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
    dependsOn: ["testCsvUpsertOperator"]
}
function testCsvUpdateOperator() {
    log:printInfo("salesforceBulkClient -> CsvUpdateOperator");

    string johnsID = getContactIdByName("John", "Michael", "Professor Grade 04");
    string pedrosID = getContactIdByName("Pedro", "Guterez", "Professor Grade 04");

    string contacts = "Id,description,FirstName,LastName,Title,Phone,Email,My_External_Id__c
" + johnsID + ",Created_from_Ballerina_Sf_Bulk_API,John,Michael,Professor Grade 04,0332236677,john.michael@gmail.com,301
" + pedrosID + ",Created_from_Ballerina_Sf_Bulk_API,Pedro,Guterez,Professor Grade 04,0445567100,pedro.gut@gmail.com,303";

    // Create JSON update operator.
    CsvUpdateOperator|ConnectorError csvUpdateOperator = sfBulkClient->createCsvUpdateOperator("Contact");

    if (csvUpdateOperator is CsvUpdateOperator) {
        string batchId = EMPTY_STRING;

        // Upload the csv contacts.
        BatchInfo|ConnectorError batch = csvUpdateOperator->update(<@untainted> contacts);
        if (batch is BatchInfo) {
            test:assertTrue(batch.id.length() > 0, msg = "Could not upload the contacts using json.");
            batchId = batch.id;
        } else {
            test:assertFail(msg = batch.detail()?.message.toString());
        }

        // Get job information.
        JobInfo|ConnectorError job = csvUpdateOperator->getJobInfo();
        if (job is JobInfo) {
            test:assertTrue(job.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = job.detail()?.message.toString());
        }

        // Close job.
        JobInfo|ConnectorError closedJob = csvUpdateOperator->closeJob();
        if (closedJob is JobInfo) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.detail()?.message.toString());
        }

        // Get batch information.
        BatchInfo|ConnectorError batchInfo = csvUpdateOperator->getBatchInfo(batchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.detail()?.message.toString());
        }

        // Get informations of all batches of this job.
        BatchInfo[]|ConnectorError allBatchInfo = csvUpdateOperator->getAllBatches();
        if (allBatchInfo is BatchInfo[]) {
            test:assertTrue(allBatchInfo.length() > 0, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = allBatchInfo.detail()?.message.toString());
        }

        // Retrieve the csv batch request.
        string|ConnectorError batchRequest = csvUpdateOperator->getBatchRequest(batchId);
        if (batchRequest is string) {
            test:assertTrue(batchRequest.length() > 0, msg = "Retrieving batch request failed.");                
        } else {
            test:assertFail(msg = batchRequest.detail()?.message.toString());
        }

        // Get the results of the batch
        Result[]|ConnectorError batchResult = csvUpdateOperator->getResult(batchId, noOfRetries);
        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Getting batch results failed.");
            test:assertTrue(checkBatchResults(batchResult), "Insert result was not successful.");
        } else {
            test:assertFail(msg = batchResult.detail()?.message.toString());
        }

        // Abort job.
        JobInfo|ConnectorError abortedJob = csvUpdateOperator->abortJob();
        if (abortedJob is JobInfo) {
            test:assertTrue(abortedJob.state == "Aborted", msg = "Aborting job failed.");
        } else {
            test:assertFail(msg = abortedJob.detail()?.message.toString());
        }
    } else {
        test:assertFail(msg = csvUpdateOperator.detail()?.message.toString());
    }
}
