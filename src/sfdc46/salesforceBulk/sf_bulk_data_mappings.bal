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

import ballerina/log;
import ballerinax/java;
import ballerinax/java.arrays as jarrays;

function getJob(xml|json jobDetails) returns JobInfo|ConnectorError {
    if (jobDetails is xml) {
        return createJobRecordFromXml(jobDetails);
    } else {
        return createJobRecordFromJson(jobDetails);
    }
}

function createJobRecordFromXml(xml jobDetails) returns JobInfo|ConnectorError {
    JobInfo|error job = trap {
        id: jobDetails.id.getTextValue(),
        operation: jobDetails.operation.getTextValue(),
        'object: jobDetails.'object.getTextValue(),
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

    if (job is JobInfo) {
        // if (jobDetails.externalIdFieldName.getTextValue().length() > 0) {
        //     job.externalIdFieldName = jobDetails.externalIdFieldName.getTextValue();
        // }
        // if (jobDetails.assignmentRuleId.getTextValue().length() > 0) {
        //     job.assignmentRuleId = jobDetails.assignmentRuleId.getTextValue();
        // }
        return job;
    } else {
        string errMsg = "Error occurred while creating JobInfo record using xml payload.";
        log:printError(errMsg, err = job);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = job);
        return typeError;
    }
}

function createJobRecordFromJson(json jobDetails) returns JobInfo|ConnectorError {
    JobInfo|error job = JobInfo.constructFrom(<json> jobDetails);

    if (job is JobInfo) {
        return job;
    } else {
        string errMsg = "Error occurred while creating JobInfo record using json payload.";
        log:printError(errMsg, err = job);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = job);
        return typeError;
    }
}

function getBatch(xml|json batchDetails) returns BatchInfo|ConnectorError {
    if (batchDetails is xml) {
        return createBatchRecordFromXml(batchDetails);
    } else {
        return createBatchRecordFromJson(batchDetails);
    }
}

function createBatchRecordFromXml(xml batchDetails) returns BatchInfo|ConnectorError {
    BatchInfo|error batch = trap {
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
    if (batch is BatchInfo) {
        // if (batchDetails.stateMessage.getTextValue().length() > 0) {
        //     batch.stateMessage = batchDetails.stateMessage.getTextValue();
        // }
        return batch;
    } else {
        string errMsg = "Error occurred while creating BatchInfo record using xml payload.";
        log:printError(errMsg, err = batch);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = batch);
        return typeError;
    }
}

function createBatchRecordFromJson(json batchDetails) returns BatchInfo|ConnectorError {
    BatchInfo|error batch = BatchInfo.constructFrom(batchDetails);

    if (batch is BatchInfo) {
        return batch;
    } else {
        string errMsg = "Error occurred while creating BatchInfo record using json payload.";
        log:printError(errMsg, err = batch);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = batch);
        return typeError;
    }
}

function getBatchInfoList(xml|json batchInfoDetails) returns BatchInfo[]|ConnectorError {
    if(batchInfoDetails is xml) {
        return createBatchInfoListFromXml(batchInfoDetails);
    } else {
        return createBatchInfoListFromJson(batchInfoDetails);
    }
}

function createBatchInfoListFromXml(xml batchInfoDetails) returns BatchInfo[]|ConnectorError {
    BatchInfo[] batchInfoList = [];
    foreach var batchDetails in batchInfoDetails.*.elements() {
        if (batchDetails is xml) {
            BatchInfo|ConnectorError batch = getBatch(batchDetails);
            if (batch is BatchInfo) {
                batchInfoList[batchInfoList.length()] = batch;
            } else {
                string errMsg = "Error occurred while creating Batch info list using xml payload.";
                log:printError(errMsg, err = batch);
                TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
                    errorCode = TYPE_CONVERSION_ERROR, cause = batch);
                return typeError;
            }
        }
    }
    return batchInfoList;
}

