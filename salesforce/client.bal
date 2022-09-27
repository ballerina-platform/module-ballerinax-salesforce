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

import ballerina/http;
import ballerinax/salesforce.utils;
import ballerina/jballerina.java;

# Ballerina Salesforce connector provides the capability to access Salesforce REST API.
# This connector lets you to perform operations for SObjects, query using SOQL, search using SOSL, and describe SObjects
# and organizational data.
@display {
    label: "Salesforce REST API Client",
    iconPath: "icon.png"
}
public isolated client class Client {
    private final http:Client salesforceClient;
    private final OAuth2RefreshTokenGrantConfig|BearerTokenConfig clientConfig;

    # Initializes the connector. During initialization you can pass either http:BearerTokenConfig if you have a bearer
    # token or http:OAuth2RefreshTokenGrantConfig if you have Oauth tokens.
    # Create a Salesforce account and obtain tokens following 
    # [this guide](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm). 
    #
    # + salesforceConfig - Salesforce Connector configuration
    # + return - `sfdc:Error` on failure of initialization or else `()`
    public isolated function init(ConnectionConfig config) returns error? {
        self.clientConfig = config.auth.cloneReadOnly();

        http:Client|http:ClientError|error httpClientResult;
        httpClientResult = trap new (config.baseUrl, {
            auth: let var authConfig = config.auth in (authConfig is BearerTokenConfig ? authConfig : {...authConfig}),
            httpVersion: config.httpVersion,
            http1Settings: {...config.http1Settings},
            http2Settings: config.http2Settings,
            timeout: config.timeout,
            forwarded: config.forwarded,
            poolConfig: config.poolConfig,
            cache: config.cache,
            compression: config.compression,
            circuitBreaker: config.circuitBreaker,
            retryConfig: config.retryConfig,
            responseLimits: config.responseLimits,
            secureSocket: config.secureSocket,
            proxy: config.proxy,
            validation: config.validation
        });

        if httpClientResult is http:Client {
            self.salesforceClient = httpClientResult;
        } else {
            return error(INVALID_CLIENT_CONFIG);
        }
    }

    //Describe SObjects
    # Gets metadata of your organization.
    #
    # + return - `OrganizationMetadata` record if successful or else `error`
    @display {label: "Get Organization Metadata"}
    isolated remote function getOrganizationMetaData() returns @display {label: "Organization Metadata"}
                                                    OrganizationMetadata|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS]);
        return check self.salesforceClient->get(path);
    }

    # Gets basic data of the specified object.
    #
    # + sobjectName - sObject name
    # + return - `SObjectBasicInfo` record if successful or else `error`
    @display {label: "Get sObject Basic Information"}
    isolated remote function getBasicInfo(@display {label: "sObject Name"} string sobjectName)
                                                returns @display {label: "sObject Basic Information"}
                                                SObjectBasicInfo|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName]);
        return check self.salesforceClient->get(path);
    }

    # Completely describes the individual metadata at all levels of the specified object. Can be used to retrieve
    # the fields, URLs, and child relationships.
    #
    # + sObjectName - sObject name value
    # + return - `SObjectMetaData` record if successful or else `error`
    @display {label: "Get sObject Description"}
    isolated remote function describe(@display {label: "sObject Name"} string sObjectName)
                                            returns @display {label: "sObject Metadata"} SObjectMetaData|error {

        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DESCRIBE]);
        return check self.salesforceClient->get(path);
    }

    # Query for actions displayed in the UI, given a user, a context, device format, and a record ID.
    #
    # + return - `SObjectBasicInfo` record if successful or else `error`
    @display {label: "Get sObject Platform Action"}
    isolated remote function getPlatformAction() returns @display {label: "sObject Basic Information"}
                                                SObjectBasicInfo|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, PLATFORM_ACTION]);
        return check self.salesforceClient->get(path);
    }

    //Describe Organization
    # Lists summary details about each REST API version available.
    #
    # + return - List of `Version` if successful. Else, the occured `error`.
    @display {label: "Get Available API Versions"}
    isolated remote function getApiVersions() returns @display {label: "Versions"} Version[]|error {
        string path = utils:prepareUrl([BASE_PATH]);
        return check self.salesforceClient->get(path);
    }

    # Lists the resources available for the specified API version.
    #
    # + apiVersion - API version (v37)
    # + return - `Resources` as map of strings if successful. Else, the occurred `error`.
    @display {label: "Get Resources by API Version"}
    isolated remote function getResources(@display {label: "API Version"} string apiVersion)
                                                    returns @display {label: "Resources"} map<string>|error {
        string path = utils:prepareUrl([BASE_PATH, apiVersion]);
        json res = check self.salesforceClient->get(path);
        return toMapOfStrings(res);
    }

    # Lists the Limits information for your organization.
    #
    # + return - `OrganizationLimits` as map of `Limit` if successful. Else, the occurred `error`.
    @display {label: "Get Organization Limits"}
    isolated remote function getLimits() returns @display {label: "Organization Limits"}
                                                    map<Limit>|error {
        string path = utils:prepareUrl([API_BASE_PATH, LIMITS]);
        json res = check self.salesforceClient->get(path);
        return toMapOfLimits(res);
    }

    # Gets an object record by ID.
    #
    # + sobject - sObject name 
    # + id - sObject ID
    # + fields - Fields to retrieve 
    # + returnType - The payload, which is expected to be returned after data binding.
    # + return - Record if successful or else `error`
    @display {label: "Get Record by ID"}
    isolated remote function getById(@display {label: "sObject Name"} string sobject,
                                    @display {label: "sObject ID"} string id,
                                    @display {label: "Fields to Retrieve"} string[] fields = [], typedesc<record {}> returnType = <>)
                                    returns @display {label: "Result"} returnType|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "getRecordById"
    } external;

    private isolated function processGetRecordById(typedesc<record {}> returnType, string sobject, string id,
                                                    string[] fields) returns record {}|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sobject, id]);
        if fields.length() > 0 {
            path = path.concat(utils:appendQueryParams(fields));
        }
        json response = check self.salesforceClient->get(path);
        return check response.cloneWithType(returnType);
    }

    # Gets an object record by external ID.
    #
    # + sobject - sObject name 
    # + extIdField - External ID field name 
    # + extId - External ID value 
    # + fields - Fields to retrieve 
    # + returnType - The payload, which is expected to be returned after data binding.
    # + return - Record if successful or else `error`
    @display {label: "Get Record by External ID"}
    isolated remote function getByExternalId(@display {label: "sObject Name"} string sobject,
                                            @display {label: "External ID Field Name"} string extIdField,
                                            @display {label: "External ID"} string extId,
                                            @display {label: "Fields to Retrieve"} string[] fields = [], typedesc<record {}> returnType = <>)
                                            returns @display {label: "Result"} returnType|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "getRecordByExtId"
    } external;

    private isolated function processGetRecordByExtId(typedesc<record {}> returnType, string sobject, string extIdField,
                                                        string extId, string[] fields) returns record {}|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sobject, extIdField, extId]);
        if fields.length() > 0 {
            path = path.concat(utils:appendQueryParams(fields));
        }
        json response = check self.salesforceClient->get(path);
        return check response.cloneWithType(returnType);
    }

    # Creates records based on relevant object type sent with json record.
    #
    # + sObjectName - sObject name value
    # + sObjectRecord - Record to be inserted
    # + return - Creation response if successful or else `error`
    @display {label: "Create Record"}
    isolated remote function create(@display {label: "sObject Name"} string sObjectName,
                                    @display {label: "sObject Data"} record {} sObjectRecord)
                                    returns @display {label: "Created Entity ID"} CreationResponse|error {
        http:Request req = new;
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
        req.setJsonPayload(sObjectRecord.toJson());
        return check self.salesforceClient->post(path, req);
    }

    # Updates records based on relevant object ID.
    #
    # + sObjectName - sObject name value
    # + id - sObject ID
    # + sObjectRecord - Record to be updated
    # + return - Empty response if successful `error`
    @display {label: "Update Record"}
    isolated remote function update(@display {label: "sObject Name"} string sObjectName,
                                    @display {label: "sObject ID"} string id,
                                    @display {label: "Record Payload"} record {} sObjectRecord)
                                    returns @display {label: "Result"} error? {
        http:Request req = new;
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        req.setJsonPayload(sObjectRecord.toJson());
        return check self.salesforceClient->patch(path, req);
    }

    # Upsert a record based on the value of a specified external ID field.
    #
    # + sObjectName - sObject name value
    # + externalIdField - External ID field of an object
    # + externalId - External ID
    # + sObjectRecord - Record to be upserted
    # + return - Empty response if successful or else `error`
    @display {label: "Upsert Record"}
    isolated remote function upsert(@display {label: "sObject Name"} string sObjectName,
                                    @display {label: "External ID Field"} string externalIdField,
                                    @display {label: "External ID"} string externalId,
                                    @display {label: "Record Payload"} record {} sObjectRecord)
                                    returns @display {label: "Result"} error? {
        http:Request req = new;
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, externalIdField, externalId]);
        req.setJsonPayload(sObjectRecord.toJson());
        return check self.salesforceClient->patch(path, req);
    }

    # Delete existing records based on relevant object ID.
    #
    # + sObjectName - SObject name value
    # + id - SObject ID
    # + return - Empty response if successful or else `error`
    @display {label: "Delete Record"}
    isolated remote function delete(@display {label: "SObject Name"} string sObjectName,
                                    @display {label: "SObject ID"} string id)
                                    returns @display {label: "Result"} error? {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        return check self.salesforceClient->delete(path);
    }

    # Executes the specified SOQL query.
    #
    # + soql - SOQL query
    # + returnType - The payload, which is expected to be returned after data binding.
    # + return - `stream<{returnType}, error?>` if successful. Else, the occurred `error`.
    @display {label: "Get Query Result"}
    isolated remote function query(@display {label: "SOQL Query"} string soql, typedesc<record {}> returnType = <>)
                                    returns @display {label: "SOQL Result"} stream<returnType, error?>|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "getQueryResult"
    } external;

    private isolated function processGetQueryResult(typedesc<record {}> returnType, string receivedQuery)
                                                    returns stream<record {}, error?>|error {
        string path = utils:prepareQueryUrl([API_BASE_PATH, QUERY], [Q], [receivedQuery]);
        SOQLQueryResultStream objectInstance = check new (self.salesforceClient, path);
        stream<record {}, error?> finalStream = new (objectInstance);
        return self.streamConverter(finalStream, returnType);
    }

    # Executes the specified SOSL search.
    #
    # + sosl - SOSL search query
    # + returnType - The payload, which is expected to be returned after data binding.
    # + return - `stream<{returnType}, error?>` record if successful. Else, the occurred `error`.
    @display {label: "SOSL Search"}
    isolated remote function search(@display {label: "SOSL Search Query"} string sosl, typedesc<record {}> returnType = <>)
                                    returns @display {label: "SOSL Result"} stream<returnType, error?>|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "searchSOSLString"
    } external;

    private isolated function processSearchSOSLString(typedesc<record {}> returnType, string searchString)
                                                    returns stream<record {}, error?>|error {
        string path = utils:prepareQueryUrl([API_BASE_PATH, SEARCH], [Q], [searchString]);

        SOSLSearchResult objectInstance = check new (self.salesforceClient, path);
        stream<record {}, error?> finalStream = new (objectInstance);
        return self.streamConverter(finalStream, returnType);
    }

    // External function for the conversion of stream
    isolated function streamConverter(stream<record {}, error?> data, typedesc<record {}> returnType) returns
    stream<record {}, error?>|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor"
    } external;

    ///////////////////////////////////////////// DEPRECATED ///////////////////////////////////////////////////////////

    //Describe SObjects
    # Lists the available objects and their metadata for your organization and available to the logged-in user.
    #
    # + return - `OrgMetadata` record if successful or else `sfdc:Error`
    #
    # # Deprecated
    # This function is deprecated as the method signature is altered.
    # Use the new and improved `getOrganizationMetaData()` function instead.
    @display {label: "Get Available Objects"}
    @deprecated
    isolated remote function describeAvailableObjects()
                                                    returns @display {label: "Organization Metadata"}
                                                    OrgMetadata|Error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS]);
        json res = check self.get(path);
        return toOrgMetadata(res);
    }

    # Describes the individual metadata for the specified object.
    #
    # + sobjectName - SObject name
    # + return - `SObjectBasicInfo` record if successful or else `sfdc:Error`
    #
    # # Deprecated
    # This function is deprecated as the method signature is altered.
    # Use the new and improved  `getBasicInfo(string sobjectName)` function instead.
    @display {label: "Get SObject Basic Information"}
    @deprecated
    isolated remote function getSObjectBasicInfo(@display {label: "SObject Name"} string sobjectName)
                                                returns @display {label: "SObject Basic Information"}
                                                SObjectBasicInfo|Error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName]);
        json res = check self.get(path);
        return toSObjectBasicInfo(res);
    }

    # Completely describes the individual metadata at all levels for the specified object. Can be used to retrieve
    # the fields, URLs, and child relationships.
    #
    # + sObjectName - SObject name value
    # + return - `SObjectMetaData` record if successful or else `sfdc:Error`
    #
    # # Deprecated
    # This function is deprecated as the method signature is altered.
    # Use the new and improved `describe(string sObjectName)` function instead.
    @display {label: "Get SObject Description"}
    @deprecated
    isolated remote function describeSObject(@display {label: "SObject Name"} string sObjectName)
                                            returns @display {label: "SObject Metadata"} SObjectMetaData|Error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DESCRIBE]);
        json res = check self.get(path);
        return toSObjectMetaData(res);
    }

    # Query for actions displayed in the UI, given a user, a context, device format, and a record ID.
    #
    # + return - `SObjectBasicInfo` record if successful or else `sfdc:Error`
    #
    # # Deprecated
    # This function is deprecated as the method signature is altered.
    # Use the new and improved `getPlatformAction()` function instead.
    @display {label: "Get SObject Platform Action"}
    @deprecated
    isolated remote function sObjectPlatformAction()
                                                returns @display {label: "SObject Basic Information"}
                                                SObjectBasicInfo|Error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, PLATFORM_ACTION]);
        json res = check self.get(path);
        return toSObjectBasicInfo(res);
    }

    //Describe Organization
    # Lists summary details about each REST API version available.
    #
    # + return - List of `Version` if successful. Else, the occured Error.
    #
    # # Deprecated
    # This function is deprecated as the method signature is altered.
    # Use the new and improved `getApiVersions()` function instead.
    @display {label: "Get Available API Versions"}
    @deprecated
    isolated remote function getAvailableApiVersions() returns @display {label: "Versions"} Version[]|Error {
        string path = utils:prepareUrl([BASE_PATH]);
        json res = check self.get(path);
        return toVersions(res);
    }

    # Lists the resources available for the specified API version.
    #
    # + apiVersion - API version (v37)
    # + return - `Resources` as map of strings if successful. Else, the occurred `Error`.
    #
    # # Deprecated
    # This function is deprecated as the method signature is altered.
    # Use the new and improved `getResources(string apiVersion)` function instead.
    @display {label: "Get Resources by API Version"}
    @deprecated
    isolated remote function getResourcesByApiVersion(@display {label: "API Version"} string apiVersion)
                                                     returns @display {label: "Resources"} map<string>|Error {
        string path = utils:prepareUrl([BASE_PATH, apiVersion]);
        json res = check self.get(path);
        return toMapOfStrings(res);
    }

    # Lists the Limits information for your organization.
    #
    # + return - `OrganizationLimits` as map of `Limit` if successful. Else, the occurred `Error`.
    #
    # # Deprecated
    # This function is deprecated as the method signature is altered.
    # Use the new and improved `getLimits()` function instead.
    @display {label: "Get Organization Limits"}
    @deprecated
    isolated remote function getOrganizationLimits()
                                                    returns @display {label: "Organization Limits"}
                                                    map<Limit>|Error {
        string path = utils:prepareUrl([API_BASE_PATH, LIMITS]);
        json res = check self.get(path);
        return toMapOfLimits(res);
    }

    # Accesses records based on the specified object ID, can be used with external objects.
    #
    # + path - Resource path
    # + return - JSON result if successful else or else `sfdc:Error`
    #
    # # Deprecated
    # This function is deprecated as it returns a json response.
    # Use the new and improved `getById(string sObject, string id)` function instead.
    @display {label: "Get Record"}
    @deprecated
    isolated remote function getRecord(@display {label: "Resource Path"} string path)
                                        returns @display {label: "Result"} json|Error {
        json|http:ClientError response = self.salesforceClient->get(path);
        if response is json {
            return response;
        } else {
            return checkAndSetErrorDetail(response);
        }
    }

    private isolated function get(@display {label: "Resource Path"} string path)
                                  returns @display {label: "Result"} json|Error {
        json|http:ClientError response = self.salesforceClient->get(path);
        if response is json {
            return response;
        } else {
            return checkAndSetErrorDetail(response);
        }
    }

    # Gets an object record by ID.
    #
    # + sobject - SObject name 
    # + id - SObject ID
    # + fields - Fields to retrieve 
    # + return - JSON result if successful or else `sfdc:Error`
    #
    # # Deprecated
    # This function is deprecated as it returns a json response.
    # Use the new and improved `getById(string sObject, string id)` function instead.
    @display {label: "Get Record by ID"}
    @deprecated
    isolated remote function getRecordById(@display {label: "SObject Name"} string sobject,
                                            @display {label: "SObject ID"} string id,
                                            @display {label: "Fields to Retrieve"}
                                           string... fields)
                                            returns @display {label: "Result"} json|Error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sobject, id]);
        if fields.length() > 0 {
            path = path.concat(utils:appendQueryParams(fields));
        }
        json response = check self.get(path);
        return response;
    }

    private isolated function getByIdUtil(@display {label: "SObject Name"} string sobject,
                                            @display {label: "SObject ID"} string id,
                                            @display {label: "Fields to Retrieve"}
                                          string... fields)
                                            returns @display {label: "Result"} json|Error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sobject, id]);
        if fields.length() > 0 {
            path = path.concat(utils:appendQueryParams(fields));
        }
        json response = check self.get(path);
        return response;
    }

    # Gets an object record by external ID.
    #
    # + sobject - SObject name 
    # + extIdField - External ID field name 
    # + extId - External ID value 
    # + fields - Fields to retrieve 
    # + return - JSON result if successful or else `sfdc:Error`
    #
    # # Deprecated
    # This function is deprecated as it returns a json response.
    # Use the new and improved `getByExternalId(string sObject, string extIdField, string extId)` function instead.
    @display {label: "Get Record by External ID"}
    @deprecated
    isolated remote function getRecordByExtId(@display {label: "SObject Name"} string sobject,
                                            @display {label: "External ID Field Name"} string extIdField,
                                            @display {label: "External ID"} string extId,
                                            @display {label: "Fields to Retrieve"}
                                              string... fields)
                                            returns @display {label: "Result"} json|Error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sobject, extIdField, extId]);
        if fields.length() > 0 {
            path = path.concat(utils:appendQueryParams(fields));
        }
        json response = check self.get(path);
        return response;
    }

    # Creates records based on relevant object type sent with json record.
    #
    # + sObjectName - SObject name value
    # + recordPayload - JSON record to be inserted
    # + return - Created entity ID if successful or else `sfdc:Error`
    #
    # # Deprecated
    # This function is deprecated as it expects a json payload.
    # Use the new and improved `create(string sObjectName, record{} recordPayload)` function instead.
    @display {label: "Create Record"}
    @deprecated
    isolated remote function createRecord(@display {label: "SObject Name"} string sObjectName,
                                        @display {label: "Record Payload"} json recordPayload)
                                        returns @display {label: "Created Entity ID"} string|Error {
        http:Request req = new;
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
        req.setJsonPayload(recordPayload);
        json|http:ClientError response = self.salesforceClient->post(path, req);
        if response is json {
            json|error resultId = response.id;
            if resultId is json {
                return resultId.toString();
            } else {
                return error Error(resultId.message());
            }
        } else {
            return checkAndSetErrorDetail(response);
        }
    }

    private isolated function createUtil(@display {label: "SObject Name"} string sObjectName,
                                        @display {label: "Record Payload"} json recordPayload)
                                        returns @display {label: "Created Entity ID"} string|Error {
        http:Request req = new;
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
        req.setJsonPayload(recordPayload);
        json|http:ClientError response = self.salesforceClient->post(path, req);
        if response is json {
            json|error resultId = response.id;
            if resultId is json {
                return resultId.toString();
            } else {
                return error Error(resultId.message());
            }
        } else {
            return checkAndSetErrorDetail(response);
        }
    }

    # Delete existing records based on relevant object ID.
    #
    # + sObjectName - SObject name value
    # + id - SObject ID
    # + return - true if successful else false or else `sfdc:Error`
    #
    # # Deprecated
    # This function is deprecated to rename it.
    # Use the new and improved `delete(string sObjectName, string id)` function instead.
    @display {label: "Delete Record"}
    @deprecated
    isolated remote function deleteRecord(@display {label: "SObject Name"} string sObjectName,
                                        @display {label: "SObject ID"} string id)
                                        returns @display {label: "Result"} Error? {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        http:Response|http:ClientError response = self.salesforceClient->delete(path);
        if response is http:ClientError {
            return checkAndSetErrorDetail(response);
        }
    }

    private isolated function deleteUtil(@display {label: "SObject Name"} string sObjectName,
                                        @display {label: "SObject ID"} string id)
                                        returns @display {label: "Result"} Error? {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        http:Response|http:ClientError response = self.salesforceClient->delete(path);
        if response is http:ClientError {
            return checkAndSetErrorDetail(response);
        }
    }

    # Updates records based on relevant object ID.
    #
    # + sObjectName - SObject name value
    # + id - SObject ID
    # + recordPayload - JSON record to be updated
    # + return - true if successful else false or else `sfdc:Error`
    #
    # # Deprecated
    # This function is deprecated as it expects a json payload.
    # Use the new and improved `update(string sObjectName, string id, record{} recordPayload)` function instead.
    @display {label: "Update Record"}
    @deprecated
    isolated remote function updateRecord(@display {label: "SObject Name"} string sObjectName,
                                        @display {label: "SObject ID"} string id,
                                        @display {label: "Record Payload"} json recordPayload)
                                        returns @display {label: "Result"} Error? {
        http:Request req = new;
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        req.setJsonPayload(recordPayload);
        http:Response|http:ClientError response = self.salesforceClient->patch(path, req);
        if response is http:ClientError {
            return checkAndSetErrorDetail(response);
        }
    }

    private isolated function updateUtil(@display {label: "SObject Name"} string sObjectName,
                                        @display {label: "SObject ID"} string id,
                                        @display {label: "Record Payload"} json recordPayload)
                                        returns @display {label: "Result"} Error? {
        http:Request req = new;
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        req.setJsonPayload(recordPayload);
        http:Response|http:ClientError response = self.salesforceClient->patch(path, req);
        if response is http:ClientError {
            return checkAndSetErrorDetail(response);
        }
    }

    //Account
    # Accesses Account SObject records based on the Account object ID.
    #
    # + accountId - Account ID
    # + fields - Fields to retireve
    # + return - JSON response if successful or else an sfdc:Error
    #
    # # Deprecated
    # This function is deprecated as it returns a json response.
    # Use the new and improved `getById(string sObject, string id)` function instead.
    @display {label: "Get Account by ID"}
    @deprecated
    isolated remote function getAccountById(@display {label: "Account ID"} string accountId,
                                            @display {label: "Fields to Retrieve"}
                                            string... fields)
                                            returns @display {label: "Result"} json|Error {
        json res = check self.getByIdUtil(ACCOUNT, accountId, ...fields);
        return res;
    }

    # Creates new Account object record.
    #
    # + accountRecord - Account JSON record to be inserted
    # + return - Account ID if successful or else an sfdc:Error
    # # Deprecated
    # This function is deprecated as it expects a json payload.
    # Use the new and improved `create(string sObjectName, record{} recordPayload)` function instead.
    @display {label: "Create Account"}
    @deprecated
    isolated remote function createAccount(@display {label: "Account Record"} json accountRecord)
                                            returns @display {label: "Account ID"} string|Error {
        return self.createUtil(ACCOUNT, accountRecord);
    }

    # Deletes existing Account's records.
    #
    # + accountId - Account ID
    # + return - `true` if successful `false` otherwise, or an sfdc:Error in case of an error
    #
    # # Deprecated
    # This function is deprecated to rename it.
    # Use the new and improved `delete(string sObjectName, string id)` function instead.
    @display {label: "Delete Account"}
    @deprecated
    isolated remote function deleteAccount(@display {label: "Account ID"} string accountId)
                                            returns @display {label: "Result"} Error? {
        return self.deleteUtil(ACCOUNT, accountId);
    }

    # Updates existing Account object record.
    #
    # + accountId - Account ID
    # + accountRecord - Account record JSON payload
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    #
    # # Deprecated
    # This function is deprecated as it expects a json payload.
    # Use the new and improved `update(string sObjectName, string id, record{} recordPayload)` function instead.
    @display {label: "Update Account"}
    @deprecated
    isolated remote function updateAccount(@display {label: "Account ID"} string accountId,
                                            @display {label: "Account Record"} json accountRecord)
                                            returns @display {label: "Result"} Error? {
        return self.updateUtil(ACCOUNT, accountId, accountRecord);
    }

    //Lead
    # Accesses Lead SObject records based on the Lead object ID.
    #
    # + leadId - Lead ID
    # + fields - Fields to retireve
    # + return - JSON response if successful or else an sfdc:Error
    #
    # # Deprecated
    # This function is deprecated as it returns a json response.
    # Use the new and improved `getById(string sObject, string id)` function instead.
    @display {label: "Get Lead by ID"}
    @deprecated
    isolated remote function getLeadById(@display {label: "Lead ID"} string leadId,
                                        @display {label: "Fields to Retrieve"}
                                         string... fields)
                                        returns @display {label: "Result"} json|Error {
        json res = check self.getByIdUtil(LEAD, leadId, ...fields);
        return res;
    }

    # Creates new Lead object record.
    #
    # + leadRecord - Lead JSON record to be inserted
    # + return - Lead ID if successful or else an sfdc:Error
    #
    # # Deprecated
    # This function is deprecated as it expects a json payload.
    # Use the new and improved `create(string sObjectName, record{} recordPayload)` function instead.
    @display {label: "Create Lead"}
    @deprecated
    isolated remote function createLead(@display {label: "Lead Record"} json leadRecord)
                                        returns @display {label: "Lead ID"} string|Error {
        return self.createUtil(LEAD, leadRecord);
    }

    # Deletes existing Lead's records.
    #
    # + leadId - Lead ID
    # + return - `true`  if successful, `false` otherwise or an sfdc:Error incase of an error
    #
    # # Deprecated
    # This function is deprecated to rename it.
    # Use the new and improved `delete(string sObjectName, string id)` function instead.
    @display {label: "Delete Lead"}
    @deprecated
    isolated remote function deleteLead(@display {label: "Lead ID"} string leadId)
                                        returns @display {label: "Result"} Error? {
        return self.deleteUtil(LEAD, leadId);
    }

    # Updates existing Lead object record.
    #
    # + leadId - Lead ID
    # + leadRecord - Lead JSON record
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    #
    # # Deprecated
    # This function is deprecated as it expects a json payload.
    # Use the new and improved `update(string sObjectName, string id, record{} recordPayload)` function instead.
    @display {label: "Update Lead"}
    @deprecated
    isolated remote function updateLead(@display {label: "Lead ID"} string leadId,
                                        @display {label: "Lead Record"} json leadRecord)
                                        returns @display {label: "Result"} Error? {
        return self.updateUtil(LEAD, leadId, leadRecord);
    }

    //Contact
    # Accesses Contacts SObject records based on the Contact object ID.
    #
    # + contactId - Contact ID
    # + fields - Fields to retireve
    # + return - JSON result if successful or else an sfdc:Error
    #
    # # Deprecated
    # This function is deprecated as it returns a json response.
    # Use the new and improved `getById(string sObject, string id)` function instead.
    @display {label: "Get Contact by ID"}
    @deprecated
    isolated remote function getContactById(@display {label: "Contact ID"} string contactId,
                                            @display {label: "Fields to Retrieve"}
                                            string... fields) returns @display {label: "Result"} json|Error {
        json res = check self.getByIdUtil(CONTACT, contactId, ...fields);
        return res;
    }

    # Creates new Contact object record.
    #
    # + contactRecord - JSON contact record
    # + return - Contact ID if successful or else an sfdc:Error
    #
    # # Deprecated
    # This function is deprecated as it expects a json payload.
    # Use the new and improved `create(string sObjectName, record{} recordPayload)` function instead.
    @display {label: "Create Contact"}
    @deprecated
    isolated remote function createContact(@display {label: "Contact Record"} json contactRecord)
                                            returns @display {label: "Contact ID"} string|Error {
        return self.createUtil(CONTACT, contactRecord);
    }

    # Deletes existing Contact's records.
    #
    # + contactId - Contact ID
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    #
    # # Deprecated
    # This function is deprecated to rename it.
    # Use the new and improved `delete(string sObjectName, string id)` function instead.
    @display {label: "Delete Contact"}
    @deprecated
    isolated remote function deleteContact(@display {label: "Contact ID"} string contactId)
                                            returns @display {label: "Result"} Error? {
        return self.deleteUtil(CONTACT, contactId);
    }

    # Updates existing Contact object record.
    #
    # + contactId - Contact ID
    # + contactRecord - JSON contact record
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    #
    # # Deprecated
    # This function is deprecated as it expects a json payload.
    # Use the new and improved `update(string sObjectName, string id, record{} recordPayload)` function instead.
    @display {label: "Update Contact"}
    @deprecated
    isolated remote function updateContact(@display {label: "Contact ID"} string contactId,
                                            @display {label: "Contact Record"} json contactRecord)
                                            returns @display {label: "Result"} Error? {
        return self.updateUtil(CONTACT, contactId, contactRecord);
    }

    //Opportunity
    # Accesses Opportunities SObject records based on the Opportunity object ID.
    #
    # + opportunityId - Opportunity ID
    # + fields - Fields to retireve
    # + return - JSON response if successful or else an sfdc:Error
    #
    # # Deprecated
    # This function is deprecated as it returns a json response.
    # Use the new and improved `getById(string sObject, string id)` function instead.
    @display {label: "Get Opportunity by ID"}
    @deprecated
    isolated remote function getOpportunityById(@display {label: "Opportunity ID"} string opportunityId,
                                                @display {label: "Fields to Retrieve"}
                                                string... fields)
                                                returns @display {label: "Result"} json|Error {
        json res = check self.getByIdUtil(OPPORTUNITY, opportunityId, ...fields);
        return res;
    }

    # Creates new Opportunity object record.
    #
    # + opportunityRecord - JSON opportunity record
    # + return - Opportunity ID if successful or else an sfdc:Error
    #
    # # Deprecated
    # This function is deprecated as it expects a json payload.
    # Use the new and improved `create(string sObjectName, record{} recordPayload)` function instead.
    @display {label: "Create Opportunity"}
    @deprecated
    isolated remote function createOpportunity(@display {label: "Opportunity Record"} json opportunityRecord)
                                                returns @display {label: "Opportunity ID"} string|Error {
        return self.createUtil(OPPORTUNITY, opportunityRecord);
    }

    # Deletes existing Opportunity's records.
    #
    # + opportunityId - Opportunity ID
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    #
    # # Deprecated
    # This function is deprecated to rename it.
    # Use the new and improved `delete(string sObjectName, string id)` function instead.
    @display {label: "Delete Opportunity"}
    @deprecated
    isolated remote function deleteOpportunity(@display {label: "Opportunity ID"} string opportunityId)
                                                returns @display {label: "Result"} Error? {
        return self.deleteUtil(OPPORTUNITY, opportunityId);
    }

    # Updates existing Opportunity object record.
    #
    # + opportunityId - Opportunity ID
    # + opportunityRecord - Opportunity JSON payload
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    #
    # # Deprecated
    # This function is deprecated as it expects a json payload.
    # Use the new and improved `update(string sObjectName, string id, record{} recordPayload)` function instead.
    @display {label: "Update Opportunity"}
    @deprecated
    isolated remote function updateOpportunity(@display {label: "Opportunity ID"} string opportunityId,
                                                @display {label: "Opportunity Record"} json opportunityRecord)
                                                returns @display {label: "Result"} Error? {
        return self.updateUtil(OPPORTUNITY, opportunityId, opportunityRecord);
    }

    //Product
    # Accesses Products SObject records based on the Product object ID.
    #
    # + productId - Product ID
    # + fields - Fields to retireve
    # + return - JSON result if successful or else an sfdc:Error
    #
    # # Deprecated
    # This function is deprecated as it returns a json response.
    # Use the new and improved `getById(string sObject, string id)` function instead.
    @display {label: "Get Product by ID"}
    @deprecated
    isolated remote function getProductById(@display {label: "Product ID"} string productId,
                                            @display {label: "Fields to Retrieve"}
                                            string... fields)
                                            returns @display {label: "Result"} json|Error {
        json res = check self.getByIdUtil(PRODUCT, productId, ...fields);
        return res;
    }

    # Creates new Product object record.
    #
    # + productRecord - JSON product record
    # + return - Product ID if successful or else an sfdc:Error
    #
    # # Deprecated
    # This function is deprecated as it expects a json payload.
    # Use the new and improved `create(string sObjectName, record{} recordPayload)` function instead.
    @display {label: "Create Product"}
    @deprecated
    isolated remote function createProduct(@display {label: "Product Record"} json productRecord)
                                            returns @display {label: "Product ID"} string|Error {
        return self.createUtil(PRODUCT, productRecord);
    }

    # Deletes existing product's records.
    #
    # + productId - Product ID
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    #
    # # Deprecated
    # This function is deprecated to rename it.
    # Use the new and improved `delete(string sObjectName, string id)` function instead.
    @display {label: "Delete Product"}
    @deprecated
    isolated remote function deleteProduct(@display {label: "Product ID"} string productId)
                                            returns @display {label: "Result"} Error? {
        return self.deleteUtil(PRODUCT, productId);
    }

    # Updates existing Product object record.
    #
    # + productId - Product ID
    # + productRecord - JSON product record
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    #
    # # Deprecated
    # This function is deprecated as it expects a json payload.
    # Use the new and improved `update(string sObjectName, string id, record{} recordPayload)` function instead.
    @display {label: "Update Product"}
    @deprecated
    isolated remote function updateProduct(@display {label: "Product ID"} string productId,
                                            @display {label: "Product Record"} json productRecord)
                                            returns @display {label: "Result"} Error? {
        return self.updateUtil(PRODUCT, productId, productRecord);
    }

    //Query
    # Executes the specified SOQL query.
    #
    # + receivedQuery - Sent SOQL query
    # + return - `SoqlResult` record if successful. Else, the occurred `Error`.
    #
    # # Deprecated
    # This function is deprecated as it does not handle the pagination of records
    # Use the new and improved `query(string soql)` function instead. 
    @display {label: "Get Query Result"}
    @deprecated
    isolated remote function getQueryResult(@display {label: "SOQL Query"} string receivedQuery)
                                            returns @display {label: "SOQL Result"} SoqlResult|Error {
        string path = utils:prepareQueryUrl([API_BASE_PATH, QUERY], [Q], [receivedQuery]);
        json res = check self.get(path);
        return toSoqlResult(res);
    }

    # If the query results are too large, retrieve the next batch of results using the nextRecordUrl.
    #
    # + nextRecordsUrl - URL to get the next query results
    # + return - `SoqlResult` record if successful. Else, the occurred `Error`.
    #
    # # Deprecated
    # This function is deprecated as it is related to pagination of results in `query(string soql)`
    # Use the new and improved `query(string soql)` function instead.
    @display {label: "Get Next Query Result"}
    @deprecated
    isolated remote function getNextQueryResult(@display {label: "Next Records URL"} string nextRecordsUrl)
                                                returns @display {label: "SOQL Result"} SoqlResult|Error {
        json res = check self.get(nextRecordsUrl);
        return toSoqlResult(res);
    }

    # Executes the specified SOQL query.
    #
    # + receivedQuery - Sent SOQL query
    # + return - `SoqlResult` record if successful. Else, the occurred `error`.
    #
    # # Deprecated
    # This function is deprecated as it does not handle the pagination of records
    # Use the new and improved `query(string soql)` function instead.
    @display {label: "Get Query Result"}
    @deprecated
    isolated remote function getQueryResultStream(@display {label: "SOQL Query"} string receivedQuery)
                                            returns @display {label: "SOQL Result"} stream<record {}, error?>|error {
        string path = utils:prepareQueryUrl([API_BASE_PATH, QUERY], [Q], [receivedQuery]);
        SOQLQueryResultStream objectInstance = check new (self.salesforceClient, path);
        stream<record {}, error?> finalStream = new (objectInstance);
        return finalStream;
    }

    //Search
    # Executes the specified SOSL search.
    #
    # + searchString - Sent SOSL search query
    # + return - `SoslResult` record if successful. Else, the occurred `Error`.
    #
    # # Deprecated
    # This function is deprecated as it does not handle the pagination of returned data
    # Use the new and improved `search(string sosl)` function instead.
    @display {label: "SOSL Search"}
    @deprecated
    isolated remote function searchSOSLString(@display {label: "SOSL Search Query"} string searchString)
                                            returns @display {label: "SOSL Result"} SoslResult|Error {
        string path = utils:prepareQueryUrl([API_BASE_PATH, SEARCH], [Q], [searchString]);
        json res = check self.get(path);
        return toSoslResult(res);
    }

    # Executes the specified SOSL search.
    #
    # + searchString - Sent SOSL search query
    # + return - `stream<record{}, error?>` record if successful. Else, the occurred `error`.
    #
    # # Deprecated
    # This function is deprecated as it does not handle the pagination of returned data
    # Use the new and improved `search(string sosl)` function instead.
    @display {label: "SOSL Search"}
    @deprecated
    isolated remote function searchSOSLStringStream(@display {label: "SOSL Search Query"} string searchString)
                                            returns @display {label: "SOSL Result"} stream<record {}, error?>|error {
        string path = utils:prepareQueryUrl([API_BASE_PATH, SEARCH], [Q], [searchString]);
        SOSLSearchResult objectInstance = check new (self.salesforceClient, path);
        stream<record {}, error?> finalStream = new (objectInstance);
        return finalStream;
    }
}
