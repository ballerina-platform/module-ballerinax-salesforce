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

public type Result record {
    string id?;
    boolean success;
    boolean created;
    string errors?;
};

function getBatchResults(xml|json|string batchResult) returns Result[]|SalesforceError {
    if (batchResult is xml) {
        return createBatchResultRecordFromXml(batchResult);
    } else if (batchResult is string) {
        return createBatchResultRecordFromCsv(batchResult);
    } else {
        return createBatchResultRecordFromJson(batchResult);
    }
}

function createBatchResultRecordFromXml(xml payload) returns Result[]| SalesforceError {
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
                        log:printError("Failed batch result, errors=" + errors.toString(), err = ());
                        batchRes.errors = "[" + errors.statusCode.getTextValue() + "] " + errors.message.getTextValue();
                    }
                }
                // Add to batch results array.
                batchResArr[batchResArr.length()] = batchRes;
            } else {
                log:printError("Error occurred while creating BatchResult record.", err = batchRes);
                return getSalesforceError("Error occurred while creating BatchResult record.", 
                    http:STATUS_INTERNAL_SERVER_ERROR.toString());
            }
        } else {
            // log:printInfo("Error occurred while getting batch results.",  err = result);
            log:printError("Error occurred while getting batch results, result=" + result.toString(), ());
            return getSalesforceError("Error occurred while getting batch results.", 
                http:STATUS_INTERNAL_SERVER_ERROR.toString());
        }
    }
    return batchResArr;
}

function createBatchResultRecordFromJson(json payload) returns Result[]|SalesforceError {
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

                if (errors.toString() != "[]") {
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
                log:printError("Error occurred while accessing errors from batch result, errors=" + errors.toString(), 
                    err = ());
                return getSalesforceError("Error occurred while accessing errors from batch result.", 
                    http:STATUS_INTERNAL_SERVER_ERROR.toString());
            }
            batchResArr[batchResArr.length()] = batchRes;
        } else {
            log:printError("Error occurred while creating BatchResult record.", err = batchRes);
            return getSalesforceError("Error occurred while creating BatchResult record.", 
                http:STATUS_INTERNAL_SERVER_ERROR.toString());
        }
        
    }
    return batchResArr;
}

function createBatchResultRecordFromCsv(string payload) returns Result[]|SalesforceError {
    Result[] batchResArr = [];

    handle payloadArr = split(java:fromString(payload), java:fromString("\n"));
    int arrLength = java:getArrayLength(payloadArr);

    int counter = 1;
    while (counter < arrLength) {
        string? line = java:toString(java:getArrayElement(payloadArr, counter));

        if (line is string) {
            handle lineArr = split(java:fromString(line), java:fromString(","));

            string? idStr = java:toString(java:getArrayElement(lineArr, 0));
            string? successStr = java:toString(java:getArrayElement(lineArr, 1));
            string? createdStr = java:toString(java:getArrayElement(lineArr, 2));
            string? errorStr = java:toString(java:getArrayElement(lineArr, 3));

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
                    log:printError("Error occurred while creating BatchResult record, batchRes=" 
                        + batchRes.toString());
                    return getSalesforceError("Error occurred while creating BatchResult record.", 
                        http:STATUS_INTERNAL_SERVER_ERROR.toString());
                }
                
            } else {
                log:printError("Error occurred while accessing success & created fields from batch result, success=" 
                    + successStr.toString() + " created=" + createdStr.toString());
                return getSalesforceError("Error occurred while accessing success & created fields from batch result.", 
                    http:STATUS_INTERNAL_SERVER_ERROR.toString());
            }
        } else {
            log:printError("Error occrred while retrieveing batch result line from batch results csv, line=" 
                + line.toString());
            return getSalesforceError("Error occurred while retrieveing batch result line from batch results csv.", 
                    http:STATUS_INTERNAL_SERVER_ERROR.toString());
        }
        counter = counter + 1;
    }
    return batchResArr;
}