function createBatchInfoListFromJson(json batchInfoDetails) returns BatchInfo[]|ConnectorError {
    BatchInfo[] batchInfoList = [];

    json[] batchInfoArr = <json[]>batchInfoDetails.batchInfo;
    foreach json batchInfo in batchInfoArr {
        BatchInfo|ConnectorError batch = getBatch(batchInfo);
        if (batch is BatchInfo) {
            batchInfoList[batchInfoList.length()] = batch;
        } else {
            string errMsg = "Error occurred while creating Batch info list using json payload.";
            log:printError(errMsg, err = batch);
            TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
                errorCode = TYPE_CONVERSION_ERROR, cause = batch);
            return typeError;
        }
    }
    return batchInfoList;
}

function getBatchResults(xml|json|string batchResult) returns Result[]|ConnectorError {
    if (batchResult is xml) {
        return createBatchResultRecordFromXml(batchResult);
    } else if (batchResult is string) {
        return createBatchResultRecordFromCsv(batchResult);
    } else {
        return createBatchResultRecordFromJson(batchResult);
    }
}

function createBatchResultRecordFromXml(xml payload) returns Result[]|ConnectorError {
    Result[] batchResArr = [];

    foreach var result in payload.*.elements() {
        if (result is xml) {
            Result|error batchRes = trap {
                success: getBooleanValue(result[getElementNameWithNamespace("success")].getTextValue()),
                created: getBooleanValue(result[getElementNameWithNamespace("created")].getTextValue())
            };

            if (batchRes is Result) {
                // Check whether ID exists
                if (result.id.getTextValue().length() > 0) {
                    batchRes.id = result.id.getTextValue();
                }
                // Check whether errors exists
                xml|error errors = result.errors;
                if (errors is xml) {

                    if (errors.toString().length() > 0) {
                        log:printInfo("Failed batch result, err=" + errors.toString());
                        batchRes.errors = "[" + errors.statusCode.getTextValue() + "] " + errors.message.getTextValue();
                    }
                }
                // Add to batch results array.
                batchResArr[batchResArr.length()] = batchRes;
            } else {
                string errMsg = "Error occurred while creating BatchResult record using xml payload.";
                log:printError(errMsg, err = batchRes);
                TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
                    errorCode = TYPE_CONVERSION_ERROR, cause = batchRes);
                return typeError;
            }
        } else {
            log:printError(XML_ACCESSING_ERROR_MSG + ", result=" + result.toString(), err = ());
            TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = XML_ACCESSING_ERROR_MSG,
                errorCode = TYPE_CONVERSION_ERROR);
            return typeError;
        }
    }
    return batchResArr;
}

function createBatchResultRecordFromJson(json payload) returns Result[]|ConnectorError {
    Result[] batchResArr = [];
    json[] payloadArr = <json[]> payload;

    foreach json ele in payloadArr {
        Result|error batchRes = trap {
            success: getBooleanValue(ele.success.toString()),
            created: getBooleanValue(ele.created.toString())
        };

        if (batchRes is Result) {
            // Check whether ID exists
            if (ele.id.toString().length() > 0 && ele.id.toString() != "null") {
                batchRes.id = ele.id.toString();
            }
            // Check whether errors exists
            json|error errors = ele.errors;

            if (errors is json) {

                if (trim(errors.toString()).length() > 0) {
                    log:printError("Failed batch result, errors=" + errors.toString(), err = ());
                    json[] errorsArr = <json[]> errors;
                    string errMsg = "";
                    int counter = 1;
                    foreach json err in errorsArr {
                        errMsg = errMsg + "[" + err.statusCode.toString() + "] " + err.message.toString();
                        if (errorsArr.length() != counter) {
                            errMsg = errMsg + ", ";
                        }
                        counter = counter + 1;
                    }
                    batchRes.errors = errMsg;
                }

            } else {
                string errMsg = "Error occurred while accessing errors from batch result.";
                log:printError(errMsg, err = errors);
                TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
                    errorCode = TYPE_CONVERSION_ERROR, cause = errors);
                return typeError;
            }
            batchResArr[batchResArr.length()] = batchRes;
        } else {
            string errMsg = "Error occurred while creating BatchResult record using json payload.";
            log:printError(errMsg, err = batchRes);
            TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
                errorCode = TYPE_CONVERSION_ERROR, cause = batchRes);
            return typeError;
        }

    }
    return batchResArr;
}

