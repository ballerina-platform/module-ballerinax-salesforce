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
    dependsOn: ["testCsvDeleteOperator"]
}
function testXmlInsertOperator() {
    log:printInfo("salesforceBulkClient -> XmlInsertOperator");

    xml contacts = xml `<sObjects xmlns="http://www.force.com/2009/06/asyncapi/dataload">
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <FirstName>Lucas</FirstName>
            <LastName>Podolski</LastName>
            <Title>Professor Grade 05</Title>
            <Phone>0332254123</Phone>
            <Email>lucas@yahoo.com</Email>
            <My_External_Id__c>221</My_External_Id__c>
        </sObject>
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <FirstName>Miroslav</FirstName>
            <LastName>Klose</LastName>
            <Title>Professor Grade 05</Title>
            <Phone>0442554423</Phone>
            <Email>klose@gmail.com</Email>
            <My_External_Id__c>222</My_External_Id__c>
        </sObject>
    </sObjects>`;

    string jsonContactsFilePath = "src/sfdc46/tests/resources/contacts.xml";

    // Create JSON insert operator.
    XmlInsertOperator|SalesforceError xmlInsertOperator = sfBulkClient->createXmlInsertOperator("Contact");

    if (xmlInsertOperator is XmlInsertOperator) {
        string batchIdUsingXml = EMPTY_STRING;
        string batchIdUsingXmlFile = EMPTY_STRING;

        // Upload the json contacts.
        Batch|SalesforceError batchUsingXml = xmlInsertOperator->upload(contacts);
        if (batchUsingXml is Batch) {
            test:assertTrue(batchUsingXml.id.length() > 0, msg = "Could not upload the contacts using json.");
            batchIdUsingXml = batchUsingXml.id;
        } else {
            test:assertFail(msg = batchUsingXml.message);
        }

        // Upload json contacts as a file.
        Batch|SalesforceError batchUsingXmlFile = xmlInsertOperator->uploadFile(jsonContactsFilePath);
        if (batchUsingXmlFile is Batch) {
            test:assertTrue(batchUsingXmlFile.id.length() > 0, msg = "Could not upload the contacts using json file.");
            batchIdUsingXmlFile = batchUsingXmlFile.id;
        } else {
            test:assertFail(msg = batchUsingXmlFile.message);
        }

        // Get job information.
        Job|SalesforceError job = xmlInsertOperator->getJobInfo();
        if (job is Job) {
            test:assertTrue(job.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = job.message);
        }

        // Close job.
        Job|SalesforceError closedJob = xmlInsertOperator->closeJob();
        if (closedJob is Job) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.message);
        }

        // Get batch information.
        Batch|SalesforceError batchInfo = xmlInsertOperator->getBatchInfo(batchIdUsingXml);
        if (batchInfo is Batch) {
            test:assertTrue(batchInfo.id == batchIdUsingXml, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.message);
        }

        // Get informations of all batches of this job.
        BatchInfo|SalesforceError allBatchInfo = xmlInsertOperator->getAllBatches();
        if (allBatchInfo is BatchInfo) {
            test:assertTrue(allBatchInfo.batchInfoList.length() == 2, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = allBatchInfo.message);
        }

        // Retrieve the json batch request.
        xml|SalesforceError batchRequest = xmlInsertOperator->getBatchRequest(batchIdUsingXml);
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
        xml|SalesforceError batchResult = xmlInsertOperator->getBatchResults(batchIdUsingXml, noOfRetries);

        if (batchResult is xml) {
            test:assertTrue(validateXmlBatchResult(batchResult), msg = "Invalid batch result.");                
        } else {
            test:assertFail(msg = batchResult.message);
        }

        // Abort job.
        Job|SalesforceError abortedJob = xmlInsertOperator->abortJob();
        if (abortedJob is Job) {
            test:assertTrue(abortedJob.state == "Aborted", msg = "Aborting job failed.");
        } else {
            test:assertFail(msg = abortedJob.message);
        }
    } else {
        test:assertFail(msg = xmlInsertOperator.message);
    }
}
