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

package salesforce;

import ballerina/log;
import ballerina/net.http;
import ballerina/net.uri;
import ballerina/io;

//==============================================================================//
//============================ utility functions================================//

public function <SalesforceConnector sfConnector> getRecord (string path) returns json {
    error Error = {};
    json jsonResult;
    http:Request request = {};
    var oauth2Response = sfConnector.oauth2.get(path, request);
    match oauth2Response {
        http:HttpConnectorError conError => {
            Error = {message:conError.message};
            throw Error;
        }
        http:Response result => {
            var jsonPayload = result.getJsonPayload();
            match jsonPayload {
                mime:EntityError entityError => {
                    Error = {message:entityError.message};
                    throw Error;
                }
                json jsonRes => {
                    jsonResult = jsonRes;
                }
            }
        }
    }
    return jsonResult;
}

public function <SalesforceConnector sfConnector> createRecord (string sObjectName, json record) returns string {
    http:Request request = {};
    string id = "";
    error sfError = {};
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
    request.setJsonPayload(record);
    var oauth2Response = sfConnector.oauth2.post(path, request);
    match oauth2Response {
        http:HttpConnectorError conError => {
            sfError = {message:conError.message};
            throw sfError;
        }
        http:Response result => {
            if (result.statusCode == 200 || result.statusCode == 201 || result.statusCode == 204) {
                var jsonPayload = result.getJsonPayload();
                match jsonPayload {
                    mime:EntityError entityError => {
                        sfError = {message:entityError.message};
                        throw sfError;
                    }
                    json jsonRes => {
                        id = jsonRes.id.toString();
                    }
                }

            } else {
                sfError = {message:"Was not updated"};
                throw sfError;
            }
        }
    }
    return id;
}

public function <SalesforceConnector sfConnector> updateRecord (string sObjectName, string id, json record) returns boolean {
    http:Request request = {};
    error sfError = {};
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    request.setJsonPayload(record);
    var oauth2Response = sfConnector.oauth2.patch(path, request);
    match oauth2Response {
        http:HttpConnectorError conError => {
            sfError = {message:conError.message};
            throw sfError;
        }
        http:Response result => {
            if (result.statusCode == 200 || result.statusCode == 201 || result.statusCode == 204) {
                return true;
            } else {
                sfError = {message:"Was not updated"};
                throw sfError;
            }
        }
    }
}

public function <SalesforceConnector sfConnector> deleteRecord (string sObjectName, string id) returns boolean {
    http:Request request = {};
    error sfError = {};
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    var oauth2Response = sfConnector.oauth2.delete(path, request);
    match oauth2Response {
        http:HttpConnectorError conError => {
            sfError = {message:conError.message};
            throw sfError;
        }
        http:Response result => {
            if (result.statusCode == 200 || result.statusCode == 201 || result.statusCode == 204) {
                return true;
            } else {
                sfError = {message:"Was not deleted"};
                throw sfError;
            }
        }
    }
}

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

function prepareQueryUrl (string[] paths, string[] queryParamNames, string[] queryParamValues) returns string {

    string url = prepareUrl(paths);

    url = url + "?";
    boolean first = true;
    foreach i, name in queryParamNames {
        string value = queryParamValues[i];

        var oauth2Response = uri:encode(value, ENCODING_CHARSET);
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
