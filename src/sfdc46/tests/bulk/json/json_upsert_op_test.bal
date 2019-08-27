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
    dependsOn: ["testJsonQueryOperator"]
}
function testJsonUpsertOperator() {
    log:printInfo("salesforceBulkClient -> JsonUpsertOperator");
    json contacts = [
        {
            description: "Created_from_Ballerina_Sf_Bulk_API",
            FirstName: "Andi",
            LastName: "Flower",
            Title: "Professor Grade 03",
            Phone: "0552216170",
            Email: "flower@gmail.com",
            My_External_Id__c: "202"
        },
        {
            description: "Created_from_Ballerina_Sf_Bulk_API",
            FirstName: "Andrew",
            LastName: "Strauss",
            Title: "Professor Grade 03",
            Phone: "0113232445",
            Email: "andrew.s@gmail.com",
            My_External_Id__c: "203"
        }
    ];

    // Create JSON upsert operator.
    JsonUpsertOperator|SalesforceError jsonUpsertOperator = 
        sfBulkClient->createJsonUpsertOperator("Contact", "My_External_Id__c");

    if (jsonUpsertOperator is JsonUpsertOperator) {
        string batchIdUsingJson = EMPTY_STRING;

        // Upload the json contacts.
        Batch|SalesforceError batchUsingJson = jsonUpsertOperator->upsert(contacts);
        if (batchUsingJson is Batch) {
            test:assertTrue(batchUsingJson.id.length() > 0, msg = "Could not upload the contacts using json.");
            batchIdUsingJson = batchUsingJson.id;
        } else {
            test:assertFail(msg = batchUsingJson.message);
        }

        // Get job information.
        Job|SalesforceError job = jsonUpsertOperator->getJobInfo();
        if (job is Job) {
            test:assertTrue(job.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = job.message);
        }

        // Close job.
        Job|SalesforceError closedJob = jsonUpsertOperator->closeJob();
        if (closedJob is Job) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.message);
        }

        // Get batch information.
        Batch|SalesforceError batchInfo = jsonUpsertOperator->getBatchInfo(batchIdUsingJson);
        if (batchInfo is Batch) {
            test:assertTrue(batchInfo.id == batchIdUsingJson, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.message);
        }

        // Get informations of all batches of this job.
        BatchInfo|SalesforceError allBatchInfo = jsonUpsertOperator->getAllBatches();
        if (allBatchInfo is BatchInfo) {
            test:assertTrue(allBatchInfo.batchInfoList.length() > 0, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = allBatchInfo.message);
        }

        // Retrieve the json batch request.
        json|SalesforceError batchRequest = jsonUpsertOperator->getBatchRequest(batchIdUsingJson);
        if (batchRequest is json) {
            json[]|error batchRequestArr = <json[]> batchRequest;
            if (batchRequestArr is json[]) {
                test:assertTrue(batchRequestArr.length() == 2, msg = "Retrieving batch request failed.");                
            } else {
                test:assertFail(msg = batchRequestArr.toString());
            }
        } else {
            test:assertFail(msg = batchRequest.message);
        }

        // Get the results of the batch
        Result[]|SalesforceError batchResult = jsonUpsertOperator->getBatchResults(batchIdUsingJson, noOfRetries);

        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
            test:assertTrue(checkBatchResults(batchResult), msg = "Upsert result was not successful.");
        } else {
            test:assertFail(msg = batchResult.message);
        }

        // Abort job.
        Job|SalesforceError abortedJob = jsonUpsertOperator->abortJob();
        if (abortedJob is Job) {
            test:assertTrue(abortedJob.state == "Aborted", msg = "Aborting job failed.");
        } else {
            test:assertFail(msg = abortedJob.message);
        }
    } else {
        test:assertFail(msg = jsonUpsertOperator.message);
    }
}
