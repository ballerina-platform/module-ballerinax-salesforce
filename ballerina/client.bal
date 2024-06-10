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
import ballerina/io;
import ballerina/jballerina.java;
import ballerina/lang.runtime;
import ballerina/time;
import ballerinax/'client.config;
import ballerinax/salesforce.utils;

# Ballerina Salesforce connector provides the capability to access Salesforce REST API.
# This connector lets you to perform operations for SObjects, query using SOQL, search using SOSL, and describe SObjects
# and organizational data.

public isolated client class Client {
    private final http:Client salesforceClient;
    private map<string> sfLocators = {};

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
    isolated remote function getOrganizationMetaData() returns
                                                    OrganizationMetadata|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS]);
        return check self.salesforceClient->get(path);
    }

    # Gets basic data of the specified object.
    #
    # + sobjectName - sObject name
    # + return - `SObjectBasicInfo` record if successful or else `error`
    isolated remote function getBasicInfo(string sobjectName)
                                                returns SObjectBasicInfo|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName]);
        return check self.salesforceClient->get(path);
    }

    # Completely describes the individual metadata at all levels of the specified object. Can be used to retrieve
    # the fields, URLs, and child relationships.
    #
    # + sObjectName - sObject name value
    # + return - `SObjectMetaData` record if successful or else `error`
    isolated remote function describe(string sObjectName)
                                            returns SObjectMetaData|error {

        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DESCRIBE]);
        return check self.salesforceClient->get(path);
    }

    # Query for actions displayed in the UI, given a user, a context, device format, and a record ID.
    #
    # + return - `SObjectBasicInfo` record if successful or else `error`
    isolated remote function getPlatformAction() returns SObjectBasicInfo|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, PLATFORM_ACTION]);
        return check self.salesforceClient->get(path);
    }

    //Describe Organization
    # Lists summary details about each REST API version available.
    #
    # + return - List of `Version` if successful. Else, the occurred `error`
    isolated remote function getApiVersions() returns Version[]|error {
        string path = utils:prepareUrl([BASE_PATH]);
        return check self.salesforceClient->get(path);
    }

    # Lists the resources available for the specified API version.
    #
    # + apiVersion - API version (v37)
    # + return - `Resources` as a map of string if successful. Else, the occurred `error`
    isolated remote function getResources(string apiVersion)
                                                    returns map<string>|error {
        string path = utils:prepareUrl([BASE_PATH, apiVersion]);
        json res = check self.salesforceClient->get(path);
        return toMapOfStrings(res);
    }

    # Lists the Limits information for your organization.
    #
    # + return - `OrganizationLimits` as a map of `Limit` if successful. Else, the occurred `error`
    isolated remote function getLimits() returns map<Limit>|error {
        string path = utils:prepareUrl([API_BASE_PATH, LIMITS]);
        json res = check self.salesforceClient->get(path);
        return toMapOfLimits(res);
    }

    # Gets an object record by ID.
    #
    # + sobjectName - sObject name
    # + id - sObject ID
    # + returnType - The payload, which is expected to be returned after data binding
    # + return - `record` if successful or else `error`
    isolated remote function getById(string sobjectName, string id, typedesc<record {}> returnType = <>)
                                    returns returnType|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "getRecordById"
    } external;

    private isolated function processGetRecordById(typedesc<record {}> returnType, string sobjectName, string id,
            string[] fields) returns record {}|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName, id]);
        if fields.length() > 0 {
            path = path.concat(utils:appendQueryParams(fields));
        }
        json response = check self.salesforceClient->get(path);
        return check response.cloneWithType(returnType);
    }

    # Gets an object record by external ID.
    #
    # + sobjectName - sObject name
    # + extIdField - External ID field name
    # + extId - External ID value
    # + returnType - The payload, which is expected to be returned after data binding
    # + return - Record if successful or else `error`
    isolated remote function getByExternalId(string sobjectName, string extIdField, string extId,
            typedesc<record {}> returnType = <>) returns returnType|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "getRecordByExtId"
    } external;

    private isolated function processGetRecordByExtId(typedesc<record {}> returnType, string sobjectName, string extIdField,
            string extId, string[] fields) returns record {}|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName, extIdField, extId]);
        if fields.length() > 0 {
            path = path.concat(utils:appendQueryParams(fields));
        }
        return check self.salesforceClient->get(path);
    }

    # Creates records based on relevant object type sent with json record.
    #
    # + sObjectName - sObject name value
    # + sObject - Record to be inserted
    # + return - `CreationResponse` if successful or else `error`
    isolated remote function create(string sObjectName, record {} sObject)
                                    returns CreationResponse|error {
        http:Request req = new;
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
        req.setJsonPayload(sObject.toJson());
        return check self.salesforceClient->post(path, req);
    }

    # Updates records based on relevant object ID.
    #
    # + sObjectName - sObject name value
    # + id - sObject ID
    # + sObject - Record to be updated
    # + return - `Nil` if successful, else returns an error
    isolated remote function update(string sObjectName, string id, record {} sObject)
                                    returns error? {
        http:Request req = new;
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        req.setJsonPayload(sObject.toJson());
        return check self.salesforceClient->patch(path, req);
    }

    # Upsert a record based on the value of a specified external ID field.
    #
    # + sObjectName - sObject name value
    # + externalIdField - External ID field of an object
    # + externalId - External ID
    # + sObject - Record to be upserted
    # + return - `Nil` if successful or else `error`
    isolated remote function upsert(string sObjectName, string externalIdField, string externalId,
            record {} sObject) returns error? {
        http:Request req = new;
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, externalIdField, externalId]);
        req.setJsonPayload(sObject.toJson());
        return check self.salesforceClient->patch(path, req);
    }

    # Delete existing records based on relevant object ID.
    #
    # + sObjectName - SObject name value
    # + id - SObject ID
    # + return - `Nil` if successful or else `error`
    isolated remote function delete(string sObjectName, string id)
                                    returns error? {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        return check self.salesforceClient->delete(path);
    }

    # Lists reports.
    #
    # + return - Array of `Report` if successful or else `error`
    isolated remote function listReports() returns Report[]|error {
        string path = utils:prepareUrl([API_BASE_PATH, ANALYTICS, REPORTS]);
        return check self.salesforceClient->get(path);
    }

    # Deletes a report.
    #
    # + reportId - Report Id
    # + return - `Nil` if the report deletion is successful or else an error
    isolated remote function deleteReport(string reportId) returns error? {
        string path = utils:prepareUrl([API_BASE_PATH, ANALYTICS, REPORTS, reportId]);
        return check self.salesforceClient->delete(path);
    }

    # Runs an instance of a report synchronously.
    #
    # + reportId - Report Id
    # + return - `ReportInstanceResult` if successful or else `error`
    isolated remote function runReportSync(string reportId)
            returns ReportInstanceResult|error {
        string path = utils:prepareUrl([API_BASE_PATH, ANALYTICS, REPORTS, reportId]);
        return check self.salesforceClient->get(path);
    }

    # Runs an instance of a report asynchronously.
    #
    # + reportId - Report Id
    # + return - `ReportInstance` if successful or else `error`
    isolated remote function runReportAsync(string reportId) returns ReportInstance|error {
        string path = utils:prepareUrl([API_BASE_PATH, ANALYTICS, REPORTS, reportId, INSTANCES]);
        return check self.salesforceClient->post(path, {});
    }

    # Lists asynchronous runs of a Report.
    #
    # + reportId - Report Id
    # + return - Array of `ReportInstance` if successful or else `error`
    isolated remote function listAsyncRunsOfReport(string reportId) returns ReportInstance[]|error {
        string path = utils:prepareUrl([API_BASE_PATH, ANALYTICS, REPORTS, reportId, INSTANCES]);
        return check self.salesforceClient->get(path);
    }

    # Get report instance result.
    #
    # + reportId - Report Id
    # + instanceId - Instance Id
    # + return - `ReportInstanceResult` if successful or else `error`
    isolated remote function getReportInstanceResult(string reportId, string instanceId) returns
            ReportInstanceResult|error {
        string path = utils:prepareUrl([API_BASE_PATH, ANALYTICS, REPORTS, reportId, INSTANCES, instanceId]);
        return check self.salesforceClient->get(path);
    }

    # Executes the specified SOQL query.
    #
    # + soql - SOQL query
    # + returnType - The payload, which is expected to be returned after data binding
    # + return - `stream<{returnType}, error?>` if successful. Else, the occurred `error`
    isolated remote function query(string soql, typedesc<record {}> returnType = <>)
                                    returns stream<returnType, error?>|error = @java:Method {
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
    # + returnType - The payload, which is expected to be returned after data binding
    # + return - `stream<{returnType}, error?>` record if successful. Else, the occurred `error`
    isolated remote function search(string sosl, typedesc<record {}> returnType = <>)
                                    returns stream<returnType, error?>|error = @java:Method {
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
    # + startDate - Start date of the timespan
    # + endDate - End date of the timespan
    # + return - `DeletedRecordsResult` record if successful or else `error`
    isolated remote function getDeletedRecords(string sObjectName, time:Civil startDate, time:Civil endDate)
        returns DeletedRecordsResult|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DELETED]);
        string finalUrl = utils:addQueryParameters(path, {
            'start: check time:civilToString(removeDecimalPlaces(startDate)),
            end: check time:civilToString(removeDecimalPlaces(endDate))
        });
        return check self.salesforceClient->get(finalUrl);
    }

    # Retrieves the list of individual records that have been updated within the given timespan.
    #
    # + sObjectName - SObject reference
    # + startDate - Start date of the timespan
    # + endDate - End date of the timespan
    # + return - `UpdatedRecordsResults` record if successful or else `error`
    isolated remote function getUpdatedRecords(string sObjectName, time:Civil startDate, time:Civil endDate)
        returns UpdatedRecordsResults|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, UPDATED]);
        string finalUrl = utils:addQueryParameters(path, {
            'start: check time:civilToString(removeDecimalPlaces(startDate)),
            end: check time:civilToString(removeDecimalPlaces(endDate))
        });
        return check self.salesforceClient->get(finalUrl);
    }

    # Get the password information
    #
    # + userId - User ID
    # + return - `boolean` if successful or else `error`
    isolated remote function isPasswordExpired(string userId) returns boolean|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, USER, userId, PASSWORD]);
        http:Response response = check self.salesforceClient->get(path);
        if response.statusCode == 200 {
            json payload = check response.getJsonPayload();
            map<json> payloadMap = check payload.ensureType();
            boolean isExpired = check payloadMap.isExpired;
            return isExpired;
        } else {
            json payload = check response.getJsonPayload();
            json[] jsonArray = check payload.ensureType();
            map<json> payloadMap = check jsonArray[0].ensureType();
            record {string message; string errorCode;} responseRecord = {message: check payloadMap.message, errorCode: check payloadMap.errorCode};
            return error("Error occurred while checking the password status! ",
                httpCode = response.statusCode, errorCode = responseRecord.errorCode,
                errormessage = responseRecord.message);
        }
    }

    # Reset the user password.
    #
    # + userId - User ID
    # + return - `byte[]` if successful or else `error`
    isolated remote function resetPassword(string userId) returns byte[]|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, USER, userId, PASSWORD]);
        return check self.salesforceClient->delete(path);
    }

    # Change the user password
    #
    # + userId - User ID
    # + newPassword - New user password as a string
    # + return - `Nil` if successful or else `error`
    isolated remote function changePassword(string userId, string newPassword) returns error? {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, USER, userId, PASSWORD]);
        record {} payload = {"NewPassword": newPassword};
        return check self.salesforceClient->post(path, payload);
    }

    # Returns a list of actions and their details
    #
    # + sObjectName - SObject reference
    # + return - `QuickAction[]` if successful or else `error`
    isolated remote function getQuickActions(string sObjectName) returns QuickAction[]|error {
        string path = utils:prepareUrl([API_BASE_PATH, QUICK_ACTIONS]);
        return check self.salesforceClient->get(path);
    }

    # Executes up to 25 sub-requests in a single request.
    #
    # + batchRequests - A record containing all the requests
    # + haltOnError - If true, the request halts when an error occurs on an individual sub-request
    # + return - `BatchResult` if successful or else `error`
    isolated remote function batch(Subrequest[] batchRequests, boolean haltOnError = false) returns BatchResult|error {
        string path = utils:prepareUrl([API_BASE_PATH, COMPOSITE, BATCH]);
        record {} payload = {"batchRequests": batchRequests, "haltOnError": haltOnError};
        return check self.salesforceClient->post(path, payload);
    }

    # Retrieves information about alternate named layouts for a given object.
    #
    # + sObjectName - SObject reference
    # + layoutName - Name of the layout
    # + returnType - The payload type, which is expected to be returned after data binding
    # + return - Record of `returnType` if successful or else `error`
    isolated remote function getNamedLayouts(string sObjectName, string layoutName, typedesc<record {}> returnType = <>)
                                    returns returnType|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "getNamedLayouts"
    } external;

    private isolated function processGetNamedLayouts(typedesc<record {}> returnType, string sobjectName, string layoutName
                                                    ) returns record {}|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName, DESCRIBE, NAMED_LAYOUTS, layoutName]);
        json response = check self.salesforceClient->get(path);
        return check response.cloneWithType(returnType);
    }

    # Retrieve a list of general action types for the current organization.
    #
    # + subContext - Sub context
    # + returnType - The payload type, which is expected to be returned after data binding
    # + return - Record of `returnType` if successful or else `error`
    isolated remote function getInvocableActions(string subContext,
            typedesc<record {}> returnType = <>) returns returnType|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "getInvocableActions"
    } external;

    private isolated function processGetInvocableActions(typedesc<record {}> returnType, string subContext) returns record {}|error {
        string path = utils:prepareUrl([API_BASE_PATH, ACTIONS]) + subContext;
        json response = check self.salesforceClient->get(path);
        return check response.cloneWithType(returnType);
    }

    # Invoke Actions.
    #
    # + subContext - Sub context
    # + payload - Payload for the action
    # + returnType - The type of the returned variable
    # + return - Record of `returnType` if successful or else `error`
    isolated remote function invokeActions(string subContext, record {} payload,
            typedesc<record {}> returnType = <>) returns returnType|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "invokeActions"
    } external;

    private isolated function processInvokeActions(typedesc<record {}> returnType, string subContext, record {} payload) returns record {}|error {
        string path = utils:prepareUrl([API_BASE_PATH, ACTIONS]) + subContext;
        return check self.salesforceClient->get(path);
    }

    # Delete record using external Id.
    #
    # + sObjectName - Name of the sObject
    # + externalId - Name of the external id field
    # + value - Value of the external id field
    # + return - `Nil` if successful or else `error`
    isolated remote function deleteRecordsUsingExtId(string sObjectName, string externalId, string value) returns error? {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, externalId, value]);
        return check self.salesforceClient->delete(path);
    }

    # Access Salesforce APEX resource.
    #
    # + urlPath - URI path
    # + methodType - HTTP method type
    # + payload - Payload
    # + returnType - The payload type, which is expected to be returned after data binding
    # + return - `string|int|record{}` type if successful or else `error`
    isolated remote function apexRestExecute(string urlPath, http:Method methodType,
            record {} payload = {}, typedesc<record {}|string|int?> returnType = <>)
            returns returnType|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "apexRestExecute"
    } external;

    private isolated function processApexExecute(typedesc<record {}|string|int?> returnType, string urlPath, http:Method methodType, record {} payload) returns record {}|string|int|error? {
        string path = utils:prepareUrl([APEX_BASE_PATH, urlPath]);
        http:Response response = new;
        match methodType {
            "GET" => {
                response = check self.salesforceClient->get(path);
            }
            "POST" => {
                response = check self.salesforceClient->post(path, payload);
            }
            "DELETE" => {
                response = check self.salesforceClient->delete(path);
            }
            "PUT" => {
                response = check self.salesforceClient->put(path, payload);
            }
            "PATCH" => {
                response = check self.salesforceClient->patch(path, payload);
            }
            _ => {
                return error("Invalid Method");
            }
        }
        if response.statusCode == 200 || response.statusCode == 201 {
            if response.getContentType() == "" {
                return;
            }
            json responsePayload = check response.getJsonPayload();
            return check responsePayload.cloneWithType(returnType);
        } else {
            json responsePayload = check response.getJsonPayload();
            return error("Error occurred while executing the apex request. ",
                httpCode = response.statusCode, details = responsePayload);
        }
    }

    // Bulk v2

    # Creates a bulkv2 ingest job.
    #
    # + payload - The payload for the bulk job
    # + return - `BulkJob` if successful or else `error`
    isolated remote function createIngestJob(BulkCreatePayload payload) returns BulkJob|error {
        string path = utils:prepareUrl([API_BASE_PATH, JOBS, INGEST]);
        return check self.salesforceClient->post(path, payload);
    }

    # Creates a bulkv2 query job.
    #
    # + payload - The payload for the bulk job
    # + return - `BulkJob` if successful or else `error`
    isolated remote function createQueryJob(BulkCreatePayload payload) returns BulkJob|error {
        string path = utils:prepareUrl([API_BASE_PATH, JOBS, QUERY]);
        return check self.salesforceClient->post(path, payload);
    }

    # Creates a bulkv2 query job and provide future value.
    #
    # + payload - The payload for the bulk job
    # + return - `future<BulkJobInfo>` if successful else `error`
    isolated remote function createQueryJobAndWait(BulkCreatePayload payload) returns future<BulkJobInfo|error>|error {
        string path = utils:prepareUrl([API_BASE_PATH, JOBS, QUERY]);
        http:Response response = check self.salesforceClient->post(path, payload);
        if response.statusCode != 200 {
            return error("Error occurred while closing the bulk job. ", httpCode = response.statusCode);
        }
        BulkJob bulkJob = check (check response.getJsonPayload()).fromJsonWithType();
        final string jobPath = utils:prepareUrl([API_BASE_PATH, JOBS, QUERY, bulkJob.id]);
        worker A returns BulkJobInfo|error {
            while true {
                runtime:sleep(2);
                http:Response jobStatus = check self.salesforceClient->get(jobPath);
                if jobStatus.statusCode != 200 {
                    return error("Error occurred while checking the status of the bulk job. ",
                        httpCode = jobStatus.statusCode);
                } else {
                    json responsePayload = check jobStatus.getJsonPayload();
                    BulkJobInfo jobInfo = check responsePayload.cloneWithType(BulkJobInfo);
                    if jobInfo.state == JOB_COMPLETE || jobInfo.state == FAILED || jobInfo.state == ABORTED {
                        return jobInfo;
                    }
                }
            }
        }
        return A;
    }

    # Retrieves detailed information about a job.
    #
    # + bulkJobId - Id of the bulk job
    # + bulkOperation - The processing operation for the job
    # + return - `BulkJobInfo` if successful or else `error`
    isolated remote function getJobInfo(string bulkJobId, BulkOperation bulkOperation) returns BulkJobInfo|error {
        string path = utils:prepareUrl([API_BASE_PATH, JOBS, bulkOperation, bulkJobId]);
        return check self.salesforceClient->get(path);
    };

    # Uploads data for a job using CSV data.
    #
    # + bulkJobId - Id of the bulk job
    # + content - CSV data to be added
    # + return - `Nil` record if successful or `error` if unsuccessful
    isolated remote function addBatch(string bulkJobId, string|string[][]|stream<string[], error?>|io:ReadableByteChannel content) returns error? {
        string payload = "";
        string path = utils:prepareUrl([API_BASE_PATH, JOBS, INGEST, bulkJobId, BATCHES]);
        if content is io:ReadableByteChannel {
            payload = check convertToString(content);
        } else if content is string[][]|stream<string[], error?> {
            payload = check convertStringListToString(content);
        } else {
            payload = content;
        }
        http:Response response = check self.salesforceClient->put(path, payload, mediaType = "text/csv");
        if response.statusCode != 201 {
            return error("Error occurred while adding the batch. ", httpCode = response.statusCode);
        }
    };

    # Get details of all the jobs.
    #
    # + jobType - Type of the job
    # + return - `AllJobs` record if successful or `error` if unsuccessful
    isolated remote function getAllJobs(JobType? jobType = ()) returns error|AllJobs {
        string path = utils:prepareUrl([API_BASE_PATH, JOBS, INGEST]) +
            ((jobType is ()) ? "" : string `?jobType=${jobType}`);
        return check self.salesforceClient->get(path);
    }

    # Get details of all query jobs.
    #
    # + jobType - Type of the job
    # + return - `AllJobs` if successful else `error`
    isolated remote function getAllQueryJobs(JobType? jobType = ()) returns error|AllJobs {
        string path = utils:prepareUrl([API_BASE_PATH, JOBS, INGEST]) +
            ((jobType is ()) ? "" : string `?jobType=${jobType}`);
        return check self.salesforceClient->get(path);
    }

    # Get job status information.
    #
    # + status - Status of the job
    # + bulkJobId - Id of the bulk job
    # + return - `string[][]` if successful else `error`
    isolated remote function getJobStatus(string bulkJobId, Status status)
            returns string[][]|error {
        string path = utils:prepareUrl([API_BASE_PATH, JOBS, INGEST, bulkJobId, status]);
        http:Response response = check self.salesforceClient->get(path);
        if response.statusCode == 200 {
            string textPayload = check response.getTextPayload();
            if textPayload == "" {
                return [];
            }
            string[][] result = check parseCsvString(textPayload);
            return result;
        } else {
            json responsePayload = check response.getJsonPayload();
            return error("Error occurred while retrieving the bulk job status. ",
                httpCode = response.statusCode, details = responsePayload);
        }

    }

    # Get bulk query job results
    #
    # + bulkJobId - Id of the bulk job
    # + maxRecords - The maximum number of records to retrieve per set of results for the query
    # + return - The resulting string[][] if successful else `error`
    isolated remote function getQueryResult(string bulkJobId, int? maxRecords = ()) returns string[][]|error {
        string result = check self.processGetBulkJobResults(bulkJobId, maxRecords);
        if result == "" {
            return [];
        } else {
            return check parseCsvString(result);
        }
    }

    private isolated function processGetBulkJobResults(string bulkJobId, int? maxRecords = ()) returns string|error {
        string path = "";
        string batchingParams = "";

        if maxRecords != () {
            lock {
                if self.sfLocators.hasKey(bulkJobId) {
                    string locator = self.sfLocators.get(bulkJobId);
                    if locator is "null" {
                        return "";
                    }
                    batchingParams = string `results?maxRecords=${maxRecords}&locator=${locator}`;
                } else {
                    batchingParams = string `results?maxRecords=${maxRecords}`;
                }
            }
            path = utils:prepareUrl([API_BASE_PATH, JOBS, QUERY, bulkJobId, batchingParams]);
            // Max records value default, we might not know when the locator comes
        } else {
            lock {
                if self.sfLocators.hasKey(bulkJobId) {
                    string locator = self.sfLocators.get(bulkJobId);
                    if locator is "null" {
                        return "";
                    }
                    batchingParams = string `results?locator=${locator}`;
                    path = utils:prepareUrl([API_BASE_PATH, JOBS, QUERY, bulkJobId, batchingParams]);
                } else {
                    path = utils:prepareUrl([API_BASE_PATH, JOBS, QUERY, bulkJobId, RESULT]);
                }
            }
        }

        http:Response response = check self.salesforceClient->get(path);
        if response.statusCode == 200 {
            string textPayload = check response.getTextPayload();
            lock {
                string|http:HeaderNotFoundError locatorValue = response.getHeader("sforce-locator");
                if locatorValue is string {
                    self.sfLocators[bulkJobId] = locatorValue;
                } // header not found error ignored 
            }
            return textPayload;
        } else {
            json responsePayload = check response.getJsonPayload();
            return error("Error occurred while retrieving the query job results. ",
                httpCode = response.statusCode, details = responsePayload);
        }
    }

    # Get bulk query job results
    #
    # + bulkJobId - Id of the bulk job
    # + maxRecords - The maximum number of records to retrieve per set of results for the query
    # + T - Type description of the required data type
    # + return - The resulting data in the given format if successful else `error`
    isolated remote function getQueryResultWithType(string bulkJobId, int? maxRecords = (), typedesc<record {}[]> T = <>)
        returns T|error =
    @java:Method {
        'class: "io.ballerinax.salesforce.BulkJobResultProcessor",
        name: "parseResultsToInputType"
    } external;

    # Abort the bulkv2 job.
    #
    # + bulkJobId - Id of the bulk job
    # + bulkOperation - The processing operation for the job
    # + return - `()` if successful else `error`
    isolated remote function abortJob(string bulkJobId, BulkOperation bulkOperation) returns BulkJobInfo|error {
        string path = utils:prepareUrl([API_BASE_PATH, JOBS, bulkOperation, bulkJobId]);
        record {} payload = {"state": "Aborted"};
        return check self.salesforceClient->patch(path, payload);
    }

    # Delete a bulkv2 job.
    #
    # + bulkJobId - Id of the bulk job
    # + bulkOperation - The processing operation for the job
    # + return - `()` if successful else `error`
    isolated remote function deleteJob(string bulkJobId, BulkOperation bulkOperation) returns error? {
        string path = utils:prepareUrl([API_BASE_PATH, JOBS, bulkOperation, bulkJobId]);
        return check self.salesforceClient->delete(path);
    }

    # Notifies Salesforce servers that the upload of job data is complete.
    #
    # + bulkJobId - Id of the bulk job
    # + return - future<BulkJobInfo> if successful else `error`
    isolated remote function closeIngestJobAndWait(string bulkJobId) returns error|future<BulkJobInfo|error> {
        final string path = utils:prepareUrl([API_BASE_PATH, JOBS, INGEST, bulkJobId]);
        record {} payload = {"state": "UploadComplete"};
        http:Response response = check self.salesforceClient->patch(path, payload);
        if response.statusCode != 200 {
            return error("Error occurred while closing the bulk job. ", httpCode = response.statusCode);
        }
        worker A returns BulkJobInfo|error {
            while true {
                runtime:sleep(2);
                http:Response jobStatus = check self.salesforceClient->get(path);
                if jobStatus.statusCode != 200 {
                    return error("Error occurred while checking the status of the bulk job. ",
                        httpCode = jobStatus.statusCode);
                } else {
                    json responsePayload = check jobStatus.getJsonPayload();
                    BulkJobInfo jobInfo = check responsePayload.cloneWithType(BulkJobInfo);
                    if jobInfo.state == JOB_COMPLETE || jobInfo.state == FAILED || jobInfo.state == ABORTED {
                        return jobInfo;
                    }
                }
            }
        }
        return A;
    }

    # Notifies Salesforce servers that the upload of job data is complete.
    #
    # + bulkJobId - Id of the bulk job
    # + return - BulkJobInfo if successful else `error`
    isolated remote function closeIngestJob(string bulkJobId) returns error|BulkJobCloseInfo {
        final string path = utils:prepareUrl([API_BASE_PATH, JOBS, INGEST, bulkJobId]);
        record {} payload = {"state": "UploadComplete"};
        return check self.salesforceClient->patch(path, payload);
    }
}
