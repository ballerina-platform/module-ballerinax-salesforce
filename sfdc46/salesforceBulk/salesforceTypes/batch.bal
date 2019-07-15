//
// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
//

public type Batch record {
    string id;
    string jobId;
    string state;
    string createdDate;
    string systemModstamp;
    int numberRecordsProcessed;
    int numberRecordsFailed;
    int totalProcessingTime;
    int apiActiveProcessingTime;
    int apexProcessingTime;
};

function getBatch(xml|json batchDetails) returns Batch|SalesforceError {
    if (batchDetails is xml) {
        return createBatchRecordFromXml(batchDetails);
    } else {
        return createBatchRecordFromJson(batchDetails);
    }
}

function createBatchRecordFromXml(xml batchDetails) returns Batch | SalesforceError {
    Batch | error batch = trap {
        id: batchDetails[getElementNameWithNamespace("id")].getTextValue(),
        jobId: batchDetails[getElementNameWithNamespace("jobId")].getTextValue(),
        state: batchDetails[getElementNameWithNamespace("state")].getTextValue(),
        createdDate: batchDetails[getElementNameWithNamespace("createdDate")].getTextValue(),
        systemModstamp: batchDetails[getElementNameWithNamespace("systemModstamp")].getTextValue(),
        numberRecordsProcessed: 
        getIntValue(batchDetails[getElementNameWithNamespace("numberRecordsProcessed")].getTextValue()),
        numberRecordsFailed: 
        getIntValue(batchDetails[getElementNameWithNamespace("numberRecordsFailed")].getTextValue()),
        totalProcessingTime: 
        getIntValue(batchDetails[getElementNameWithNamespace("totalProcessingTime")].getTextValue()),
        apiActiveProcessingTime: 
        getIntValue(batchDetails[getElementNameWithNamespace("apiActiveProcessingTime")].getTextValue()),
        apexProcessingTime: 
        getIntValue(batchDetails[getElementNameWithNamespace("apexProcessingTime")].getTextValue())
    };
    if (batch is Batch) {
        return batch;
    } else {
        SalesforceError sfError = {
            message: "Error occurred when creating Batch record from XML response.",
            errorCode: "500"
        };
        return sfError;
    }
}

function createBatchRecordFromJson(json batchDetails) returns Batch | SalesforceError {
    Batch | error batch = trap {
        id: batchDetails["id"].toString(),
        jobId: batchDetails["jobId"].toString(),
        state: batchDetails["state"].toString(),
        createdDate: batchDetails["createdDate"].toString(),
        systemModstamp: batchDetails["systemModstamp"].toString(),
        numberRecordsProcessed: getIntValue(batchDetails["numberRecordsProcessed"].toString()),
        numberRecordsFailed: getIntValue(batchDetails["numberRecordsFailed"].toString()),
        totalProcessingTime: getIntValue(batchDetails["totalProcessingTime"].toString()),
        apiActiveProcessingTime: getIntValue(batchDetails["apiActiveProcessingTime"].toString()),
        apexProcessingTime: getIntValue(batchDetails["apexProcessingTime"].toString())
    };
    if (batch is Batch) {
        return batch;
    } else {
        SalesforceError sfError = {
            message: "Error occurred when creating Batch record from JSON response.",
            errorCode: "500"
        };
        return sfError;
    }
}
