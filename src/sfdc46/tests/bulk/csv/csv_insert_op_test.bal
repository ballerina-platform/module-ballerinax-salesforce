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
    dependsOn: ["testJsonDeleteOperator"]
}
function testCsvInsertOperator() {
    log:printInfo("salesforceBulkClient -> CsvInsertOperator");

    string contacts = "description,FirstName,LastName,Title,Phone,Email,My_External_Id__c
Created_from_Ballerina_Sf_Bulk_API,John,Michael,Professor Grade 04,0332236677,john434@gmail.com,301
Created_from_Ballerina_Sf_Bulk_API,Peter,Shane,Professor Grade 04,0332211777,peter77@gmail.com,302";

    string csvContactsFilePath = "src/sfdc46/tests/resources/contacts.csv";

    // Create csv insert operator.
    CsvInsertOperator|SalesforceError csvInsertOperator = sfBulkClient->createCsvInsertOperator("Contact");

    if (csvInsertOperator is CsvInsertOperator) {
        string batchIdUsingCsv = EMPTY_STRING;
        string batchIdUsingCsvFile = EMPTY_STRING;

        // Upload the csv contacts.
        Batch|SalesforceError batchUsingCsv = csvInsertOperator->insert(contacts);
        if (batchUsingCsv is Batch) {
            test:assertTrue(batchUsingCsv.id.length() > 0, msg = "Could not upload the contacts using csv.");
            batchIdUsingCsv = batchUsingCsv.id;
        } else {
            test:assertFail(msg = batchUsingCsv.message);
        }

        // Upload csv contacts as a file.
        Batch|SalesforceError batchUsingJsonFile = csvInsertOperator->insertFile(csvContactsFilePath);
        if (batchUsingJsonFile is Batch) {
            test:assertTrue(batchUsingJsonFile.id.length() > 0, msg = "Could not upload the contacts using csv file.");
            batchIdUsingCsvFile = batchUsingJsonFile.id;
        } else {
            test:assertFail(msg = batchUsingJsonFile.message);
        }

        // Get job information.
        Job|SalesforceError job = csvInsertOperator->getJobInfo();
        if (job is Job) {
            test:assertTrue(job.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = job.message);
        }

        // Close job.
        Job|SalesforceError closedJob = csvInsertOperator->closeJob();
        if (closedJob is Job) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.message);
        }

        // Get batch information.
        Batch|SalesforceError batchInfo = csvInsertOperator->getBatchInfo(batchIdUsingCsv);
        if (batchInfo is Batch) {
            test:assertTrue(batchInfo.id == batchIdUsingCsv, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.message);
        }

        // Get informations of all batches of this job.
        BatchInfo|SalesforceError allBatchInfo = csvInsertOperator->getAllBatches();
        if (allBatchInfo is BatchInfo) {
            test:assertTrue(allBatchInfo.batchInfoList.length() == 2, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = allBatchInfo.message);
        }

        // Retrieve the csv batch request.
        string|SalesforceError batchRequest = csvInsertOperator->getBatchRequest(batchIdUsingCsv);
        if (batchRequest is string) {
            test:assertTrue(batchRequest.length() > 0, msg = "Retrieving batch request failed.");                
        } else {
            test:assertFail(msg = batchRequest.message);
        }

        // Get the results of the batch
        Result[]|SalesforceError batchResult = csvInsertOperator->getBatchResults(batchIdUsingCsv, noOfRetries);

        if (batchResult is Result[]) {
            test:assertTrue(checkBatchResults(batchResult), "Insert result was not successful.");
        } else {
            test:assertFail(msg = batchResult.message);
        }

        // Abort job.
        Job|SalesforceError abortedJob = csvInsertOperator->abortJob();
        if (abortedJob is Job) {
            test:assertTrue(abortedJob.state == "Aborted", msg = "Aborting job failed.");
        } else {
            test:assertFail(msg = abortedJob.message);
        }
    } else {
        test:assertFail(msg = csvInsertOperator.message);
    }
}
