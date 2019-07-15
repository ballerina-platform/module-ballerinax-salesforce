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

public type Job record {
    string id;
    string operation;
    string ^"object";
    string createdById;
    string createdDate;
    string systemModstamp;
    string state;
    string concurrencyMode;
    string contentType;
    int numberBatchesQueued;
    int numberBatchesInProgress;
    int numberBatchesCompleted;
    int numberBatchesFailed;
    int numberBatchesTotal;
    int numberRecordsProcessed;
    int numberRetries;
    float apiVersion;
    int numberRecordsFailed;
    int totalProcessingTime;
    int apiActiveProcessingTime;
    int apexProcessingTime;
    string externalIdFieldName?;
    boolean fastPathEnabled?;
};

function getJob(xml | json jobDetails) returns Job | SalesforceError {
    if (jobDetails is xml) {
        return createJobRecordFromXml(jobDetails);
    } else {
        return createJobRecordFromJson(jobDetails);
    }
}

function createJobRecordFromXml(xml jobDetails) returns Job | SalesforceError {
    Job | error job = trap {
        id: string.convert(jobDetails.id.getTextValue()),
        operation: jobDetails.operation.getTextValue(),
        ^"object": jobDetails.^"object".getTextValue(),
        createdById: jobDetails.createdById.getTextValue(),
        createdDate: jobDetails.createdDate.getTextValue(),
        systemModstamp: jobDetails.systemModstamp.getTextValue(),
        state: jobDetails.state.getTextValue(),
        concurrencyMode: jobDetails.concurrencyMode.getTextValue(),
        contentType: jobDetails.contentType.getTextValue(),
        numberBatchesQueued: getIntValue(jobDetails.numberBatchesQueued.getTextValue()),
        numberBatchesInProgress: getIntValue(jobDetails.numberBatchesQueued.getTextValue()),
        numberBatchesCompleted: getIntValue(jobDetails.numberBatchesCompleted.getTextValue()),
        numberBatchesFailed: getIntValue(jobDetails.numberBatchesFailed.getTextValue()),
        numberBatchesTotal: getIntValue(jobDetails.numberBatchesTotal.getTextValue()),
        numberRecordsProcessed: getIntValue(jobDetails.numberRecordsProcessed.getTextValue()),
        numberRetries: getIntValue(jobDetails.numberRetries.getTextValue()),
        apiVersion: getFloatValue(jobDetails.apiVersion.getTextValue()),
        numberRecordsFailed: getIntValue(jobDetails.numberRecordsFailed.getTextValue()),
        totalProcessingTime: getIntValue(jobDetails.totalProcessingTime.getTextValue()),
        apiActiveProcessingTime: getIntValue(jobDetails.apiActiveProcessingTime.getTextValue()),
        apexProcessingTime: getIntValue(jobDetails.apexProcessingTime.getTextValue())
    };

    if (job is Job) {
        if (jobDetails.externalIdFieldName.getTextValue().length() > 0) {
            job.externalIdFieldName = jobDetails.externalIdFieldName.getTextValue();
        }
        if (jobDetails.assignmentRuleId.getTextValue().length() > 0) {
            job.assignmentRuleId = jobDetails.assignmentRuleId.getTextValue();
        }
        return job;
    } else {
        SalesforceError sfError = {
            message: "Error occurred when creating Job record from XML response.",
            errorCode: "500"
        };
        return sfError;
    }
}

function createJobRecordFromJson(json jobDetails) returns Job | SalesforceError {
    Job | error job = trap {
        id: jobDetails.id.toString(),
        operation: jobDetails.operation.toString(),
        ^"object": jobDetails.^"object".toString(),
        createdById: jobDetails.createdById.toString(),
        createdDate: jobDetails.createdDate.toString(),
        systemModstamp: jobDetails.systemModstamp.toString(),
        state: jobDetails.state.toString(),
        concurrencyMode: jobDetails.concurrencyMode.toString(),
        contentType: jobDetails.contentType.toString(),
        numberBatchesQueued: getIntValue(jobDetails.numberBatchesQueued.toString()),
        numberBatchesInProgress: getIntValue(jobDetails.numberBatchesQueued.toString()),
        numberBatchesCompleted: getIntValue(jobDetails.numberBatchesCompleted.toString()),
        numberBatchesFailed: getIntValue(jobDetails.numberBatchesFailed.toString()),
        numberBatchesTotal: getIntValue(jobDetails.numberBatchesTotal.toString()),
        numberRecordsProcessed: getIntValue(jobDetails.numberRecordsProcessed.toString()),
        numberRetries: getIntValue(jobDetails.numberRetries.toString()),
        apiVersion: getFloatValue(jobDetails.apiVersion.toString()),
        numberRecordsFailed: getIntValue(jobDetails.numberRecordsFailed.toString()),
        totalProcessingTime: getIntValue(jobDetails.totalProcessingTime.toString()),
        apiActiveProcessingTime: getIntValue(jobDetails.apiActiveProcessingTime.toString()),
        apexProcessingTime: getIntValue(jobDetails.apexProcessingTime.toString())
    };

    if (job is Job) {
        if (jobDetails.externalIdFieldName is string && jobDetails.externalIdFieldName.length() > 0) { 
            job.externalIdFieldName = jobDetails.externalIdFieldName.toString();
        }
        if (jobDetails.assignmentRuleId is string && jobDetails.assignmentRuleId.length() > 0) { 
            job.assignmentRuleId = jobDetails.assignmentRuleId.toString();
        }
        return job;
    } else {
        SalesforceError sfError = {
            message: "Error occurred when creating Job record from JSON response.",
            errorCode: "500"
        };
        return sfError;
    }
}
