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
import ballerina/jballerina.java;
import ballerinax/'client.config;
import ballerinax/salesforce.utils;
import ballerina/time;

# Ballerina Salesforce connector provides the capability to access Salesforce REST API.
# This connector lets you to perform operations for SObjects, query using SOQL, search using SOSL, and describe SObjects
# and organizational data.
@display {
    label: "Salesforce REST API Client",
    iconPath: "icon.png"
}
public isolated client class Client {
    private final http:Client salesforceClient;

    # Initializes the connector. During initialization you can pass either http:BearerTokenConfig if you have a bearer
    # token or http:OAuth2RefreshTokenGrantConfig if you have Oauth tokens.
    # Create a Salesforce account and obtain tokens following 
    # [this guide](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm). 
    #
    # + salesforceConfig - Salesforce Connector configuration
    # + return - `sfdc:Error` on failure of initialization or else `()`
    public isolated function init(ConnectionConfig config) returns error? {
        http:Client|http:ClientError|error httpClientResult;
        http:ClientConfiguration httpClientConfig = check config:constructHTTPClientConfig(config);
        httpClientResult = trap new (config.baseUrl, httpClientConfig);

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
        http:Response response = check self.salesforceClient->get(path);
        if response.statusCode == 200 {
            json payload = check response.getJsonPayload();
            SObjectBasicInfo basicInfo = check payload.fromJsonWithType();
            return basicInfo;
        } else {
            json payload = check response.getJsonPayload();
            return error("Error occurred while retrieving the basic information of the sObject. " + payload.toString());
        }
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
    # + returnType - The payload, which is expected to be returned after data binding.
    # + return - Record if successful or else `error`
    @display {label: "Get Record by ID"}
    isolated remote function getById(@display {label: "sObject Name"} string sobject,
                                    @display {label: "sObject ID"} string id, 
                                    typedesc<record {}> returnType = <>)
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
    # + returnType - The payload, which is expected to be returned after data binding.
    # + return - Record if successful or else `error`
    @display {label: "Get Record by External ID"}
    isolated remote function getByExternalId(@display {label: "sObject Name"} string sobject,
                                            @display {label: "External ID Field Name"} string extIdField,
                                            @display {label: "External ID"} string extId,
                                            typedesc<record {}> returnType = <>)
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
        return check response.fromJsonWithType(returnType);
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

    # Lists reports.
    #
    # + return - Array of Report if successful or else `error`
    @display {label: "List Reports"}
    isolated remote function listReports() returns @display {label: "Reports"} Report[]|error {
        string path = utils:prepareUrl([API_BASE_PATH, ANALYTICS, REPORTS]);
        return check self.salesforceClient->get(path);
    }

    # Deletes a report.
    #
    # + reportId - Report Id
    # + return - `()` if the report deletion is successful or else an error
    @display {label: "Delete Report"}
    isolated remote function deleteReport(@display {label: "Report Id"} string reportId) returns error? {
        string path = utils:prepareUrl([API_BASE_PATH, ANALYTICS, REPORTS, reportId]);
        return check self.salesforceClient->delete(path);
    }

    # Runs an instance of a report synchronously.
    #
    # + reportId - Report Id
    # + return - ReportInstanceResult if successful or else `error`
    @display {label: "Run Report Synchronously"}
    isolated remote function runReportSync(@display {label: "Report Id"} string reportId)
            returns @display {label: "Report Instance Result"} ReportInstanceResult|error {
        string path = utils:prepareUrl([API_BASE_PATH, ANALYTICS, REPORTS, reportId]);
        return check self.salesforceClient->get(path);
    }

    # Runs an instance of a report asynchronously.
    #
    # + reportId - Report Id
    # + return - ReportInstance if successful or else `error`
    @display {label: "Run Report Asynchronously"}
    isolated remote function runReportAsync(@display {label: "Report Id"} string reportId)
            returns @display {label: "Report Instance"} ReportInstance|error {
        string path = utils:prepareUrl([API_BASE_PATH, ANALYTICS, REPORTS, reportId, INSTANCES]);
        return check self.salesforceClient->post(path, {});
    }

    # Lists asynchronous runs of a Report.
    #
    # + reportId - Report Id
    # + return - Array of ReportInstance if successful or else `error`
    @display {label: "List Async Report Runs"}
    isolated remote function listAsyncRunsOfReport(@display {label: "Report Id"} string reportId)
            returns @display {label: "Report Instances"} ReportInstance[]|error {
        string path = utils:prepareUrl([API_BASE_PATH, ANALYTICS, REPORTS, reportId, INSTANCES]);
        return check self.salesforceClient->get(path);
    }

    # Get report instance result.
    #
    # + reportId - Report Id
    # + instanceId - Instance Id
    # + return - ReportInstanceResult if successful or else `error`
    @display {label: "Get Report Instance Result"}
    isolated remote function getReportInstanceResult(@display {label: "Report Id"} string reportId, 
            @display {label: "Instance Id"} string instanceId) returns @display {label: "Report Instance Result"} 
            ReportInstanceResult|error {
        string path = utils:prepareUrl([API_BASE_PATH, ANALYTICS, REPORTS, reportId, INSTANCES, instanceId]);
        return check self.salesforceClient->get(path);
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


    // Added APIs
    
    # Retrieves the list of individual records that have been deleted within the given timespan.
    #
    # + sObjectName - SObject reference
    # + startDate - Start date of the timespan.
    # + endDate - End date of the timespan.
    isolated remote function getDeleted(string sObjectName, time:Civil startDate, time:Civil endDate) 
        returns DeletedRecordsResult|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DELETED]);
        string finalUrl = utils:addQueryParameters(path,{'start: check time:civilToString(startDate), 
            end: check time:civilToString(endDate)});
        return check self.salesforceClient->get(finalUrl);
    }

    # Retrieves the list of individual records that have been deleted within the given timespan.
    #
    # + sObjectName - SObject reference
    # + startDate - Start date of the timespan.
    # + endDate - End date of the timespan.
    isolated remote function getUpdated(string sObjectName, time:Civil startDate, time:Civil endDate) 
        returns UpdatedRecordsResults|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, UPDATED]);
        string finalUrl = utils:addQueryParameters(path,{'start: check time:civilToString(startDate), 
            end: check time:civilToString(endDate)});
        return check self.salesforceClient->get(finalUrl);
    }

    # Get the password information
    #
    # + userId - User ID
    isolated remote function getPasswordInfo(string userId) returns boolean|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, USER, userId, PASSWORD]);
        http:Response response = check self.salesforceClient->get(path);
        if response.statusCode == 200 {
            json payload = check response.getJsonPayload();
            map<json> payloadMap = check payload.ensureType();
            boolean isExpired = check payloadMap.isExpired;
            return isExpired;
        } else {
            json payload = check response.getJsonPayload();
            json[] jsonArray= check payload.ensureType();
            map<json> payloadMap = check jsonArray[0].ensureType();
            record {string message; string errorCode;} responseRecord = {message: check payloadMap.message, errorCode: check payloadMap.errorCode};
            return error("Error occurred while resetting the password" + responseRecord.toString());
        }
    }

    # Reset user password
    #
    # + userId - User ID
    isolated remote function resetPassword(string userId) returns byte[]|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, USER, userId, PASSWORD]);
        http:Response response = check self.salesforceClient->delete(path);
        if response.statusCode == 200 {
            json payload = check response.getJsonPayload();
            map<json> payloadMap = check payload.ensureType();
            string password = check payloadMap.NewPassword;
            return password.toBytes();
        } else {
            return error("Error occurred while resetting the password");
        }
    }

    # Change user password
    #
    # + userId - User ID
    # + newPassword - New user password
    isolated remote function changePassword(string userId, byte[] newPassword) returns error? {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, USER, userId, PASSWORD]);
        record{} payload = {"NewPassword" : check string:fromBytes(newPassword)};
        return check self.salesforceClient->post(path, payload);
    }

    # Returns a list of actions and their details
    #
    # + sObjectName - SObject reference
    isolated remote function getQuickActions(string sObjectName) returns QuickAction[]|error {
        string path = utils:prepareUrl([API_BASE_PATH, QUICK_ACTIONS]);
        http:Response response = check self.salesforceClient->get(path);
        if response.statusCode == 200 {
            json payload = check response.getJsonPayload();
            QuickAction[] actions = check payload.fromJsonWithType();
            return actions;
        } else {
            json payload = check response.getJsonPayload();
            return error("Error occurred while retrieving the quick actions. " + payload.toString());
        }
    }

    # Executes up to 25 subrequests in a single request.
    #
    # + batchRequest - record containing all the requests
    isolated remote function batch(Subrequest[] batchRequests, boolean haltOnError = false) returns BatchResult|error {
        string path = utils:prepareUrl([API_BASE_PATH, COMPOSITE, BATCH]);
        record{} payload = {"batchRequests" : batchRequests, "haltOnError" : haltOnError};
        http:Response response = check self.salesforceClient->post(path, payload);
        if response.statusCode == 200 {
            json jsonPayload = check response.getJsonPayload();
            return check jsonPayload.fromJsonWithType();
        } else {
            json jsonPayload = check response.getJsonPayload();
            return error("Error occurred while executing the batch request. " + payload.toString());
        }
    }

    # Retrieves information about alternate named layouts for a given object.
    #
    # + sObjectName - SObject reference
    # + layoutName - Name of the layout.
    isolated remote function getNamedLayouts(@display {label: "Name of the sObject"} string sObjectName, 
                                @display {label: "Name of the layout"} string layoutName, typedesc<record {}> returnType = <>)
                                    returns returnType|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "getNamedLayouts"
    } external;

    private isolated function processGetNamedLayouts(typedesc<record {}> returnType, string sobject, string id,
                                                    string[] fields) returns record {}|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sobject, id]);
        if fields.length() > 0 {
            path = path.concat(utils:appendQueryParams(fields));
        }
        json response = check self.salesforceClient->get(path);
        return check response.cloneWithType(returnType);
    }

    # Retrieve a list of general action types for the current organization.
    #
    # + subContext - Sub context
    isolated remote function getInvocableActions(string subContext, 
            typedesc<record {}> returnType = <>) returns returnType|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "getInvocableActions"
    } external;

    private isolated function processGetInvocableActions(string subContext, typedesc<record {}> returnType) returns record {}|error {
        string path = utils:prepareUrl([API_BASE_PATH, ACTIONS]) + subContext;
        json response = check self.salesforceClient->get(path);
        return check response.cloneWithType(returnType);
    }

    # Invoke Actions.
    #
    # + subContext - Sub context
    # + actionName - name of the action
    # + payload - payload for the action

    isolated remote function invokeActions(string subContext, record{} payload, 
            typedesc<record {}> returnType = <>) returns returnType|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "invokeActions"
    } external;

    private isolated function processInvokeActions(typedesc<record {}> returnType, string subContext, record{} payload) returns record {}|error {
        string path = utils:prepareUrl([API_BASE_PATH, ACTIONS]) + subContext;
        json response = check self.salesforceClient->get(path);
        return check response.cloneWithType(returnType);
    }

    # Delete record using external Id.
    #
    # + externalId - Name of the external id field
    # + value - value of the external id field.

    isolated remote function deleteRecordsUsingExtId(string externalId, string value) returns error? {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, externalId, value]);
        return check self.salesforceClient->delete(path);
    }

}
