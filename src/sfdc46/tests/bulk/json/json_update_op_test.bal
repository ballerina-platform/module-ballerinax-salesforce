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
    dependsOn: ["testJsonUpsertOperator"]
}
function testJsonUpdateOperator() {
    log:printInfo("salesforceBulkClient -> JsonUpdateOperator");

    string mornesID = getContactIdByName("Morne", "Morkel", "Professor Grade 03");
    string andisID = getContactIdByName("Andi", "Flower", "Professor Grade 03");

    json contacts = [
        {
            description: "Created_from_Ballerina_Sf_Bulk_API",
            Id: mornesID,
            FirstName: "Morne",
            LastName: "Morkel",
            Title: "Professor Grade 03",
            Phone: "0552226670",
            Email: "morne@w3c.com",
            My_External_Id__c: "201"
        },
        {
            description: "Created_from_Ballerina_Sf_Bulk_API",
            Id: andisID,
            FirstName: "Andi",
            LastName: "Flower",
            Title: "Professor Grade 03",
            Phone: "0442216170",
            Email: "andie@w3c.com",
            My_External_Id__c: "203"
        }
    ];

    // Create JSON update operator.
    JsonUpdateOperator|SalesforceError jsonUpdateOperator = sfBulkClient->createJsonUpdateOperator("Contact");

    if (jsonUpdateOperator is JsonUpdateOperator) {
        string batchIdUsingJson = EMPTY_STRING;

        // Upload the json contacts.
        Batch|SalesforceError batchUsingJson = jsonUpdateOperator->update(<@untainted> contacts);
        if (batchUsingJson is Batch) {
            test:assertTrue(batchUsingJson.id.length() > 0, msg = "Could not upload the contacts using json.");
            batchIdUsingJson = batchUsingJson.id;
        } else {
            test:assertFail(msg = batchUsingJson.message);
        }

        // Get job information.
        Job|SalesforceError job = jsonUpdateOperator->getJobInfo();
        if (job is Job) {
            test:assertTrue(job.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = job.message);
        }

        // Close job.
        Job|SalesforceError closedJob = jsonUpdateOperator->closeJob();
        if (closedJob is Job) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.message);
        }

        // Get batch information.
        Batch|SalesforceError batchInfo = jsonUpdateOperator->getBatchInfo(batchIdUsingJson);
        if (batchInfo is Batch) {
            test:assertTrue(batchInfo.id == batchIdUsingJson, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.message);
        }

        // Get informations of all batches of this job.
        BatchInfo|SalesforceError allBatchInfo = jsonUpdateOperator->getAllBatches();
        if (allBatchInfo is BatchInfo) {
            test:assertTrue(allBatchInfo.batchInfoList.length() > 0, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = allBatchInfo.message);
        }

        // Retrieve the json batch request.
        json|SalesforceError batchRequest = jsonUpdateOperator->getBatchRequest(batchIdUsingJson);
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
        Result[]|SalesforceError batchResult = jsonUpdateOperator->getResult(batchIdUsingJson, noOfRetries);

        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
            test:assertTrue(checkBatchResults(batchResult), msg = "Update result was not successful.");
        } else {
            test:assertFail(msg = batchResult.message);
        }

        // Abort job.
        Job|SalesforceError abortedJob = jsonUpdateOperator->abortJob();
        if (abortedJob is Job) {
            test:assertTrue(abortedJob.state == "Aborted", msg = "Aborting job failed.");
        } else {
            test:assertFail(msg = abortedJob.message);
        }
    } else {
        test:assertFail(msg = jsonUpdateOperator.message);
    }
}
