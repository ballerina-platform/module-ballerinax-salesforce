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
    dependsOn: ["testJsonUpdateOperator"]
}
function testJsonDeleteOperator() {
    log:printInfo("salesforceBulkClient -> JsonDeleteOperator");
    
    // Create JSON delete operator.
    JsonDeleteOperator|SalesforceError jsonDeleteOperator = sfBulkClient->createJsonDeleteOperator("Contact");
    // Get contacts to be deleted.
    json deleteContacts = getDeleteContacts();

    if (jsonDeleteOperator is JsonDeleteOperator) {
        string batchId = EMPTY_STRING;

        // Create json delete batch.
        Batch|SalesforceError batch = jsonDeleteOperator->delete(<@untainted> deleteContacts);
        if (batch is Batch) {
            test:assertTrue(batch.id.length() > 0, msg = "Creating query batch failed.");
            batchId = batch.id;
        } else {
            test:assertFail(msg = batch.message);
        }

        // Get job information.
        Job|SalesforceError jobInfo = jsonDeleteOperator->getJobInfo();
        if (jobInfo is Job) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = jobInfo.message);
        }

        // Close job.
        Job|SalesforceError closedJob = jsonDeleteOperator->closeJob();
        if (closedJob is Job) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.message);
        }

        // Get batch information.
        Batch|SalesforceError batchInfo = jsonDeleteOperator->getBatchInfo(batchId);
        if (batchInfo is Batch) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.message);
        }

        // Get informations of all batches of this job.
        BatchInfo|SalesforceError allBatchInfo = jsonDeleteOperator->getAllBatches();
        if (allBatchInfo is BatchInfo) {
            test:assertTrue(allBatchInfo.batchInfoList.length() == 1, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = allBatchInfo.message);
        }

        // Get the batch request.
        json|SalesforceError batchRequest = jsonDeleteOperator->getBatchRequest(batchId);
        if (batchRequest is json) {
            json[] batchRequestArr = <json[]> batchRequest;
            test:assertTrue(batchRequestArr.length() > 0, msg = "Getting batch request failed.");
        } else {
            test:assertFail(msg = batchRequest.message);
        }

        // Get batch results.
        Result[]|SalesforceError batchResults = jsonDeleteOperator->getBatchResults(batchId, noOfRetries);

        if (batchResults is Result[]) {
            test:assertTrue(batchResults.length() > 0, msg = "Getting batch results failed.");
            test:assertTrue(checkBatchResults(batchResults), msg = "Delete result was not successful.");
        } else {
            test:assertFail(msg = batchResults.message);
        }

        // Abort job.
        Job|SalesforceError abortedJob = jsonDeleteOperator->abortJob();
        if (abortedJob is Job) {
            test:assertTrue(abortedJob.state == "Aborted", msg = "Aborting job failed.");
        } else {
            test:assertFail(msg = abortedJob.message);
        }
    } else {
        test:assertFail(msg = jsonDeleteOperator.message);
    }
}
