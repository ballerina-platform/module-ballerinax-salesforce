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
    dependsOn: ["testXmlQueryOperator"]
}
function testXmlUpsertOperator() {
    log:printInfo("salesforceBulkClient -> XmlUpsertOperator");

    xml contacts = xml `<sObjects xmlns="http://www.force.com/2009/06/asyncapi/dataload">
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <FirstName>Lucas</FirstName>
            <LastName>Podolski</LastName>
            <Title>Professor Grade 05</Title>
            <Phone>0442254123</Phone>
            <Email>lucas@yahoo.com</Email>
            <My_External_Id__c>221</My_External_Id__c>
        </sObject>
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <FirstName>John</FirstName>
            <LastName>Wicks</LastName>
            <Title>Professor Grade 05</Title>
            <Phone>0442552550</Phone>
            <Email>wicks@gmail.com</Email>
            <My_External_Id__c>223</My_External_Id__c>
        </sObject>
    </sObjects>`;

    // Create JSON upsert operator.
    XmlUpsertOperator|SalesforceError xmlUpsertOperator = 
        sfBulkClient->createXmlUpsertOperator("Contact", "My_External_Id__c");

    if (xmlUpsertOperator is XmlUpsertOperator) {
        string batchIdUsingXml = EMPTY_STRING;

        // Upload the json contacts.
        Batch|SalesforceError batchUsingXml = xmlUpsertOperator->upsert(contacts);
        if (batchUsingXml is Batch) {
            test:assertTrue(batchUsingXml.id.length() > 0, msg = "Could not upload the contacts using json.");
            batchIdUsingXml = batchUsingXml.id;
        } else {
            test:assertFail(msg = batchUsingXml.message);
        }

        // Get job information.
        Job|SalesforceError job = xmlUpsertOperator->getJobInfo();
        if (job is Job) {
            test:assertTrue(job.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = job.message);
        }

        // Close job.
        Job|SalesforceError closedJob = xmlUpsertOperator->closeJob();
        if (closedJob is Job) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.message);
        }

        // Get batch information.
        Batch|SalesforceError batchInfo = xmlUpsertOperator->getBatchInfo(batchIdUsingXml);
        if (batchInfo is Batch) {
            test:assertTrue(batchInfo.id == batchIdUsingXml, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.message);
        }

        // Get informations of all batches of this job.
        BatchInfo|SalesforceError allBatchInfo = xmlUpsertOperator->getAllBatches();
        if (allBatchInfo is BatchInfo) {
            test:assertTrue(allBatchInfo.batchInfoList.length() > 0, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = allBatchInfo.message);
        }

        // Retrieve the json batch request.
        xml|SalesforceError batchRequest = xmlUpsertOperator->getBatchRequest(batchIdUsingXml);
        if (batchRequest is xml) {
            foreach var xmlBatch in batchRequest.*.elements() {
                if (xmlBatch is xml) {
                    test:assertTrue(xmlBatch[getElementNameWithNamespace("description")].getTextValue() == 
                        "Created_from_Ballerina_Sf_Bulk_API", 
                        msg = "Retrieving batch request failed.");                
                } else {
                    test:assertFail(msg = "Accessing xml batches from batch request failed, err=" 
                        + xmlBatch.toString());
                }
            }
        } else {
            test:assertFail(msg = batchRequest.message);
        }

        // Get the results of the batch
        Result[]|SalesforceError batchResult = xmlUpsertOperator->getBatchResults(batchIdUsingXml, noOfRetries);

        if (batchResult is Result[]) {
            test:assertTrue(checkBatchResults(batchResult), msg = "Invalid batch result.");                
        } else {
            test:assertFail(msg = batchResult.message);
        }

        // Abort job.
        Job|SalesforceError abortedJob = xmlUpsertOperator->abortJob();
        if (abortedJob is Job) {
            test:assertTrue(abortedJob.state == "Aborted", msg = "Aborting job failed.");
        } else {
            test:assertFail(msg = abortedJob.message);
        }
    } else {
        test:assertFail(msg = xmlUpsertOperator.message);
    }
}
