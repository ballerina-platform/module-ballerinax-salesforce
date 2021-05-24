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
import ballerinax/sfdc;

// Create Salesforce client configuration by reading from config file.
sfdc:SalesforceConfiguration sfConfig = {
    baseUrl: "<BASE_URL>",
    clientConfig: {
        clientId: "<CLIENT_ID>",
        clientSecret: "<CLIENT_SECRET>",
        refreshToken: "<REFESH_TOKEN>",
        refreshUrl: "<REFRESH_URL>"
    }
};

// Create Salesforce client.
sfdc:Client baseClient = checkpanic new(sfConfig);

public function main(){

    string batchId = "";

    string id1 = getContactIdByName("Wanda", "Davidson", "Software Engineer Level 3");
    string id2 = getContactIdByName("Natasha", "Romenoff", "Software Engineer Level 3");

    xml contacts = xml `<sObjects xmlns="http://www.force.com/2009/06/asyncapi/dataload">
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <Id>${id1}</Id>
            <FirstName>Wanda</FirstName>
            <LastName>Davidson</LastName>
            <Title>Software Engineer Level 3</Title>
            <Phone>0991161283</Phone>
            <Email>wanda67@yahoo.com</Email>
            <My_External_Id__c>864</My_External_Id__c>
            <Department>Finance</Department>
        </sObject>
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <Id>${id2}</Id>
            <FirstName>Natasha</FirstName>
            <LastName>Romenoff</LastName>
            <Title>Software Engineer Level 3</Title>
            <Phone>0867556843</Phone>
            <Email>natashaRom@gmail.com</Email>
            <My_External_Id__c>865</My_External_Id__c>
            <Department>Finance</Department>
        </sObject>
    </sObjects>`;
    

    sfdc:BulkJob|error updateJob = baseClient->creatJob("upsert", "Contact", "XML","My_External_Id__c");

    if (updateJob is sfdc:BulkJob){
        error|sfdc:BatchInfo batch = baseClient->addBatch(updateJob, <@untainted>contacts);
        if (batch is sfdc:BatchInfo) {
            batchId = batch.id;
            string message = batch.id.length() > 0 ? "Batch added to upsert Successfully" :"Failed to add the batch";
            log:printInfo(message);
        } else {
           log:printError(batch.message());
        }

        //get job info
        error|sfdc:JobInfo jobInfo = baseClient->getJobInfo(updateJob);
        if (jobInfo is sfdc:JobInfo) {
            string message = jobInfo.id.length() > 0 ? "Jon Info Received Successfully" :"Failed Retrieve Job Info";
            log:printInfo(message);
        } else {
            log:printError(jobInfo.message());
        }

        //get batch info
        error|sfdc:BatchInfo batchInfo = baseClient->getBatchInfo(updateJob, batchId);
        if (batchInfo is sfdc:BatchInfo) {
            string message = batchInfo.id == batchId ? "Batch Info Received Successfully" :"Failed to Retrieve Batch Info";
            log:printInfo(message);
        } else {
            log:printError(batchInfo.message());
        }

        //get all batches
        error|sfdc:BatchInfo[] batchInfoList = baseClient->getAllBatches(updateJob);
        if (batchInfoList is sfdc:BatchInfo[]) {
            string message = batchInfoList.length() == 1 ? "All Batches Received Successfully" :"Failed to Retrieve All Batches";
            log:printInfo(message);
        } else {
            log:printError(batchInfoList.message());
        }

        //get batch request
        var batchRequest = baseClient->getBatchRequest(updateJob, batchId);
        if (batchRequest is xml) {
            string message = (batchRequest/<*>).length() > 0 ? "Batch Request Received Successfully" :"Failed to Retrieve Batch Request";
            log:printInfo(message);
            
        } else if (batchRequest is error) {
            log:printError(batchRequest.message());
        } else {
            log:printError(batchRequest.toString());
        }

        //get batch result
        var batchResult = baseClient->getBatchResult(updateJob, batchId);
        if (batchResult is sfdc:Result[]) {
            foreach sfdc:Result res in batchResult {
                if (!res.success) {
                    log:printError("Failed result, res=" + res.toString(), err = ());
                }
            }
        } else if (batchResult is error) {
            log:printError(batchResult.message());
        } else {
            log:printError(batchResult.toString());
        }

        //close job
        error|sfdc:JobInfo closedJob = baseClient->closeJob(updateJob);
        if (closedJob is sfdc:JobInfo) {
            string message = closedJob.state == "Closed" ? "Job Closed Successfully" :"Failed to Close the Job";
            log:printInfo(message);
        } else {
            log:printError(closedJob.message());
        }
    }

}

function getContactIdByName(string firstName, string lastName, string title) returns @tainted string {
    string contactId = "";
    string sampleQuery = "SELECT Id FROM Contact WHERE FirstName='" + firstName + "' AND LastName='" + lastName 
        + "' AND Title='" + title + "'";
    sfdc:SoqlResult|sfdc:Error res = baseClient->getQueryResult(sampleQuery);

    if (res is sfdc:SoqlResult) {
        sfdc:SoqlRecord[]|error records = res.records;
        if (records is sfdc:SoqlRecord[]) {
            string id = records[0]["Id"].toString();
            contactId = id;
        } else {
            log:printInfo("Getting contact ID by name failed. err=" + records.toString());            
        }
    } else {
        log:printInfo("Getting contact ID by name failed. err=" + res.toString());
    }
    return contactId;
}



