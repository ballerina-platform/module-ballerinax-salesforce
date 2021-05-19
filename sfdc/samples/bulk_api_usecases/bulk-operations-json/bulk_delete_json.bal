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

    string id1 = getContactIdByName("Avenra", "Stanis", "Software Engineer Level 1");
    string id2 = getContactIdByName("Irma", "Martin", "Software Engineer Level 1");

    json contactsToDelete = [
        {"Id":id1}, 
        {"Id":id2}
    ];

    sfdc:BulkJob|error deleteJob = baseClient->creatJob("delete", "Contact", "JSON");

    if (deleteJob is sfdc:BulkJob){
        error|sfdc:BatchInfo batch = baseClient->addBatch(deleteJob, contactsToDelete);
        if (batch is sfdc:BatchInfo) {
           string message = batch.id.length() > 0 ? "Contacts Successfully uploaded to delete" :"Failed to upload the Contacts to delete";
           log:printInfo(message);
           batchId = batch.id;
           
        } else {
           log:printError(batch.message());
        }
        
                //get batch info
        error|sfdc:BatchInfo batchInfo = baseClient->getBatchInfo(deleteJob, batchId);
        if (batchInfo is sfdc:BatchInfo) {
            string message = batchInfo.id == batchId ? "Batch Info Received Successfully" :"Failed to Retrieve Batch Info";
            log:printInfo(message);
        } else {
            log:printError(batchInfo.message());
        }

        //get all batches
        error|sfdc:BatchInfo[] batchInfoList = baseClient->getAllBatches(deleteJob);
        if (batchInfoList is sfdc:BatchInfo[]) {
            string message = batchInfoList.length() == 1 ? "All Batches Received Successfully" :"Failed to Retrieve All Batches";
            log:printInfo(message);
        } else {
            log:printError(batchInfoList.message());
        }

        //get batch request
        var batchRequest = baseClient->getBatchRequest(deleteJob, batchId);
        if (batchRequest is json) {
            json[]|error batchRequestArr = <json[]>batchRequest;
            if (batchRequestArr is json[]) {
                string message = batchRequestArr.length() > 0 ? "Batch Request Received Successfully" :"Failed to Retrieve Batch Request";
                log:printInfo(message);
            } else {
                log:printError(batchRequestArr.message());
            }
        } else if (batchRequest is error) {
            log:printError(batchRequest.message());
        } else {
            log:printError(batchRequest.toString());
        }

        //get batch result
        var batchResult = baseClient->getBatchResult(deleteJob, batchId);
        if (batchResult is sfdc:Result[]) {
           string message = batchResult.length() > 0 ? "Batch Result Received Successfully" :"Failed to Retrieve Batch Result";
           log:printInfo(message);
        } else if (batchResult is error) {
            log:printError(batchResult.message());
        } else {
            log:printError(batchResult.toString());
        }

        //close job
        error|sfdc:JobInfo closedJob = baseClient->closeJob(deleteJob);
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

