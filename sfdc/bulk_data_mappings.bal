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
import ballerina/regex;

isolated function createJobRecordFromXml(xml jobDetails) returns JobInfo|Error {
    xmlns "http://www.force.com/2009/06/asyncapi/dataload" as ns;

    JobInfo|error job = trap {
        id: (jobDetails/<ns:id>/*).toString(),
        operation: (jobDetails/<ns:operation>/*).toString(),
        'object: (jobDetails/<ns:'object>/*).toString(),
        createdById: (jobDetails/<ns:createdById>/*).toString(),
        createdDate: (jobDetails/<ns:createdDate>/*).toString(),
        systemModstamp: (jobDetails/<ns:systemModstamp>/*).toString(),
        state: (jobDetails/<ns:state>/*).toString(),
        concurrencyMode: (jobDetails/<ns:concurrencyMode>/*).toString(),
        contentType: (jobDetails/<ns:contentType>/*).toString(),
        numberBatchesQueued: getIntValue((jobDetails/<ns:numberBatchesQueued>/*).toString()),
        numberBatchesInProgress: getIntValue((jobDetails/<ns:numberBatchesQueued>/*).toString()),
        numberBatchesCompleted: getIntValue((jobDetails/<ns:numberBatchesCompleted>/*).toString()),
        numberBatchesFailed: getIntValue((jobDetails/<ns:numberBatchesFailed>/*).toString()),
        numberBatchesTotal: getIntValue((jobDetails/<ns:numberBatchesTotal>/*).toString()),
        numberRecordsProcessed: getIntValue((jobDetails/<ns:numberRecordsProcessed>/*).toString()),
        numberRetries: getIntValue((jobDetails/<ns:numberRetries>/*).toString()),
        apiVersion: getFloatValue((jobDetails/<ns:apiVersion>/*).toString()),
        numberRecordsFailed: getIntValue((jobDetails/<ns:numberRecordsFailed>/*).toString()),
        totalProcessingTime: getIntValue((jobDetails/<ns:totalProcessingTime>/*).toString()),
        apiActiveProcessingTime: getIntValue((jobDetails/<ns:apiActiveProcessingTime>/*).toString()),
        apexProcessingTime: getIntValue((jobDetails/<ns:apexProcessingTime>/*).toString())
    };

    if (job is JobInfo) {
        if ((jobDetails/<ns:externalIdFieldName>/*).length() > 0) {
            job["externalIdFieldName"] = (jobDetails/<ns:externalIdFieldName>/*).toString();
        }
        if ((jobDetails/<ns:assignmentRuleId>/*).length() > 0) {
            job["assignmentRuleId"] = (jobDetails/<ns:assignmentRuleId>/*).toString();
        }
        return job;
    } else {
        string errMsg = "Error occurred while creating JobInfo record using xml payload.";
        log:printError(errMsg, 'error = job);
        return error Error(errMsg, job);
    }
}

isolated function createBatchRecordFromXml(xml batchDetails) returns BatchInfo|Error {
    xmlns "http://www.force.com/2009/06/asyncapi/dataload" as ns;

    BatchInfo|error batch = trap {
        id: (batchDetails/<ns:id>/*).toString(),
        jobId: (batchDetails/<ns:jobId>/*).toString(),
        state: (batchDetails/<ns:state>/*).toString(),
        createdDate: (batchDetails/<ns:createdDate>/*).toString(),
        systemModstamp: (batchDetails/<ns:systemModstamp>/*).toString(),
        numberRecordsProcessed: getIntValue((batchDetails/<ns:numberRecordsProcessed>/*).toString()),
        numberRecordsFailed: getIntValue((batchDetails/<ns:numberRecordsFailed>/*).toString()),
        totalProcessingTime: getIntValue((batchDetails/<ns:totalProcessingTime>/*).toString()),
        apiActiveProcessingTime: getIntValue((batchDetails/<ns:apiActiveProcessingTime>/*).toString()),
        apexProcessingTime: getIntValue((batchDetails/<ns:apexProcessingTime>/*).toString())
    };
    if (batch is BatchInfo) {
        if ((batchDetails/<ns:stateMessage>/*).length() > 0) {
            batch["stateMessage"] = (batchDetails/<ns:stateMessage>/*).toString();
        }
        return batch;
    } else {
        string errMsg = "Error occurred while creating BatchInfo record using xml payload.";
        log:printError(errMsg, 'error = batch);
        return error Error(errMsg, batch);
    }
}

isolated function createBatchResultRecordFromXml(xml payload) returns Result[]|Error {
    Result[] batchResArr = [];
    xmlns "http://www.force.com/2009/06/asyncapi/dataload" as ns;
    foreach var result in payload/<*> {
        Result|error batchRes = trap {
            success: getBooleanValue((result/<ns:success>/*).toString()),
            created: getBooleanValue((result/<ns:created>/*).toString())
        };

        if (batchRes is Result) {
            // Check whether the ID exists,
            if ((result/<ns:id>/*).length() > 0) {
                batchRes.id = (result/<ns:id>/*).toString();
            }
            // Check whether an error occured.
            xml|error errors = result/<ns:errors>/*;
            if (errors is xml) {

                if ((errors/<*>).length() > 0) {
                    log:printInfo("Failed batch result, err=" + (errors/<*>).toString());
                    batchRes.errors = "[" + (errors/<ns:statusCode>/*).toString() + "] " + (errors/<ns:message>/*).
                    toString();
                }
            }
            // Add to the batch results array.
            batchResArr[batchResArr.length()] = batchRes;
        } else {
            string errMsg = "Error occurred while creating BatchResult record using xml payload.";
            log:printError(errMsg, 'error = batchRes);
            return error Error(errMsg, batchRes);
        }
    }
    return batchResArr;
}

isolated function createBatchResultRecordFromJson(json payload) returns Result[]|Error|error {
    Result[] batchResArr = [];
    json[] payloadArr = <json[]>payload;

    foreach json ele in payloadArr {
        json eleSuccess = check ele.success;
        json eleCreated = check ele.created;
        //if(eleSuccess is json && eleCreated is json){
        Result|error batchRes = trap {
            success: getBooleanValue(eleSuccess.toString()),
            created: getBooleanValue(eleCreated.toString())
        };

        if (batchRes is Result) {
            // Check whether the ID exists.
            json|error eleId = ele.id;
            if (eleId is json && eleId.toString().length() > 0 && eleId.toString() != "null") {
                batchRes.id = eleId.toString();
            }
            // Check whether an error occured.
            json|error errors = ele.errors;

            if (errors is json) {

                if (errors.toString().trim().length() > 2) {
                    log:printError("Failed batch result, errors=" + errors.toString(), err = ());
                    json[] errorsArr = <json[]>errors;
                    string errMsg = "";
                    int counter = 1;
                    foreach json err in errorsArr {
                        json|error errStatusCode = err.statusCode;
                        json|error errMessage = err.message;
                        if (errStatusCode is json && errMessage is json) {
                            errMsg = errMsg + "[" + errStatusCode.toString() + "] " + errMessage.toString();
                            if (errorsArr.length() != counter) {
                                errMsg = errMsg + ", ";
                            }
                            counter = counter + 1;
                        }
                    }
                    batchRes.errors = errMsg;
                }

            } else {
                string errMsg = "Error occurred while accessing errors from batch result.";
                log:printError(errMsg, 'error = errors);
                return error Error(errMsg, errors);
            }
            batchResArr[batchResArr.length()] = batchRes;
        } else {
            string errMsg = "Error occurred while creating BatchResult record using json payload.";
            log:printError(errMsg, 'error = batchRes);
            return error Error(errMsg, batchRes);
        }
    //}
    }
    return batchResArr;
}

isolated function createBatchResultRecordFromCsv(string payload) returns Result[]|Error {
    Result[] batchResArr = [];

    string[] payloadArr = regex:split(payload, "\n");
    int arrLength = payloadArr.length();

    int counter = 1;
    while (counter < arrLength) {
        string? line = payloadArr[counter];

        if (line is string) {
            string[] lineArr = regex:split(line, ",");

            string? idStr = lineArr[0];
            string? successStr = lineArr[1];
            string? createdStr = lineArr[2];
            string? errorStr = lineArr[3];

            // Remove quotes of "true" or "false".
            if (successStr is string && createdStr is string) {
                successStr = regex:replaceAll(successStr, "\"", "");
                createdStr = regex:replaceAll(createdStr, "\"", "");
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
                    log:printError(errMsg, 'error = batchRes);
                    return error Error(errMsg, batchRes);
                }

            } else {
                log:printError("Error occurred while accessing success & created fields from batch result, success=" + 
                successStr.toString() + " created=" + createdStr.toString(), err = ());
                return error Error("Error occurred while creating BatchResult record using json payload.");
            }
        } else {
            log:printError("Error occrred while retrieveing batch result line from batch results csv, line=" + line.
            toString(), err = ());
            return error Error("Error occurred while accessing batch results from csv payload.");
        }
        counter = counter + 1;
    }
    return batchResArr;
}
