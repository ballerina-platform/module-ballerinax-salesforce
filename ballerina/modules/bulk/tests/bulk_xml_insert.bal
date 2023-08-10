// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/io;
import ballerina/log;
import ballerina/test;
import ballerina/lang.runtime;

@test:Config {
    enable: true
}
function insertXml() returns error? {
    log:printInfo("baseClient -> insertXml");
    string xmlBatchId = "";

    xml contacts = xml `<sObjects xmlns="http://www.force.com/2009/06/asyncapi/dataload">
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <FirstName>Argus</FirstName>
            <LastName>Filch</LastName>
            <Title>Professor Level 01</Title>
            <Phone>099116123</Phone>
            <Email>argus@yahoo.com</Email>
            <My_External_Id__c>851</My_External_Id__c>
        </sObject>
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <FirstName>Poppy</FirstName>
            <LastName>Pomfrey</LastName>
            <Title>Professor Level 01</Title>
            <Phone>086755643</Phone>
            <Email>madampomfrey@gmail.com</Email>
            <My_External_Id__c>852</My_External_Id__c>
        </sObject>
    </sObjects>`;
    //create job
    BulkJob xmlInsertJob = check baseClient->createJob("insert", "Contact", "XML");

    //add xml content
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo batch = baseClient->addBatch(xmlInsertJob, contacts);
        if batch is BatchInfo {
            test:assertTrue(batch.id.length() > 0, msg = "Could not upload the contacts using xml.");
            xmlBatchId = batch.id;
            break;
        } else {
            if currentRetry != maxIterations {
                log:printWarn("addBatch Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("addBatch Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batch.message());
            }
        }
    }

    //get job info
    error|JobInfo jobInfo = baseClient->getJobInfo(xmlInsertJob);
    if jobInfo is JobInfo {
        test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
    } else {
        test:assertFail(msg = jobInfo.message());
    }

    //get batch info
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo batchInfo = baseClient->getBatchInfo(xmlInsertJob, xmlBatchId);
        if batchInfo is BatchInfo {
            test:assertTrue(batchInfo.id == xmlBatchId, msg = "Getting batch info failed.");
            break;
        } else {
            if currentRetry != maxIterations {
                log:printWarn("getBatchInfo Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchInfo Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchInfo.message());
            }
        }
    }

    //get all batches
    foreach int i in 1 ..< 3 {
        error|BatchInfo[] batchInfoList = baseClient->getAllBatches(xmlInsertJob);
        if batchInfoList is BatchInfo[] {
            test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
            break;
        } else {
            if i == 2 {
                test:assertFail(msg = batchInfoList.message());
            } else {
                log:printInfo("Batch Operation Failed! Retrying...");
                runtime:sleep(5.0);
            }
        }
    }

    //get batch request
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        var batchRequest = baseClient->getBatchRequest(xmlInsertJob, xmlBatchId);
        if batchRequest is xml {
            test:assertTrue((batchRequest/<*>).length() == 2, msg = "Retrieving batch request failed.");
            break;
        } else if batchRequest is error {
            if currentRetry != maxIterations {
                log:printWarn("getBatchRequest Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchRequest Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchRequest.message());
            }
        } else {
            test:assertFail("Invalid batch request!");
        }
    }

    //get batch result
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        var batchResult = baseClient->getBatchResult(xmlInsertJob, xmlBatchId);
        if batchResult is Result[] {
            foreach Result item in batchResult {
                json|error itemId = item?.id;
                if itemId is json {
                    if item.success && item.created {
                        string id = itemId.toString();
                        xmlInsertResult = xmlInsertResult + xml `<sObject><Id>${id}</Id></sObject>`;
                    }
                }
                test:assertTrue(checkBatchResults(item), msg = item?.errors.toString());
            }
            break;
        } else if batchResult is error {
            if currentRetry != maxIterations {
                log:printWarn("getBatchResult Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchResult Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchResult.message());
            }
        } else {
            test:assertFail("Invalid Batch Result!");
        }
    }

    //close job
    JobInfo closedJob = check baseClient->closeJob(xmlInsertJob);
    test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
}

