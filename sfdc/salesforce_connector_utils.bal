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

@Description {value:"Function to set resource URl"}
@Param {value:"paths: array of path parameters"}
@Return {value:"string prepared url"}
function prepareUrl (string[] paths) returns string {
    string url = "";

    if (paths != null) {
        foreach path in paths {
            if (!path.hasPrefix("/")) {
                url = url + "/";
            }
            url = url + path;
        }
    }
    return url;
}

@Description {value:"Function to prepare resource URl with encoded queries"}
@Param {value:"paths: array of path parameters"}
@Param {value:"queryParamNames: array of query parameter names"}
@Param {value:"queryParamValues: array of query parameter values"}
@Return {value:"string prepared url"}
function prepareQueryUrl (string[] paths, string[] queryParamNames, string[] queryParamValues) returns string {

    string url = prepareUrl(paths);

    url = url + "?";
    boolean first = true;
    foreach i, name in queryParamNames {
        string value = queryParamValues[i];

        var oauth2Response = http:encode(value, ENCODING_CHARSET);
        match oauth2Response {
            string encoded => {
                if (first) {
                    url = url + name + "=" + encoded;
                    first = false;
                } else {
                    url = url + "&" + name + "=" + encoded;
                }
            }
            error e => {
                log:printErrorCause("Unable to encode value: " + value, e);
                break;
            }
        }
    }

    return url;
}

@Description {value:"Function to check errors and set errors to relevant error types"}
@Param {value:"response: http response or http connector error with network related errors"}
@Param {value:"isRequiredJsonPayload: gets true if response should contain a Json body, else false"}
@Return {value:"Json Payload or SalesforceConnectorError"}
function checkAndSetErrors (http:Response httpResponse, boolean expectPayload)
returns json|SalesforceConnectorError {
    json result;
    try {
        //if success
        if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201 || httpResponse.statusCode == 204) {
            if (expectPayload) {
                var res = httpResponse.getJsonPayload();
                result = check res;
            }
        } else {
            SalesforceConnectorError connectorError = {messages:[], salesforceErrors:[]};
            var jsonRes = httpResponse.getJsonPayload();
            json jsonResponse = check jsonRes;
            var res = <json[]>jsonResponse;
            json[] errors = check res;
            foreach i, err in errors {
                SalesforceError sfError = {message:err.message.toString()?:"", errorCode:err.errorCode.toString()?:""};
                connectorError.messages[i] = err.message.toString()?:"";
                connectorError.salesforceErrors[i] = sfError;
            }
            return connectorError;
        }
    } catch (mime:EntityError entityError) {
        SalesforceConnectorError connectorError = {
                                                      messages:[entityError.message],
                                                      errors:entityError.cause
                                                  };
        return connectorError;
    } catch (error e) {
        SalesforceConnectorError connectorError = {messages:[], salesforceErrors:[]};
        connectorError.messages[0] = "Error occured while receiving Json payload: Found null!";
        connectorError.errors[0] = e;
        return connectorError;
    }

    return result;
}