function createBatchResultRecordFromCsv(string payload) returns Result[]|ConnectorError {
    Result[] batchResArr = [];

    handle payloadArr = split(java:fromString(payload), java:fromString("\n"));
    int arrLength = jarrays:getLength(payloadArr);

    int counter = 1;
    while (counter < arrLength) {
        string? line = java:toString(jarrays:get(payloadArr, counter));

        if (line is string) {
            handle lineArr = split(java:fromString(line), java:fromString(","));

            string? idStr = java:toString(jarrays:get(lineArr, 0));
            string? successStr = java:toString(jarrays:get(lineArr, 1));
            string? createdStr = java:toString(jarrays:get(lineArr, 2));
            string? errorStr = java:toString(jarrays:get(lineArr, 3));

            // Remove quotes of "true" or "false".
            if (successStr is string && createdStr is string) {
                successStr = java:toString(replace(java:fromString(successStr), java:fromString("\""),
                    java:fromString("")));
                createdStr = java:toString(replace(java:fromString(createdStr), java:fromString("\""),
                    java:fromString("")));
            }

            if (successStr is string && successStr.length() > 0 && createdStr is string && createdStr.length() > 0) {

                Result|error batchRes = trap {
                    success: getBooleanValue(successStr),
                    created: getBooleanValue(createdStr)
                };

                if (batchRes is Result) {
                    if (idStr is string && idStr.length() > 0) {
                        batchRes.id = idStr;
                    }
                    if (errorStr is string && errorStr.length() > 0) {
                        batchRes.errors = errorStr;
                    }
                    // Add batch result to array.
                    batchResArr[batchResArr.length()] = batchRes;
                } else {
                    string errMsg = "Error occurred while creating BatchResult record using csv payload.";
                    log:printError(errMsg, err = batchRes);
                    TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
                        errorCode = TYPE_CONVERSION_ERROR, cause = batchRes);
                    return typeError;
                }

            } else {
                log:printError("Error occurred while accessing success & created fields from batch result, success="
                    + successStr.toString() + " created=" + createdStr.toString(), err = ());
                TypeConversionError typeError = error(TYPE_CONVERSION_ERROR,
                    message = "Error occurred while creating BatchResult record using json payload.",
                    errorCode = TYPE_CONVERSION_ERROR);
            return typeError;
            }
        } else {
            log:printError("Error occrred while retrieveing batch result line from batch results csv, line="
                + line.toString(), err = ());
            TypeConversionError typeError = error(TYPE_CONVERSION_ERROR,
                message = "Error occurred while accessing batch results from csv payload.",
                errorCode = TYPE_CONVERSION_ERROR);
            return typeError;
        }
        counter = counter + 1;
    }
    return batchResArr;
}

function getResultList(xml|json resultListDetails) returns string[]|ConnectorError {
    if(resultListDetails is xml){
        return createResultListRecordFromXml(resultListDetails);
    }else{
        return createResultListRecordFromJson(resultListDetails);
    }
}

function createResultListRecordFromXml(xml payload) returns string[]|ConnectorError {
    string[] results = [];
    foreach var result in payload.*.elements() {
        if (result is xml) {
            string|error resultId = result.getTextValue();
            if (resultId is string) {
                results[results.length()] = resultId;
            } else {
                log:printError("Error occrred while retrieveing batch result ID from batch result.", err = resultId);
                TypeConversionError typeError = error(TYPE_CONVERSION_ERROR,
                    message = "Error occrred while retrieveing batch result ID from batch result.",
                    errorCode = TYPE_CONVERSION_ERROR);
                return typeError;
            }
        }
    }
    return results;
}

function createResultListRecordFromJson(json payload) returns string[]|ConnectorError {
    string[] results = [];
    json[] resultsArr = <json[]>payload;

    foreach json result in resultsArr {
        string resultId = result.toString();
        results[results.length()] = resultId;
    }
    return results;
}