@test:Config {
    enable: true
}
function insertXmlFromFile() returns error? {
    log:printInfo("baseClient -> insertXmlFromFile");
    string xmlBatchId = "";

    string xmlContactsFilePath = "ballerina/modules/bulk/tests/resources/contacts.xml";

    //create job
    BulkJob xmlInsertJob = check baseClient->createJob("insert", "Contact", "XML");

    //add xml content via file
    io:ReadableByteChannel|io:Error rbc = io:openReadableFile(xmlContactsFilePath);
    if rbc is io:ReadableByteChannel {
        foreach int currentRetry in 1 ..< maxIterations + 1 {
            error|BatchInfo batchUsingXmlFile = baseClient->addBatch(xmlInsertJob, rbc);
            if batchUsingXmlFile is BatchInfo {
                test:assertTrue(batchUsingXmlFile.id.length() > 0, msg = "Could not upload the contacts using xml file.");
                xmlBatchId = batchUsingXmlFile.id;
                break;
            } else {
                if currentRetry != maxIterations {
                    log:printWarn("addBatch Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("addBatch Operation Failed! Giving up after 5 tries.");
                    test:assertFail(msg = batchUsingXmlFile.message());
                }
            }
        }
        // close channel.
        closeRb(rbc);
    } else {
        test:assertFail(msg = rbc.message());
    }

    //get job info
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|JobInfo jobInfo = baseClient->getJobInfo(xmlInsertJob);
        if jobInfo is JobInfo {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            if currentRetry != maxIterations {
                log:printWarn("getJobInfo Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getJobInfo Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = jobInfo.message());
            }
        }
    }

    //get batch info
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo batchInfo = baseClient->getBatchInfo(xmlInsertJob, xmlBatchId);
        if batchInfo is BatchInfo {
            test:assertTrue(batchInfo.id == xmlBatchId, msg = "Getting batch info failed.");
        } else {
            if currentRetry != maxIterations {
                log:printWarn("getBatchInfo Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchInfo Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchInfo.message());
            }
        }
    }

    //get all batches
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo[] batchInfoList = baseClient->getAllBatches(xmlInsertJob);
        if batchInfoList is BatchInfo[] {
            test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
        } else {
            if currentRetry != maxIterations {
                log:printWarn("getAllBatches Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getAllBatches Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchInfoList.message());
            }
        }
    }

    //get batch request
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        var batchRequest = baseClient->getBatchRequest(xmlInsertJob, xmlBatchId);
        if batchRequest is xml {
            test:assertTrue((batchRequest/<*>).length() == 2, msg = "Retrieving batch request failed.");
            break;
        } else if batchRequest is error {
            if currentRetry != maxIterations {
                log:printWarn("getBatchRequest Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchRequest Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchRequest.message());
            }
        } else {
            test:assertFail("Invalid batch request!");
        }
    }

    //get batch result
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        var batchResult = baseClient->getBatchResult(xmlInsertJob, xmlBatchId);
        if batchResult is Result[] {
            foreach Result item in batchResult {
                json|error itemId = item?.id;
                if itemId is json {
                    if item.success && item.created {
                        string id = itemId.toString();
                        xmlInsertResult = xmlInsertResult + xml `<sObject><Id>${id}</Id></sObject>`;
                    }
                }
                test:assertTrue(checkBatchResults(item), msg = item?.errors.toString());
            }
            break;
        } else if batchResult is error {
            if currentRetry != maxIterations {
                log:printWarn("getBatchResult Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchResult Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchResult.message());
            }
        } else {
            test:assertFail("Invalid Batch Result!");
        }
    }

    //close job
    error|JobInfo closedJob = baseClient->closeJob(xmlInsertJob);
    if closedJob is JobInfo {
        test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
    } else {
        test:assertFail(msg = closedJob.message());
    }

}
