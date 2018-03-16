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

import ballerina.config;
import ballerina.io;
import ballerina.log;
import ballerina.net.http;
import ballerina.net.uri;
import oauth2;

oauth2:ClientConnector oauth2Connector = null;

function getOAuth2ClientConnector () (oauth2:ClientConnector) {
    if (oauth2Connector == null) {
        io:println("Creating OAuth2 client");
        oauth2Connector = create oauth2:ClientConnector(config:getGlobalValue(ENDPOINT),
                                                        config:getGlobalValue(ACCESS_TOKEN),
                                                        config:getGlobalValue(CLIENT_ID),
                                                        config:getGlobalValue(CLIENT_SECRET),
                                                        config:getGlobalValue(REFRESH_TOKEN),
                                                        config:getGlobalValue(REFRESH_TOKEN_ENDPOINT),
                                                        config:getGlobalValue(REFRESH_TOKEN_PATH));
        io:println("OAuth2 Client created");
    }

    return oauth2Connector;
}

@Description {value:"Accesses records based on the specified object ID, can be used with external objects "}
@Param {value:"sobjectName: The relevant sobject name"}
@Return {value:"response message"}
@Return {value:"Error occured."}
function getRecord (string sObjectName, string id) (json, SalesforceConnectorError) {
    SalesforceConnectorError connectorError;
    json response;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id], null, null);
    response, connectorError = sendGetRequest(path);

    return response, connectorError;
}

@Description {value:"Creates new records"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"record: json payload containing record data"}
@Return {value:"Created record's ID"}
@Return {value:"Error occured."}
function createRecord (string sObjectName, json record) (string, SalesforceConnectorError) {
    SalesforceConnectorError connectorError;
    json response;
    string id;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName], null, null);
    response, connectorError = sendPostRequest(path, record);

    if (connectorError != null) {
        return id, connectorError;
    }

    log:printDebug(response.toString());

    try {
        id = response.id.toString();
    } catch (error e) {
        log:printErrorCause("Unable to get the newly created record's id", e);
        connectorError = setError(e);
    }

    return id, connectorError;
}

@Description {value:"Updates existing records"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"record: json payload containing record data"}
@Return {value:"response message"}
@Return {value:"Error occured."}
function updateRecord (string sObjectName, string id, json record) (boolean, SalesforceConnectorError) {
    SalesforceConnectorError connectorError;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id], null, null);
    connectorError = sendPatchRequest(path, record);

    return connectorError == null, connectorError;
}

@Description {value:"Deletes existing records"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"id: The id of the relevant record supposed to be deleted"}
@Return {value:"response message"}
@Return {value:"Error occured."}
function deleteRecord (string sObjectName, string id) (boolean, SalesforceConnectorError) {
    SalesforceConnectorError connectorError;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id], null, null);
    connectorError = sendDeleteRequest(path);

    return connectorError == null, connectorError;
}

@Description {value:"Prepare and send the request"}
@Param {value:"url: The relevant url to be used to send the request"}
@Return {value:"response json"}
@Return {value:"Error occured."}
function sendGetRequest (string url) (json, SalesforceConnectorError) {
    endpoint<oauth2:ClientConnector> oauth2Connector {
        getOAuth2ClientConnector();
    }

    http:OutRequest request = {};
    http:InResponse response = {};
    http:HttpConnectorError err;
    SalesforceConnectorError connectorError;

    response, err = oauth2Connector.get(url, request);
    connectorError = checkAndSetErrors(response, err);
    json payload = response.getJsonPayload();

    if (payload == null) {
        log:printWarn("null payload received for: " + url);
    }

    // TODO check if payload is null or had any error
    return payload, connectorError;
}

@Description {value:"Prepare and send DELETE request"}
@Param {value:"url: The relevant url to be used to send the request"}
@Return {value:"Error occured."}
function sendDeleteRequest (string url) (SalesforceConnectorError) {
    endpoint<oauth2:ClientConnector> oauth2Connector {
        getOAuth2ClientConnector();
    }

    http:OutRequest request = {};
    http:InResponse response = {};
    http:HttpConnectorError err;
    SalesforceConnectorError connectorError;

    response, err = oauth2Connector.delete(url, request);
    connectorError = checkAndSetErrors(response, err);

    // TODO check if response is null or had any error
    return connectorError;
}

@Description {value:"Prepare and send POST request"}
@Param {value:"url: The relevant url to be used to send the request"}
@Param {value:"body: json payload to be sent as request body"}
@Return {value:"response json"}
@Return {value:"Error occured."}
function sendPostRequest (string url, json body) (json, SalesforceConnectorError) {
    endpoint<oauth2:ClientConnector> oauth2Connector {
        getOAuth2ClientConnector();
    }

    http:OutRequest request = {};
    http:InResponse response = {};
    http:HttpConnectorError err;
    SalesforceConnectorError connectorError;

    request.setJsonPayload(body);
    response, err = oauth2Connector.post(url, request);
    connectorError = checkAndSetErrors(response, err);
    json payload = response.getJsonPayload();

    if (payload == null) {
        log:printWarn("null payload received for: " + url);
    }

    // TODO check if payload is null or had any error
    return payload, connectorError;
}

@Description {value:"Prepare and send PATCH request"}
@Param {value:"url: The relevant url to be used to send the request"}
@Param {value:"body: json payload to be sent as request body"}
@Return {value:"Error occured."}
function sendPatchRequest (string url, json body) (SalesforceConnectorError) {
    endpoint<oauth2:ClientConnector> oauth2Connector {
        getOAuth2ClientConnector();
    }

    http:OutRequest request = {};
    http:InResponse response = {};
    http:HttpConnectorError err;
    SalesforceConnectorError connectorError;

    request.setJsonPayload(body);
    response, err = oauth2Connector.patch(url, request);
    connectorError = checkAndSetErrors(response, err);

    // TODO check if response is null or had any error
    return connectorError;
}

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
@Param {value:"httpError: http connector error"}
@Return {value:"Error occured"}
function checkAndSetErrors (http:InResponse response, http:HttpConnectorError httpError) (SalesforceConnectorError) {
    SalesforceConnectorError connectorError;
    if (httpError != null) {
        connectorError = {
                             messages:["Http error occurred -> status code: " +
                                       <string>httpError.statusCode + "; message: " + httpError.message],
                             errors:[httpError.cause]
                         };
    } else if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
        json[] body;
        error _;
        body, _ = (json[])response.getJsonPayload();
        connectorError = {messages:[], salesforceErrors:[]};
        foreach i, e in body {
            SalesforceError sfError = {message:e.message.toString(), errorCode:e.errorCode.toString()};
            connectorError.messages[i] = e.message.toString();
            connectorError.salesforceErrors[i] = sfError;
        }
    }
    return connectorError;
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