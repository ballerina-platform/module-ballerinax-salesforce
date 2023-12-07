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
import ballerina/http;
import ballerina/time;
import ballerina/io;
import ballerina/lang.'string as strings;

# Check HTTP response and return JSON payload if succesful, else set errors and return Error.
#
# + httpResponse - HTTP respone or Error
# + expectPayload - Payload is expected or not
# + return - JSON result if successful, else Error occured
# 
isolated string csvContent = EMPTY_STRING;

isolated function checkAndSetErrors(http:Response|error httpResponse, boolean expectPayload = true) 
                                    returns json|Error {
    if httpResponse is http:Response {
        if httpResponse.statusCode == http:STATUS_OK || httpResponse.statusCode == http:STATUS_CREATED || httpResponse.
        statusCode == http:STATUS_NO_CONTENT {
            if expectPayload {
                json|error jsonResponse = httpResponse.getJsonPayload();

                if jsonResponse is json {
                    return jsonResponse;
                } else {
                    log:printError(JSON_ACCESSING_ERROR_MSG, 'error = jsonResponse);
                    return error Error(JSON_ACCESSING_ERROR_MSG, jsonResponse);
                }

            } else {
                json result = {};
                return result;
            }

        } else {
            json|error jsonResponse = httpResponse.getJsonPayload();

            if jsonResponse is json {
                json[] errArr = <json[]>jsonResponse;
                string errCodes = "";
                string errMssgs = "";
                int counter = 1;

                foreach json err in errArr {
                    json|error errorCode = err.errorCode;
                    json|error errMessage = err.message;
                    if errorCode is json && errMessage is json {
                        errCodes = errCodes + errorCode.toString();
                        errMssgs = errMssgs + errMessage.toString();
                        if counter != errArr.length() {
                            errCodes = errCodes + ", ";
                            errMssgs = errMssgs + ", ";
                        }
                        counter = counter + 1;
                    }
                }
                return error Error(errMssgs);
            } else {
                log:printError(ERR_EXTRACTING_ERROR_MSG, 'error = jsonResponse);
                return error Error(ERR_EXTRACTING_ERROR_MSG, jsonResponse);
            }
        }
    } else {
        return error Error(HTTP_ERROR_MSG, httpResponse);
    }
}

# Convert http:Response to an error of type Error
#
# + response - HTTP error respone
# + return - Error
isolated function checkAndSetErrorDetail(http:ClientError response) returns Error {
    if response is http:ApplicationResponseError {
        ErrorDetails detail = {
            statusCode: response.detail()[STATUS_CODE],
            headers: response.detail()[HEADERS],
            body: response.detail()[BODY]
        };
        return error Error(HTTP_CLIENT_ERROR, response, statusCode = detail?.statusCode, body = detail?.body, 
            headers = detail?.headers); 
    } else {       
        return error Error(HTTP_CLIENT_ERROR, response); 
    }
}

# remove decimal places from a civil seconds value
# 
# + civilTime - a time:civil record
# + return - a time:civil record with decimal places removed
# 
isolated function removeDecimalPlaces(time:Civil civilTime) returns time:Civil {
    time:Civil result = civilTime;
    time:Seconds seconds= (result.second is ())? 0 : <time:Seconds>result.second;
    decimal ceiling = decimal:ceiling(seconds);
    result.second = ceiling;
    return result;
} 


# Convert ReadableByteChannel to string.
#
# + rbc - ReadableByteChannel
# + return - converted string
isolated function convertToString(io:ReadableByteChannel rbc) returns string|error {
    byte[] readContent;
    string textContent = EMPTY_STRING;
    while (true) {
        byte[]|io:Error result = rbc.read(1000);
        if result is io:EofError {
            break;
        } else if result is io:Error {
            string errMsg = "Error occurred while reading from Readable Byte Channel.";
            log:printError(errMsg, 'error = result);
            return error(errMsg, result);
        } else {
            readContent = result;
            string|error readContentStr = strings:fromBytes(readContent);
            if readContentStr is string {
                textContent = textContent + readContentStr;
            } else {
                string errMsg = "Error occurred while converting readContent byte array to string.";
                log:printError(errMsg, 'error = readContentStr);
                return error(errMsg, readContentStr);
            }
        }
    }
    return textContent;
}


# Convert string[][] to string.
#
# + stringCsvInput - Multi dimentional array of strings
# + return - converted string
isolated function convertStringListToString(string[][]|stream<string[], error?> stringCsvInput) returns string|error {
    lock {
        csvContent = EMPTY_STRING;
    }
    if stringCsvInput is string[][] {
        foreach var row in stringCsvInput {
            lock {
                csvContent += row.reduce(isolated function (string s, string t) returns string { 
                    return s.concat(COMMA, t);
                }, EMPTY_STRING).substring(1) + NEW_LINE;
            }
        }
    } else {
        check stringCsvInput.forEach(isolated function(string[] row) {
            lock {
                csvContent += row.reduce(isolated function (string s, string t) returns string { 
                    return s.concat(COMMA, t);
                }, EMPTY_STRING).substring(1) + NEW_LINE;

            }
        });
    }
    lock {
        return csvContent;
    }
}
