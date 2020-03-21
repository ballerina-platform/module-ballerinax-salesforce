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

    string contacts = "description,FirstName,LastName,Title,Phone,Email,My_External_Id__c" +
"Created_from_Ballerina_Sf_Bulk_API,John,Michael,Professor Grade 04,0332236677,john434@gmail.com,301" +
"Created_from_Ballerina_Sf_Bulk_API,Peter,Shane,Professor Grade 04,0332211777,peter77@gmail.com,302";

    string csvContactsFilePath = "src/sfdc46/tests/resources/contacts.csv";

    // Create csv insert operator.
    CsvInsertOperator|ConnectorError csvInsertOperator = sfBulkClient->createCsvInsertOperator("Contact");

    if (csvInsertOperator is CsvInsertOperator) {
        string batchIdUsingCsv = EMPTY_STRING;
        string batchIdUsingCsvFile = EMPTY_STRING;

        // Upload the csv contacts.
        BatchInfo|ConnectorError batchUsingCsv = csvInsertOperator->insert(contacts);
        if (batchUsingCsv is BatchInfo) {
            test:assertTrue(batchUsingCsv.id.length() > 0, msg = "Could not upload the contacts using csv.");
            batchIdUsingCsv = batchUsingCsv.id;
        } else {
            test:assertFail(msg = batchUsingCsv.detail()?.message.toString());
        }

        // Upload csv contacts as a file.
        BatchInfo|ConnectorError batchUsingJsonFile = csvInsertOperator->insertFile(csvContactsFilePath);
        if (batchUsingJsonFile is BatchInfo) {
            test:assertTrue(batchUsingJsonFile.id.length() > 0, msg = "Could not upload the contacts using csv file.");
            batchIdUsingCsvFile = batchUsingJsonFile.id;
        } else {
            test:assertFail(msg = batchUsingJsonFile.detail()?.message.toString());
        }

        // Get job information.
        JobInfo|ConnectorError job = csvInsertOperator->getJobInfo();
        if (job is JobInfo) {
            test:assertTrue(job.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = job.detail()?.message.toString());
        }

        // Close job.
        JobInfo|ConnectorError closedJob = csvInsertOperator->closeJob();
        if (closedJob is JobInfo) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.detail()?.message.toString());
        }

        // Get batch information.
        BatchInfo|ConnectorError batchInfo = csvInsertOperator->getBatchInfo(batchIdUsingCsv);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchIdUsingCsv, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.detail()?.message.toString());
        }

        // Get informations of all batches of this job.
        BatchInfo[]|ConnectorError allBatchInfo = csvInsertOperator->getAllBatches();
        if (allBatchInfo is BatchInfo[]) {
            test:assertTrue(allBatchInfo.length() == 2, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = allBatchInfo.detail()?.message.toString());
        }

        // Retrieve the csv batch request.
        string|ConnectorError batchRequest = csvInsertOperator->getBatchRequest(batchIdUsingCsv);
        if (batchRequest is string) {
            test:assertTrue(batchRequest.length() > 0, msg = "Retrieving batch request failed.");                
        } else {
            test:assertFail(msg = batchRequest.detail()?.message.toString());
        }

        // Get the results of the batch
        Result[]|ConnectorError batchResult = csvInsertOperator->getResult(batchIdUsingCsv, noOfRetries);

        if (batchResult is Result[]) {
            test:assertTrue(checkBatchResults(batchResult), "Insert result was not successful.");
        } else {
            test:assertFail(msg = batchResult.detail()?.message.toString());
        }

        // Abort job.
        JobInfo|ConnectorError abortedJob = csvInsertOperator->abortJob();
        if (abortedJob is JobInfo) {
            test:assertTrue(abortedJob.state == "Aborted", msg = "Aborting job failed.");
        } else {
            test:assertFail(msg = abortedJob.detail()?.message.toString());
        }
    } else {
        test:assertFail(msg = csvInsertOperator.detail()?.message.toString());
    }
}
