// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerinax/salesforce.bulk;
import ballerinax/salesforce;
import ballerina/os;

// Create Salesforce client configuration by reading from environemnt.
configurable string clientId = os:getEnv("CLIENT_ID");
configurable string clientSecret = os:getEnv("CLIENT_SECRET");
configurable string refreshToken = os:getEnv("REFRESH_TOKEN");
configurable string refreshUrl = os:getEnv("REFRESH_URL");
configurable string baseUrl = os:getEnv("EP_URL");

// Using direct-token config for client configuration
salesforce:ConnectionConfig sfConfig = {
    baseUrl: baseUrl,
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
    }
};

// Create Salesforce client.
salesforce:Client baseClient = check new (sfConfig);
bulk:Client bulkClient = check new (sfConfig);

public function main() returns error? {

    string batchId = "";

    string id1 = check getContactIdByName("Wanda", "Davidson", "Software Engineer Level 03");
    string id2 = check getContactIdByName("Natasha", "Romenoff", "Software Engineer Level 03");

    xml contacts = xml `<sObjects xmlns="http://www.force.com/2009/06/asyncapi/dataload">
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <Id>${id1}</Id>
            <FirstName>Wanda</FirstName>
            <LastName>Davidson</LastName>
            <Title>Software Engineer Level 3</Title>
            <Phone>0991161233</Phone>
            <Email>wanda67@yahoo.com</Email>
            <My_External_Id__c>864</My_External_Id__c>
        </sObject>
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <Id>${id2}</Id>
            <FirstName>Natasha</FirstName>
            <LastName>Romenoff</LastName>
            <Title>Software Engineer Level 3</Title>
            <Phone>0867556833</Phone>
            <Email>natashaRom@gmail.com</Email>
            <My_External_Id__c>865</My_External_Id__c>
        </sObject>
    </sObjects>`;

    bulk:BulkJob|error updateJob = bulkClient->createJob("update", "Contact", "XML");

    if updateJob is bulk:BulkJob {
        error|bulk:BatchInfo batch = bulkClient->addBatch(updateJob, contacts);
        if batch is bulk:BatchInfo {
            string message = batch.id.length() > 0 ? "Batch Updated Successfully" : "Failed to Update the Batch";
            batchId = batch.id;
            log:printInfo(message);
        } else {
            log:printError(batch.message());
        }

        //get job info
        error|bulk:JobInfo jobInfo = bulkClient->getJobInfo(updateJob);
        if jobInfo is bulk:JobInfo {
            string message = jobInfo.id.length() > 0 ? "Jon Info Received Successfully" : "Failed Retrieve Job Info";
            log:printInfo(message);
        } else {
            log:printError(jobInfo.message());
        }

        //get batch info
        error|bulk:BatchInfo batchInfo = bulkClient->getBatchInfo(updateJob, batchId);
        if batchInfo is bulk:BatchInfo {
            string message = batchInfo.id == batchId ? "Batch Info Received Successfully" : "Failed to Retrieve Batch Info";
            log:printInfo(message);
        } else {
            log:printError(batchInfo.message());
        }

        //get all batches
        error|bulk:BatchInfo[] batchInfoList = bulkClient->getAllBatches(updateJob);
        if batchInfoList is bulk:BatchInfo[] {
            string message = batchInfoList.length() == 1 ? "All Batches Received Successfully" : "Failed to Retrieve All Batches";
            log:printInfo(message);
        } else {
            log:printError(batchInfoList.message());
        }

        //get batch request
        var batchRequest = bulkClient->getBatchRequest(updateJob, batchId);
        if batchRequest is xml {
            string message = (batchRequest/<*>).length() > 0 ? "Batch Request Received Successfully" : "Failed to Retrieve Batch Request";
            log:printInfo(message);

        } else if batchRequest is error {
            log:printError(batchRequest.message());
        } else {
            log:printError(batchRequest.toString());
        }

        //get batch result
        var batchResult = bulkClient->getBatchResult(updateJob, batchId);
        if batchResult is bulk:Result[] {
            foreach bulk:Result res in batchResult {
                if !res.success {
                    log:printError("Failed result, res=" + res.toString(), err = ());
                }
            }
        } else if batchResult is error {
            log:printError(batchResult.message());
        } else {
            log:printError(batchResult.toString());
        }

        //close job
        error|bulk:JobInfo closedJob = bulkClient->closeJob(updateJob);
        if closedJob is bulk:JobInfo {
            string message = closedJob.state == "Closed" ? "Job Closed Successfully" : "Failed to Close the Job";
            log:printInfo(message);
        } else {
            log:printError(closedJob.message());
        }
    }

}

function getContactIdByName(string firstName, string lastName, string title) returns string|error {
    string contactId = "";
    string sampleQuery = string `SELECT Id FROM Contact WHERE FirstName='${firstName}' AND LastName='${lastName}' 
        AND Title='${title}' LIMIT 1`;
    stream<record {}, error?> queryResults = check baseClient->query(sampleQuery);
    ResultValue|error? result = queryResults.next();
    if result is ResultValue {
        contactId = check result.value.get("Id").ensureType();
    } else {
        log:printError(msg = "Getting Contact ID by name failed.");
    }
    return contactId;
}

type ResultValue record {|
    record {} value;
|};
