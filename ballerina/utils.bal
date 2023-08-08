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

# Check HTTP response and return JSON payload if succesful, else set errors and return Error.
#
# + httpResponse - HTTP respone or Error
# + expectPayload - Payload is expected or not
# + return - JSON result if successful, else Error occured
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
