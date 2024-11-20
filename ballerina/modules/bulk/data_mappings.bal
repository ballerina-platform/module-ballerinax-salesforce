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

import ballerina/log;

isolated function createJobRecordFromXml(xml jobDetails) returns JobInfo|error {
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

    if job is JobInfo {
        if (jobDetails/<ns:externalIdFieldName>/*).length() > 0 {
            job["externalIdFieldName"] = (jobDetails/<ns:externalIdFieldName>/*).toString();
        }
        if (jobDetails/<ns:assignmentRuleId>/*).length() > 0 {
            job["assignmentRuleId"] = (jobDetails/<ns:assignmentRuleId>/*).toString();
        }
        return job;
    } else {
        string errMsg = "Error occurred while creating JobInfo record using xml payload.";
        log:printError(errMsg, 'error = job);
        return error(errMsg, job);
    }
}

isolated function createBatchRecordFromXml(xml batchDetails) returns BatchInfo|error {
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
    if batch is BatchInfo {
        if (batchDetails/<ns:stateMessage>/*).length() > 0 {
            batch["stateMessage"] = (batchDetails/<ns:stateMessage>/*).toString();
        }
        return batch;
    } else {
        string errMsg = "Error occurred while creating BatchInfo record using xml payload.";
        log:printError(errMsg, 'error = batch);
        return error(errMsg, batch);
    }
}

isolated function createBatchResultRecordFromXml(xml payload) returns Result[]|error {
    Result[] batchResultArray = [];
    xmlns "http://www.force.com/2009/06/asyncapi/dataload" as ns;
    foreach var result in payload/<*> {
        Result batchResult = {
            id: (result/<ns:id>/*).toString(),
            success: getBooleanValue((result/<ns:success>/*).toString()),
            created: getBooleanValue((result/<ns:created>/*).toString())
        };
        // Check whether an error occured.
        xml|error errors = result/<ns:errors>;
        if errors is xml {
            batchResult.errors = (errors/<ns:statusCode>/*).toString() + " : " + (errors/<ns:message>/*).toString();
        }
        // Add to the batch results array.
        batchResultArray.push(batchResult);
    }
    return batchResultArray;
}

isolated function createBatchResultRecordFromJson(json payload) returns Result[]|error {
    Result[] batchResultArray = [];
    json[] payloadArr = <json[]>payload;
    foreach json element in payloadArr {
        Result batchResult =  {
            id: let var id = element.id in id is json ? id.toString() : EMPTY_STRING,
            success: let var success = element.success in success is boolean ? success : false,
            created: let var created = element.created in created is boolean ? created : false
        }; 
        // Check whether an error occured.
        json|error errors = element.errors;

        if errors is json {
            json[] errorsArr = <json[]>errors;
            string errMsg = EMPTY_STRING;
            foreach json err in errorsArr {
                json|error errStatusCode = err.statusCode;
                json|error errMessage = err.message;
                if errStatusCode is json && errMessage is json {
                    errMsg = errMsg  + errStatusCode.toString() + " : " + errMessage.toString();
                }
            }
            batchResult.errors = errMsg;
        } else {
            string errMsg = "Error occurred while accessing errors from batch result.";
            log:printError(errMsg, 'error = errors);
            return error(errMsg, errors);
        }
        batchResultArray.push(batchResult);
    }
    return batchResultArray;
}

isolated function createBatchResultRecordFromCsv(string payload) returns Result[]|error {
    Result[] batchResArr = [];
    string[] payloadArr = re `\n`.split(payload);
    int arrLength = payloadArr.length();
    int counter = 1;
    while (counter < arrLength) {
        string? line = payloadArr[counter];
        if line is string {
            if line == EMPTY_STRING && counter == (arrLength - 1) {
                counter += 1;
                continue;
            }
            string[] lineArr = re `${COMMA}`.split(line);
            string? idStr = lineArr[0];
            string? successStr = lineArr[1];
            string? createdStr = lineArr[2];
            string? errorStr = lineArr[3];

            // Remove quotes of "true" or "false".
            if successStr is string && createdStr is string {
                successStr = re `"`.replaceAll(successStr, EMPTY_STRING);
                createdStr = re `"`.replaceAll(createdStr, EMPTY_STRING);
            }

            if successStr is string && successStr.length() > 0 && createdStr is string && createdStr.length() > 0 {
                Result|error batchRes = trap {
                    success: getBooleanValue(successStr),
                    created: getBooleanValue(createdStr)
                };

                if batchRes is Result {
                    if idStr is string && idStr.length() > 0 {
                        batchRes.id = idStr;
                    }
                    if errorStr is string && errorStr.length() > 0 {
                        batchRes.errors = errorStr;
                    }
                    // Add batch result to array.
                    batchResArr[batchResArr.length()] = batchRes;
                } else {
                    string errMsg = "Error occurred while creating BatchResult record using csv payload.";
                    log:printError(errMsg, 'error = batchRes);
                    return error(errMsg, batchRes);
                }
            } else {
                log:printError("Error occurred while accessing success & created fields from batch result, success="
                    + successStr.toString() + " created=" + createdStr.toString(), err = ());
                return error("Error occurred while creating BatchResult record using json payload.");
            }
        } else {
            log:printError("Error occrred while retrieveing batch result line from batch results csv, line="
                + line.toString(), err = ());
            return error("Error occurred while accessing batch results from csv payload.");
        }
        counter = counter + 1;
    }
    return batchResArr;
}
