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

# Base client for get and post operations.
public type SalesforceBaseClient client object {
    http:Client httpClient;

    public function __init(SalesforceConfiguration sfConfig) {
        self.httpClient = new(sfConfig.baseUrl, config = sfConfig.clientConfig);
    }

    remote function getXmlRecord(string[] paths) returns xml | SalesforceError;
    remote function getJsonRecord(string[] paths) returns json | SalesforceError;
    remote function getCsvRecord(string[] paths) returns string | SalesforceError;

    remote function createXmlRecord(string[] paths, xml payload, boolean enablePkChunking = false) 
    returns xml | SalesforceError;
    remote function createJsonRecord(string[] paths, json payload, boolean enablePkChunking = false) 
    returns json | SalesforceError;
    remote function createCsvRecord(string[] paths, string payload, boolean enablePkChunking = false) 
    returns xml | SalesforceError;

    remote function createJsonQuery(string[] paths, string payload, boolean enablePkChunking = false) 
    returns json | SalesforceError;
    remote function createXmlQuery(string[] paths, string payload, boolean enablePkChunking = false) 
    returns xml | SalesforceError;
};

remote function SalesforceBaseClient.getXmlRecord(string[] paths) returns xml | SalesforceError {
    http:Request req = new;
    setSessionId(req);
    req.setHeader(CONTENT_TYPE, APP_XML);
    string path = prepareUrl(paths);

    http:Response | error response = self.httpClient->get(path, message = req);
    return checkAndSetErrorsXml(response);
}

remote function SalesforceBaseClient.getJsonRecord(string[] paths) returns json | SalesforceError {
    http:Request req = new;
    setSessionId(req);
    req.setHeader(CONTENT_TYPE, APP_JSON);
    string path = prepareUrl(paths);

    http:Response | error response = self.httpClient->get(path, message = req);
    return checkAndSetErrorsJson(response);
}

remote function SalesforceBaseClient.getCsvRecord(string[] paths) returns string | SalesforceError{
    http:Request req = new;
    setSessionId(req);
    req.setHeader(CONTENT_TYPE, APP_XML);
    string path = prepareUrl(paths);

    http:Response | error response = self.httpClient->get(path, message = req);
    return checkAndSetErrorsCsv(response);
}

remote function SalesforceBaseClient.createXmlRecord(string[] paths, xml payload, boolean enablePkChunking = false) 
returns xml | SalesforceError {
    http:Request req = new;
    req.setXmlPayload(payload);
    setSessionId(req);

    if (enablePkChunking) {
        req.setHeader(ENABLE_PK_CHUNKING, TRUE);
    }

    string path = prepareUrl(paths);
    var response = self.httpClient->post(path, req);
    return checkAndSetErrorsXml(response);
}

remote function SalesforceBaseClient.createJsonRecord(string[] paths, json payload, boolean enablePkChunking = false) 
returns json | SalesforceError {
    http:Request req = new;
    req.setJsonPayload(payload);
    setSessionId(req);

    if (enablePkChunking) {
        req.setHeader(ENABLE_PK_CHUNKING, TRUE);
    }

    string path = prepareUrl(paths);
    var response = self.httpClient->post(path, req);
    return checkAndSetErrorsJson(response);
}

remote function SalesforceBaseClient.createCsvRecord(string[] paths, string payload, boolean enablePkChunking = false) 
returns xml | SalesforceError {
    http:Request req = new;
    req.setPayload(payload);
    req.setHeader(CONTENT_TYPE, TEXT_CSV);
    setSessionId(req);

    if (enablePkChunking) {
        req.setHeader(ENABLE_PK_CHUNKING, TRUE);
    }

    string path = prepareUrl(paths);
    var response = self.httpClient->post(path, req);
    return checkAndSetErrorsXml(response);
}

remote function SalesforceBaseClient.createJsonQuery(string[] paths, string payload, boolean enablePkChunking = false) 
returns json | SalesforceError {
    http:Request req = new;
    req.setBinaryPayload(payload.toByteArray(ENCODING_CHARSET_UTF_8), contentType = APP_JSON);
    setSessionId(req);

    if (enablePkChunking) {
        req.setHeader(ENABLE_PK_CHUNKING, TRUE);
    }

    string path = prepareUrl(paths);
    var response = self.httpClient->post(path, req);
    return checkAndSetErrorsJson(response);
}

remote function SalesforceBaseClient.createXmlQuery(string[] paths, string payload, boolean enablePkChunking = false) 
returns xml | SalesforceError{
    http:Request req = new;
    req.setPayload(payload);
    setSessionId(req);
    req.setHeader(CONTENT_TYPE, APP_XML);

    if (enablePkChunking) {
        req.setHeader(ENABLE_PK_CHUNKING, TRUE);
    }

    string path = prepareUrl(paths);
    var response = self.httpClient->post(path, req);
    return checkAndSetErrorsXml(response);
}
