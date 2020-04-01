//
// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;
import ballerina/oauth2;

# The Salesforce SObject Client object.
# + salesforceClient - OAuth2 client endpoint
# + salesforceConfiguration - Salesforce Connector configuration
public type SObjectClient client object {
    http:Client salesforceClient;
    SalesforceConfiguration salesforceConfiguration;

    # The Salesforce SOBject client initialization function.
    # + salesforceConfig - Salesforce Connector configuration
    public function __init(SalesforceConfiguration salesforceConfig) {
        self.salesforceConfiguration = salesforceConfig;
        // Create OAuth2 provider.
        oauth2:OutboundOAuth2Provider oauth2Provider = new (salesforceConfig.clientConfig);
        // Create bearer auth handler using created provider.
        http:BearerAuthHandler bearerHandler = new (oauth2Provider);

        http:ClientSecureSocket? socketConfig = salesforceConfig?.secureSocketConfig;

        // Create an HTTP client.
        if (socketConfig is http:ClientSecureSocket) {
            self.salesforceClient = new (salesforceConfig.baseUrl, {
                    secureSocket: socketConfig,
                    auth: {
                        authHandler: bearerHandler
                    }
                });
        } else {
            self.salesforceClient = new (salesforceConfig.baseUrl, {
                    auth: {
                        authHandler: bearerHandler
                    }
                });
        }
    }

    //Describe SObjects

    # Lists the available objects and their metadata for your organization and available to the logged-in user.
    # + return - `OrgMetadata` record if successful else ConnectorError occured
    public remote function describeAvailableObjects() returns @tainted OrgMetadata|ConnectorError {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS]);
        json res = check self->getRecord(path);
        return toOrgMetadata(res);
    }

    # Describes the individual metadata for the specified object.
    # + sobjectName - sobject name
    # + return - `SObjectBasicInfo` record if successful else ConnectorError occured
    public remote function getSObjectBasicInfo(string sobjectName) returns @tainted SObjectBasicInfo|ConnectorError {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName]);
        json res = check self->getRecord(path);
        return toSObjectBasicInfo(res);
    }

    # Completely describes the individual metadata at all levels for the specified object. Can be used to retrieve
    # the fields, URLs, and child relationships.
    # + sObjectName - SObject name value
    # + return - `SObjectMetaData` record if successful else ConnectorError occured
    public remote function describeSObject(string sObjectName) returns @tainted SObjectMetaData|ConnectorError {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DESCRIBE]);
        json res = check self->getRecord(path);
        return toSObjectMetaData(res);
    }

    # Query for actions displayed in the UI, given a user, a context, device format, and a record ID.
    # + return - `SObjectBasicInfo` record if successful else ConnectorError occured
    public remote function sObjectPlatformAction() returns @tainted SObjectBasicInfo|ConnectorError {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, PLATFORM_ACTION]);
        json res = check self->getRecord(path);
        return toSObjectBasicInfo(res);
    }

    //Basic CRUD

    # Accesses records based on the specified object ID, can be used with external objects.
    # + path - Resource path
    # + return - `json` result if successful else ConnectorError occured
    public remote function getRecord(string path) returns @tainted json|ConnectorError {
        http:Response|error response = self.salesforceClient->get(path);
        return checkAndSetErrors(response);
    }

    # Create records based on relevant object type sent with json record.
    # + sObjectName - SObject name value
    # + recordPayload - JSON record to be inserted
    # + return - created entity ID if successful else ConnectorError occured
    public remote function createRecord(string sObjectName, json recordPayload) returns @tainted string|ConnectorError {
        http:Request req = new;
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
        req.setJsonPayload(recordPayload);

        var response = self.salesforceClient->post(path, req);

        json|ConnectorError result = checkAndSetErrors(response);
        if (result is json) {
            return result.id.toString();
        } else {
            return result;
        }
    }

    # Update records based on relevant object id.
    # + sObjectName - SObject name value
    # + id - SObject id
    # + recordPayload - JSON record to be updated
    # + return - true if successful else false or ConnectorError occured
    public remote function updateRecord(string sObjectName, string id, json recordPayload)
    returns @tainted boolean|ConnectorError {
        http:Request req = new;
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        req.setJsonPayload(recordPayload);

        var response = self.salesforceClient->patch(path, req);

        json|ConnectorError result = checkAndSetErrors(response, false);

        if (result is json) {
            return true;
        } else {
            return result;
        }
    }

    # Delete existing records based on relevant object id.
    # + sObjectName - SObject name value
    # + id - SObject id
    # + return - true if successful else false or ConnectorError occured
    public remote function deleteRecord(string sObjectName, string id) returns @tainted boolean|ConnectorError {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        var response = self.salesforceClient->delete(path, ());

        json|ConnectorError result = checkAndSetErrors(response, false);

        if (result is json) {
            return true;
        } else {
            return result;
        }
    }

    # Get an object record by Id.
    #
    # + sobject - sobject name 
    # + id - sobject id 
    # + fields - fields to retrieve 
    # + return - `json` result if successful else `ConnectorError` occured
    public remote function getRecordById(string sobject, string id, string... fields) 
    returns @tainted json|ConnectorError {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobject, id]);
        if (fields.length() > 0) {
            path = path.concat(self.appendQueryParams(fields));
        }
        json response = check self->getRecord(path);
        return response;
    }

    # Get an object record by external Id.
    #
    # + sobject - sobject name 
    # + extIdField - external Id field name 
    # + extId - external Id value 
    # + fields - fields to retrieve 
    # + return - `json` result if successful else `ConnectorError` occured
    public remote function getRecordByExtId(string sobject, string extIdField, string extId, string... fields) 
    returns @tainted json|ConnectorError {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobject, extIdField, extId]);
        if (fields.length() > 0) {
            path = path.concat(self.appendQueryParams(fields));
        }
        json response = check self->getRecord(path);
        return response;
    }

    private function appendQueryParams(string[] fields) returns string {
        string appended = "?fields=";
        foreach string item in fields {
            appended = appended.concat(item.trim(), ",");
        }
        appended = appended.substring(0, appended.length() - 1);
        return appended;
    }
};
