//
// Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/mime;
import ballerina/http;

documentation { Returns the prepared URL
    P{{paths}} an array of paths prefixes
    R{{url}} the prepared URL
}
function prepareUrl(string[] paths) returns string {
    string url = EMPTY_STRING;

    if (paths != null) {
        foreach path in paths {
            if (!path.hasPrefix(FORWARD_SLASH)) {
                url = url + FORWARD_SLASH;
            }
            url = url + path;
        }
    }
    return url;
}

documentation { Returns the prepared URL with encoded query
    P{{paths}} an array of paths prefixes
    P{{queryParamNames}} an array of query param names
    P{{queryParamValues}} an array of query param values
    R{{url}} the prepared URL with encoded query
}
function prepareQueryUrl(string[] paths, string[] queryParamNames, string[] queryParamValues) returns string {

    string url = prepareUrl(paths);

    url = url + QUESTION_MARK;
    boolean first = true;
    foreach i, name in queryParamNames {
        string value = queryParamValues[i];

        var oauth2Response = http:encode(value, ENCODING_CHARSET);
        match oauth2Response {
            string encoded => {
                if (first) {
                    url = url + name + EQUAL_SIGN + encoded;
                    first = false;
                } else {
                    url = url + AMPERSAND + name + EQUAL_SIGN + encoded;
                }
            }
            error e => {
                log:printError("Unable to encode value: " + value, err = e);
                break;
            }
        }
    }

    return url;
}

documentation { Returns the JSON result or SalesforceConnectorError
    P{{response}} HTTP respone or HttpConnectorError
    P{{expectPayload}} true if json payload expected in response, if not false
    R{{result}} JSON result if successful, else SalesforceConnectorError occured
}
function checkAndSetErrors(http:Response|http:HttpConnectorError response, boolean expectPayload)
    returns json|SalesforceConnectorError {
    json result = {};

    match response {
        http:Response httpResponse => {
            //if success
            if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201 || httpResponse.statusCode == 204) {
                if (expectPayload) {
                    match httpResponse.getJsonPayload() {
                        json jsonResponse => {
                            return jsonResponse;
                        }
                        http:PayloadError payloadErr => {
                            log:printError("Error occurred when extracting JSON payload. Error: " + payloadErr.message);
                            SalesforceConnectorError connectorError = {message:"", salesforceErrors:[]};
                            connectorError.message = "Error occured while extracting Json payload!";
                            connectorError.cause = payloadErr;
                            return connectorError;
                        }
                    }
                }
            } else {
                SalesforceConnectorError connectorError = {message:"", salesforceErrors:[]};

                match httpResponse.getJsonPayload() {
                    json jsonResponse => {
                        json[]|error res = < json[]>jsonResponse;

                        match res {
                            json[] errors => {
                                foreach i, err in errors {
                                    SalesforceError sfError = {message:err.message.toString(), errorCode:err.errorCode.toString()};
                                    connectorError.message = err.message.toString();
                                    connectorError.cause = {message:err.message.toString()};
                                    connectorError.salesforceErrors[i] = sfError;
                                }
                                return connectorError;
                            }
                            error e => {
                                log:printError("Error occurred when extracting JSON payload. Error: " + e.message);
                                SalesforceConnectorError connectorError = {message:"", salesforceErrors:[]};
                                connectorError.message = "Error occured while extracting Json payload!";
                                connectorError.cause = e;
                                return connectorError;
                            }
                        }
                    }
                    http:PayloadError payloadErr => {
                        log:printError("Error occurred when extracting errors from payload. Error: " + payloadErr.message);
                        SalesforceConnectorError connectorError = {message:"", salesforceErrors:[]};
                        connectorError.message = "Error occured while extracting errors from payload!";
                        connectorError.cause = payloadErr;
                        return connectorError;
                    }
                }

            }
        }
        http:HttpConnectorError httpError => {
            SalesforceConnectorError connectorError =
            {
                message:"Http error -> status code: " + <string>httpError.statusCode + "; message: " + httpError.message,
                cause:httpError.cause ?: {}
            };
            return connectorError;
        }
    }
    return result;
}
