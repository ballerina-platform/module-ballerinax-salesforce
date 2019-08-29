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
    dependsOn: ["testXmlUpdateOperator"]
}
function testXmlDeleteOperator() {
    log:printInfo("salesforceBulkClient -> XmlDeleteOperator");
    
    // Create JSON delete operator.
    XmlDeleteOperator|SalesforceError xmlDeleteOperator = sfBulkClient->createXmlDeleteOperator("Contact");
    // Get contacts to be deleted.
    xml deleteContacts = getDeleteContactsAsXml();

    if (xmlDeleteOperator is XmlDeleteOperator) {
        string batchId = EMPTY_STRING;

        // Create json delete batch.
        Batch|SalesforceError batch = xmlDeleteOperator->delete(<@untainted> deleteContacts);
        if (batch is Batch) {
            test:assertTrue(batch.id.length() > 0, msg = "Creating query batch failed.");
            batchId = batch.id;
        } else {
            test:assertFail(msg = batch.message);
        }

        // Get job information.
        Job|SalesforceError jobInfo = xmlDeleteOperator->getJobInfo();
        if (jobInfo is Job) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = jobInfo.message);
        }

        // Close job.
        Job|SalesforceError closedJob = xmlDeleteOperator->closeJob();
        if (closedJob is Job) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.message);
        }

        // Get batch information.
        Batch|SalesforceError batchInfo = xmlDeleteOperator->getBatchInfo(batchId);
        if (batchInfo is Batch) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.message);
        }

        // Get informations of all batches of this job.
        BatchInfo|SalesforceError allBatchInfo = xmlDeleteOperator->getAllBatches();

        if (allBatchInfo is BatchInfo) {
            test:assertTrue(allBatchInfo.batchInfoList.length() == 1, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = allBatchInfo.message);
        }

        // Get the batch request.
        xml|SalesforceError batchRequest = xmlDeleteOperator->getBatchRequest(batchId);
        if (batchRequest is xml) {
            foreach var xmlBatch in batchRequest.*.elements() {

                if (xmlBatch is xml) {
                    test:assertTrue(xmlBatch[getElementNameWithNamespace("Id")].getTextValue().length() > 0, 
                        msg = "Retrieving batch request failed.");                
                } else {
                    test:assertFail(msg = "Accessing xml batches from batch request failed, err=" 
                        + xmlBatch.toString());
                }
            }
        } else {
            test:assertFail(msg = batchRequest.message);
        }

        // Get batch results.
        Result[]|SalesforceError batchResults = xmlDeleteOperator->getResult(batchId, noOfRetries);

        if (batchResults is Result[]) {
            test:assertTrue(checkBatchResults(batchResults), msg = "Invalid batch result.");  
        } else {
            test:assertFail(msg = batchResults.message);
        }

        // Abort job.
        Job|SalesforceError abortedJob = xmlDeleteOperator->abortJob();
        if (abortedJob is Job) {
            test:assertTrue(abortedJob.state == "Aborted", msg = "Aborting job failed.");
        } else {
            test:assertFail(msg = abortedJob.message);
        }
    } else {
        test:assertFail(msg = xmlDeleteOperator.message);
    }
}
