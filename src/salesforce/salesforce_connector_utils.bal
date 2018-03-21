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

//@Description {value:"Accesses records based on the specified object ID, can be used with external objects "}
//@Param {value:"sobjectName: The relevant sobject name"}
//@Return {value:"response message"}
//@Return {value:"Error occured."}
//function getRecord (string sObjectName, string id) (json, SalesforceConnectorError) {
//    SalesforceConnectorError connectorError;
//    json response;
//
//    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id], null, null);
//    response, connectorError = sendGetRequest(path);
//
//    return response, connectorError;
//}
//
//@Description {value:"Creates new records"}
//@Param {value:"sobjectName: The relevant sobject name"}
//@Param {value:"record: json payload containing record data"}
//@Return {value:"Created record's ID"}
//@Return {value:"Error occured."}
//function createRecord (string sObjectName, json record) (string, SalesforceConnectorError) {
//    SalesforceConnectorError connectorError;
//    json response;
//    string id;
//
//    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName], null, null);
//    response, connectorError = sendPostRequest(path, record);
//
//    if (connectorError != null) {
//        return id, connectorError;
//    }
//
//    log:printDebug(response.toString());
//
//    try {
//        id = response.id.toString();
//    } catch (error e) {
//        log:printErrorCause("Unable to get the newly created record's id", e);
//        connectorError = setError(e);
//    }
//
//    return id, connectorError;
//}
//
//@Description {value:"Updates existing records"}
//@Param {value:"sobjectName: The relevant sobject name"}
//@Param {value:"record: json payload containing record data"}
//@Return {value:"response message"}
//@Return {value:"Error occured."}
//function updateRecord (string sObjectName, string id, json record) (boolean, SalesforceConnectorError) {
//    SalesforceConnectorError connectorError;
//
//    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id], null, null);
//    connectorError = sendPatchRequest(path, record);
//
//    return connectorError == null, connectorError;
//}
//
//@Description {value:"Deletes existing records"}
//@Param {value:"sobjectName: The relevant sobject name"}
//@Param {value:"id: The id of the relevant record supposed to be deleted"}
//@Return {value:"response message"}
//@Return {value:"Error occured."}
//function deleteRecord (string sObjectName, string id) (boolean, SalesforceConnectorError) {
//    SalesforceConnectorError connectorError;
//
//    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id], null, null);
//    connectorError = sendDeleteRequest(path);
//
//    return connectorError == null, connectorError;
//}



//@Description {value:"Prepare and send DELETE request"}
//@Param {value:"url: The relevant url to be used to send the request"}
//@Return {value:"Error occured."}
//function sendDeleteRequest (string url) (SalesforceConnectorError) {
//    endpoint<oauth2:ClientConnector> oauth2Connector {
//        oauth2ConnectorInstance;
//    }
//
//    http:OutRequest request = {};
//    http:InResponse response = {};
//    http:HttpConnectorError err;
//    SalesforceConnectorError connectorError;
//
//    response, err = oauth2Connector.delete(url, request);
//    _, connectorError = checkAndSetErrors(response, err, false);
//
//    return connectorError;
//}
//
//@Description {value:"Prepare and send POST request"}
//@Param {value:"url: The relevant url to be used to send the request"}
//@Param {value:"body: json payload to be sent as request body"}
//@Return {value:"response json"}
//@Return {value:"Error occured."}
//function sendPostRequest (string url, json body) (json, SalesforceConnectorError) {
//    endpoint<oauth2:ClientConnector> oauth2Connector {
//        oauth2ConnectorInstance;
//    }
//
//    http:OutRequest request = {};
//    http:InResponse response = {};
//    http:HttpConnectorError err;
//    SalesforceConnectorError connectorError;
//    json jsonPayload;
//
//    request.setJsonPayload(body);
//    response, err = oauth2Connector.post(url, request);
//    jsonPayload, connectorError = checkAndSetErrors(response, err, true);
//
//    return jsonPayload, connectorError;
//}
//
//@Description {value:"Prepare and send PATCH request"}
//@Param {value:"url: The relevant url to be used to send the request"}
//@Param {value:"body: json payload to be sent as request body"}
//@Return {value:"Error occured."}
//function sendPatchRequest (string url, json body) (SalesforceConnectorError) {
//    endpoint<oauth2:ClientConnector> oauth2Connector {
//        oauth2ConnectorInstance;
//    }
//
//    http:OutRequest request = {};
//    http:InResponse response = {};
//    http:HttpConnectorError err;
//    SalesforceConnectorError connectorError;
//
//    request.setJsonPayload(body);
//    response, err = oauth2Connector.patch(url, request);
//    _, connectorError = checkAndSetErrors(response, err, false);
//
//    return connectorError;
//}

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