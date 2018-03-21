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

package src.salesforce;

import ballerina.log;
import ballerina.net.http;
import ballerina.net.uri;
import oauth2;
import ballerina.io;

@Description {value:"Function to prepare the URL endpoint for the request"}
@Param {value:"paths: URL prefixes and suffixes to set the endpoint"}
@Param {value:"queryParamNames: query parameter names"}
@Param {value:"queryParamValues: query parameter values"}
@Return {value:"Prepared URL"}
function prepareUrl (string[] paths, string[] queryParamNames, string[] queryParamValues) (string) {
    string url = "";
    error e;

    if (paths != null) {
        foreach path in paths {
            if (!path.hasPrefix("/")) {
                url = url + "/";
            }

            url = url + path;
        }
    }

    if (queryParamNames != null) {
        url = url + "?";
        boolean first = true;
        foreach i, name in queryParamNames {
            string value = queryParamValues[i];

            value, e = uri:encode(value, ENCODING_CHARSET);
            if (e != null) {
                log:printErrorCause("Unable to encode value: " + value, e);
                break;
            }

            if (first) {
                url = url + name + "=" + value;
                first = false;
            } else {
                url = url + "&" + name + "=" + value;
            }
        }
    }

    log:printDebug("Prepared URL: " + url);
    return url;
}

@Description {value:"Function to check errors and set errors to relevant error types"}
@Param {value:"response: http response"}
@Param {value:"httpError: http connector error for network related errors"}
@Param {value:"isRequiredJsonPayload: gets true if response should contain a Json body, else false"}
@Return {value:"Json Payload"}
@Return {value:"Error occured"}
function checkAndSetErrors (http:Response response, http:HttpConnectorError httpError, boolean isRequiredJsonPayload) (json, SalesforceConnectorError) {
    SalesforceConnectorError connectorError;
    json responseBody;

    if (httpError != null) {
        connectorError = {
                             messages:["Http error occurred -> status code: " +
                                       <string>httpError.statusCode + "; message: " + httpError.message],
                             errors:httpError.cause
                         };
    } else if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        if (isRequiredJsonPayload) {
            try {
                responseBody, _ = response.getJsonPayload();
            } catch (error e) {
                connectorError = {messages:[]};
                connectorError.messages[0] = e.message;
                connectorError.errors[0] = e;
            }
        }
    } else {
        json err;
        json[] errorResponseBody;
        try {
            err, _ = response.getJsonPayload();
            errorResponseBody, _ = (json[])err;
        } catch (error e) {
            connectorError = {messages:[]};
            connectorError.messages[0] = e.message;
            connectorError.errors[0] = e;
        }

        connectorError = {messages:[], salesforceErrors:[]};
        foreach i, e in errorResponseBody {
            SalesforceError sfError = {message:e.message.toString(), errorCode:e.errorCode.toString()};
            connectorError.messages[i] = e.message.toString();
            connectorError.salesforceErrors[i] = sfError;
        }
    }
    return responseBody, connectorError;
}

@Description {value:"Function to set errors to SalesforceConnectorError type"}
@Param {value:"error: error sent"}
@Return {value:"SaleforceConnectorError occured"}
function setError (error e) (SalesforceConnectorError) {
    SalesforceConnectorError connectorError = {messages:[], errors:[]};
    connectorError.messages[0] = e.message;
    connectorError.errors[0] = e;

    return connectorError;
}