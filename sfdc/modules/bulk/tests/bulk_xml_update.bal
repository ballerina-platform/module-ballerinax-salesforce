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

import ballerina/log;
import ballerina/test;
import ballerina/lang.runtime;

@test:Config {
    enable: true,
    dependsOn: [insertXml, upsertXml]
}
function updateXml() returns error? {
    log:printInfo("baseClient -> updateXml");
    string batchId = "";
    string flitchID = getContactIdByName("Argus", "Filch", "Professor Level 01");
    string poppyID = getContactIdByName("Poppy", "Pomfrey", "Professor Level 01");
    xml contacts = xml `<sObjects xmlns="http://www.force.com/2009/06/asyncapi/dataload">
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <Id>${flitchID}</Id>
            <FirstName>Argus</FirstName>
            <LastName>Filch</LastName>
            <Title>Professor Level 01</Title>
            <Phone>0332254123</Phone>
            <Email>argus@yahoo.com</Email>
            <My_External_Id__c>851</My_External_Id__c>
        </sObject>
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <Id>${poppyID}</Id>
            <FirstName>Poppy</FirstName>
            <LastName>Pomfrey</LastName>
            <Title>Professor Level 01</Title>
            <Phone>0442554423</Phone>
            <Email>madampomfrey@gmail.com</Email>
            <My_External_Id__c>852</My_External_Id__c>
        </sObject>
    </sObjects>`;
    //create job
    BulkJob updateJob = check baseClient->createJob("update", "Contact", "XML");

    //add xml content
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo batch = baseClient->addBatch(updateJob, contacts);
        if (batch is BatchInfo) {
            test:assertTrue(batch.id.length() > 0, msg = "Could not upload the contacts using xml.");
            batchId = batch.id;
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
    error|JobInfo jobInfo = baseClient->getJobInfo(updateJob);
    if (jobInfo is JobInfo) {
        test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
    } else {
        test:assertFail(msg = jobInfo.message());
    }

    //get batch info
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo batchInfo = baseClient->getBatchInfo(updateJob, batchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
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
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BatchInfo[] batchInfoList = baseClient->getAllBatches(updateJob);
        if (batchInfoList is BatchInfo[]) {
            test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
            break;
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
        var batchRequest = baseClient->getBatchRequest(updateJob, batchId);
        if (batchRequest is xml) {
            test:assertTrue((batchRequest/<*>).length() == 2, msg = "Retrieving batch request failed.");
            break;
        } else if (batchRequest is error) {
            if currentRetry != maxIterations {
                log:printWarn("getBatchRequest Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchRequest Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchRequest.message());
            }
        } else {
            test:assertFail("Invalid batch request!");
            break;
        }
    }

    //get batch result
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        var batchResult = baseClient->getBatchResult(updateJob, batchId);
        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
            foreach Result res in batchResult {
                test:assertTrue(checkBatchResults(res), msg = res?.errors.toString());
            }
            break;
        } else if (batchResult is error) {
            if currentRetry != maxIterations {
                log:printWarn("getBatchResult Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchResult Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchResult.message());
            }
        } else {
            test:assertFail("Invalid Batch Result!");
            break;
        }
    }

    //close job
    error|JobInfo closedJob = baseClient->closeJob(updateJob);
    if (closedJob is JobInfo) {
        test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
    } else {
        test:assertFail(msg = closedJob.message());
    }
}
