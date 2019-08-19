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
        // Create OAuth2 provider.
        oauth2:OutboundOAuth2Provider oauth2Provider = new(sfConfig.clientConfig);
        // Create salesforce bulk auth handler using created provider.
        SalesforceBulkAuthHandler sfBulkAuthHandler = new(oauth2Provider);
        // Create http client.
        self.httpClient = new(sfConfig.baseUrl + prepareUrl([SERVICES, ASYNC, BULK_API_VERSION]), { 
            auth: { 
                authHandler: sfBulkAuthHandler 
            } 
        });
    }

    remote function getXmlRecord(string[] paths) returns @tainted xml | SalesforceError {
        http:Request req = new;
        req.setHeader(CONTENT_TYPE, APP_XML);
        string path = prepareUrl(paths);

        http:Response | error response = self.httpClient->get(path, req);
        return checkAndSetErrorsXml(response);
    }

    remote function getJsonRecord(string[] paths) returns @tainted json | SalesforceError {
        http:Request req = new;
        req.setHeader(CONTENT_TYPE, APP_JSON);
        string path = prepareUrl(paths);

        http:Response | error response = self.httpClient->get(path, req);
        return checkAndSetErrorsJson(response);
    }

    remote function getCsvRecord(string[] paths) returns @tainted string | SalesforceError{
        http:Request req = new;
        req.setHeader(CONTENT_TYPE, APP_XML);
        string path = prepareUrl(paths);

        http:Response | error response = self.httpClient->get(path, req);
        return checkAndSetErrorsCsv(response);
    }

    remote function createXmlRecord(string[] paths, xml payload, boolean enablePkChunking = false) 
    returns @tainted xml | SalesforceError {
        http:Request req = new;
        req.setXmlPayload(payload);

        if (enablePkChunking) {
            req.setHeader(ENABLE_PK_CHUNKING, TRUE);
        }

        string path = prepareUrl(paths);
        var response = self.httpClient->post(path, req);
        return checkAndSetErrorsXml(response);
    }

    remote function createJsonRecord(string[] paths, json payload, boolean enablePkChunking = false) 
    returns @tainted json | SalesforceError {
        http:Request req = new;
        req.setJsonPayload(payload);

        if (enablePkChunking) {
            req.setHeader(ENABLE_PK_CHUNKING, TRUE);
        }

        string path = prepareUrl(paths);
        var response = self.httpClient->post(path, req);
        return checkAndSetErrorsJson(response);
    }

    remote function createCsvRecord(string[] paths, string payload, boolean enablePkChunking = false) 
    returns @tainted xml | SalesforceError {
        http:Request req = new;
        req.setPayload(payload);
        req.setHeader(CONTENT_TYPE, TEXT_CSV);

        if (enablePkChunking) {
            req.setHeader(ENABLE_PK_CHUNKING, TRUE);
        }

        string path = prepareUrl(paths);
        var response = self.httpClient->post(path, req);
        return checkAndSetErrorsXml(response);
    }

    remote function createJsonQuery(string[] paths, string payload, boolean enablePkChunking = false) 
    returns @tainted json | SalesforceError {
        http:Request req = new;
        req.setBinaryPayload(payload.toBytes(), contentType = APP_JSON);

        if (enablePkChunking) {
            req.setHeader(ENABLE_PK_CHUNKING, TRUE);
        }

        string path = prepareUrl(paths);
        var response = self.httpClient->post(path, req);
        return checkAndSetErrorsJson(response);
    }

    remote function createXmlQuery(string[] paths, string payload, boolean enablePkChunking = false) 
    returns @tainted xml | SalesforceError{
        http:Request req = new;
        req.setPayload(payload);
        req.setHeader(CONTENT_TYPE, APP_XML);

        if (enablePkChunking) {
            req.setHeader(ENABLE_PK_CHUNKING, TRUE);
        }

        string path = prepareUrl(paths);
        var response = self.httpClient->post(path, req);
        return checkAndSetErrorsXml(response);
    }
};
