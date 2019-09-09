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
    // dependsOn: ["testDeleteOpportunity"]
}
function testJsonInsertOperator() {
    log:printInfo("salesforceBulkClient -> JsonInsertOperator");

    json contacts = [
        {
            description: "Created_from_Ballerina_Sf_Bulk_API",
            FirstName: "Morne",
            LastName: "Morkel",
            Title: "Professor Grade 03",
            Phone: "0442226670",
            Email: "morne89@gmail.com",
            My_External_Id__c: "201"
        },
        {
            description: "Created_from_Ballerina_Sf_Bulk_API",
            FirstName: "Andi",
            LastName: "Flower",
            Title: "Professor Grade 03",
            Phone: "0442216170",
            Email: "flower.andie@gmail.com",
            My_External_Id__c: "202"
        }
    ];
    
    string jsonContactsFilePath = "src/sfdc46/tests/resources/contacts.json";

    // Create JSON insert operator.
    JsonInsertOperator|ConnectorError jsonInsertOperator = sfBulkClient->createJsonInsertOperator("Contact");

    if (jsonInsertOperator is JsonInsertOperator) {
        string batchIdUsingJson = EMPTY_STRING;
        string batchIdUsingJsonFile = EMPTY_STRING;

        // Upload the json contacts.
        BatchInfo|ConnectorError batchUsingJson = jsonInsertOperator->insert(contacts);
        if (batchUsingJson is BatchInfo) {
            test:assertTrue(batchUsingJson.id.length() > 0, msg = "Could not upload the contacts using json.");
            batchIdUsingJson = batchUsingJson.id;
        } else {
            test:assertFail(msg = batchUsingJson.detail()?.message.toString());
        }

        // Upload json contacts as a file.
        BatchInfo|ConnectorError batchUsingJsonFile = jsonInsertOperator->insertFile(jsonContactsFilePath);
        if (batchUsingJsonFile is BatchInfo) {
            test:assertTrue(batchUsingJsonFile.id.length() > 0, msg = "Could not upload the contacts using json file.");
            batchIdUsingJsonFile = batchUsingJsonFile.id;
        } else {
            test:assertFail(msg = batchUsingJsonFile.detail()?.message.toString());
        }

        // Get job information.
        JobInfo|ConnectorError job = jsonInsertOperator->getJobInfo();
        if (job is JobInfo) {
            test:assertTrue(job.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = job.detail()?.message.toString());
        }

        // Close job.
        JobInfo|ConnectorError closedJob = jsonInsertOperator->closeJob();
        if (closedJob is JobInfo) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.detail()?.message.toString());
        }

        // Get batch information.
        BatchInfo|ConnectorError batchInfo = jsonInsertOperator->getBatchInfo(batchIdUsingJson);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchIdUsingJson, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.detail()?.message.toString());
        }

        // Get informations of all batches of this job.
        BatchInfo[]|ConnectorError allBatchInfo = jsonInsertOperator->getAllBatches();
        if (allBatchInfo is BatchInfo[]) {
            test:assertTrue(allBatchInfo.length() == 2, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = allBatchInfo.detail()?.message.toString());
        }

        // Retrieve the json batch request.
        json|ConnectorError batchRequest = jsonInsertOperator->getBatchRequest(batchIdUsingJson);
        if (batchRequest is json) {
            json[]|error batchRequestArr = <json[]> batchRequest;
            if (batchRequestArr is json[]) {
                test:assertTrue(batchRequestArr.length() == 2, msg = "Retrieving batch request failed.");                
            } else {
                test:assertFail(msg = batchRequestArr.toString());
            }
        } else {
            test:assertFail(msg = batchRequest.detail()?.message.toString());
        }

        // Get the results of the batch
        Result[]|ConnectorError batchResult = jsonInsertOperator->getResult(batchIdUsingJson, noOfRetries);

        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
            test:assertTrue(checkBatchResults(batchResult), msg = "Insert result was not successful.");                
        } else {
            test:assertFail(msg = batchResult.detail()?.message.toString());
        }

        // Abort job.
        JobInfo|ConnectorError abortedJob = jsonInsertOperator->abortJob();
        if (abortedJob is JobInfo) {
            test:assertTrue(abortedJob.state == "Aborted", msg = "Aborting job failed.");
        } else {
            test:assertFail(msg = abortedJob.detail()?.message.toString());
        }
    } else {
        test:assertFail(msg = jsonInsertOperator.detail()?.message.toString());
    }
}
