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
import ballerina/mime;
import ballerina/http;

# Returns the prepared URL.
# + paths - An array of paths prefixes
# + return - The prepared URL
function prepareUrl(string[] paths) returns string {
    string url = EMPTY_STRING;

    if (paths.length() > 0) {
        foreach var path in paths {
            if (!path.startsWith(FORWARD_SLASH)) {
                url = url + FORWARD_SLASH;
            }
            url = url + path;
        }
    }
    return <@untainted> url;
}

# Returns the prepared URL with encoded query.
# + paths - An array of paths prefixes
# + queryParamNames - An array of query param names
# + queryParamValues - An array of query param values
# + return - The prepared URL with encoded query
function prepareQueryUrl(string[] paths, string[] queryParamNames, string[] queryParamValues) returns string {

    string url = prepareUrl(paths);

    url = url + QUESTION_MARK;
    boolean first = true;
    int i = 0;
    foreach var name in queryParamNames {
        string value = queryParamValues[i];

        var encoded = http:encode(value, ENCODING_CHARSET);

        if (encoded is string) {
            if (first) {
                url = url + name + EQUAL_SIGN + encoded;
                first = false;
            } else {
                url = url + AMPERSAND + name + EQUAL_SIGN + encoded;
            }
        } else {
            log:printError("Unable to encode value: " + value, err = encoded);
            break;
        }
        i = i + 1;
    }

    return url;
}
# Returns the JSON result or SalesforceConnectorError.
# + httpResponse - HTTP respone or HttpConnectorError
# + expectPayload - true if json payload expected in response, if not false
# + return - JSON result if successful, else SalesforceConnectorError occured
function checkAndSetErrors(http:Response|error httpResponse, boolean expectPayload)
returns @tainted json|SalesforceConnectorError {
    json result = {};

    if (httpResponse is http:Response) {
        //if success
        if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201 || httpResponse.statusCode == 204) {
            if (expectPayload) {
                var jsonResponse = httpResponse.getJsonPayload();
                if (jsonResponse is json) {
                    return jsonResponse;
                } else {
                    log:printError("Error occurred when extracting JSON payload. Error: "
                    + <string> jsonResponse.detail()["message"]);
                    SalesforceConnectorError connectorError = { message: "", salesforceErrors: [] };
                    connectorError.message = "Error occured while extracting Json payload!";
                    return connectorError;
                }
            }
        } else {
            SalesforceConnectorError connectorError = { message: "", salesforceErrors: [] };
            var jsonResponse = httpResponse.getJsonPayload();
            if (jsonResponse is json) {
                json[]|error errors = <json[]>jsonResponse;

                if (errors is error) {
                    log:printError("Error occurred when extracting JSON payload. Error: "
                    + <string> errors.detail()["message"]);
                    connectorError = { message: "", salesforceErrors: [] };
                    connectorError.message = "Error occured while extracting Json payload!";
                    return connectorError;
                } else {
                    int i = 0;
                    foreach var err in errors {
                        SalesforceError sfError = { message: err.message.toString(), errorCode:err.errorCode
                        .toString() };
                        connectorError.message = err.message.toString();
                        connectorError.salesforceErrors[i] = sfError;
                        i = i + 1;
                    }
                    return connectorError;
                }
            } else {
                log:printError("Error occurred when extracting errors from payload. Error: "
                + <string> jsonResponse.detail()["message"]);
                connectorError = { message: "", salesforceErrors: [] };
                connectorError.message = "Error occured while extracting errors from payload!";
                return connectorError;
            }
        }
    } else {
        SalesforceConnectorError connectorError = {
                message: "Http error -> message: " + <string> httpResponse.detail()["message"], salesforceErrors: []
        };
        return connectorError;
    }
    return result;
}
