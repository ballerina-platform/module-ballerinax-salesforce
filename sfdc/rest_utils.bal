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
import ballerina/url;

# Returns the prepared URL.
# 
# + paths - An array of paths prefixes
# + return - The prepared URL
isolated function prepareUrl(string[] paths) returns string {
    string url = EMPTY_STRING;

    if (paths.length() > 0) {
        foreach var path in paths {
            if (!path.startsWith(FORWARD_SLASH)) {
                url = url + FORWARD_SLASH;
            }
            url = url + path;
        }
    }
    return <@untainted>url;
}

# Returns the prepared URL with encoded query.
# 
# + paths - An array of paths prefixes
# + queryParamNames - An array of query param names
# + queryParamValues - An array of query param values
# + return - The prepared URL with encoded query
isolated function prepareQueryUrl(string[] paths, string[] queryParamNames, string[] queryParamValues) returns string {
    string url = prepareUrl(paths);

    url = url + QUESTION_MARK;
    boolean first = true;
    int i = 0;
    foreach var name in queryParamNames {
        string value = queryParamValues[i];
        var encoded = url:encode(value, ENCODING_CHARSET);

        if (encoded is string) {
            if (first) {
                url = url + name + EQUAL_SIGN + encoded;
                first = false;
            } else {
                url = url + AMPERSAND + name + EQUAL_SIGN + encoded;
            }
        } else {
            log:printError("Unable to encode value: " + value, 'error = encoded);
            break;
        }
        i = i + 1;
    }
    return url;
}

# Check HTTP response and return JSON payload if succesful, else set errors and return Error.
# 
# + httpResponse - HTTP respone or Error
# + expectPayload - Payload is expected or not
# + return - JSON result if successful, else Error occured
isolated function checkAndSetErrors(http:Response|http:PayloadType|error httpResponse, boolean expectPayload = true) 
                                    returns @tainted json|Error {
    if (httpResponse is http:Response) {
        if (httpResponse.statusCode == http:STATUS_OK || httpResponse.statusCode == http:STATUS_CREATED || 
            httpResponse.statusCode == http:STATUS_NO_CONTENT) {
            if (expectPayload) {
                json|error jsonResponse = httpResponse.getJsonPayload();

                if (jsonResponse is json) {
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

            if (jsonResponse is json) {
                json[] errArr = <json[]>jsonResponse;
                string errCodes = "";
                string errMssgs = "";
                int counter = 1;

                foreach json err in errArr {
                    json|error errorCode = err.errorCode;
                    json|error errMessage = err.message;
                    if (errorCode is json && errMessage is json) {
                        errCodes = errCodes + errorCode.toString();
                        errMssgs = errMssgs + errMessage.toString();
                        if (counter != errArr.length()) {
                            errCodes = errCodes + ", ";
                            errMssgs = errMssgs + ", ";
                        }
                        counter = counter + 1;
                    }
                }
                return error Error(errMssgs, errorCodes = errCodes);
            } else {
                log:printError(ERR_EXTRACTING_ERROR_MSG, 'error = jsonResponse);
                return error Error(ERR_EXTRACTING_ERROR_MSG, jsonResponse);
            }
        }
    } else if (httpResponse is http:PayloadType) {
        return error Error(UNREACHABLE_STATE);
    } else {
        log:printError(HTTP_ERROR_MSG, 'error = httpResponse);
        return error Error(HTTP_ERROR_MSG, httpResponse);
    }
}
