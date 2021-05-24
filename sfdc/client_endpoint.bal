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

# The Salesforce Client object.
# 
# + salesforceClient - OAuth2 client endpoint
# + clientHandler - http:ClientOAuth2Handler class instance 
# + clientConfig - http:OAuth2RefreshTokenGrantConfig|http:BearerTokenConfig record to initialize the Salesforce client
@display {
    label: "Salesforce Client",
    iconPath: "SalesforceLogo.png"
}
public client class Client {
    http:Client salesforceClient;
    http:OAuth2RefreshTokenGrantConfig|http:BearerTokenConfig clientConfig;
    http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler clientHandler;

    # Salesforce Connector endpoint initialization function.
    # 
    # + salesforceConfig - Salesforce Connector configuration
    public isolated function init(SalesforceConfiguration salesforceConfig) returns Error? {
        self.clientConfig = salesforceConfig.clientConfig;
        http:ClientSecureSocket? socketConfig = salesforceConfig?.secureSocketConfig;

        http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler|error httpHandlerResult;
        if self.clientConfig is http:OAuth2RefreshTokenGrantConfig {
            httpHandlerResult =  trap new(<http:OAuth2RefreshTokenGrantConfig>self.clientConfig);
        } else {
            httpHandlerResult =  trap new(<http:BearerTokenConfig>self.clientConfig);
        }

        if (httpHandlerResult is http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler) {
            self.clientHandler = httpHandlerResult;
        } else {
            return prepareError(INVALID_CLIENT_CONFIG);
        }

        // Create an HTTP client.
        http:Client|http:ClientError|error httpClientResult;
        if (socketConfig is http:ClientSecureSocket) {
            httpClientResult = trap new (salesforceConfig.baseUrl, {
                auth: salesforceConfig.clientConfig,
                secureSocket: socketConfig
            });
        } else {
            httpClientResult = trap new (salesforceConfig.baseUrl, {auth: salesforceConfig.clientConfig});
        }

        if (httpClientResult is http:Client) {
            self.salesforceClient = httpClientResult;
        } else {
            return prepareError(INVALID_CLIENT_CONFIG);
        }
    }

    # Lists the available objects and their metadata for your organization and available to the logged-in user.
    # 
    # + return - `OrgMetadata` record if successful else Error occured
    @display {label: "Get available objects"}
    isolated remote function describeAvailableObjects() returns @tainted @display {label: "Organization metadata"} 
                                                     OrgMetadata|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS]);
        json res = check self->getRecord(path);
        return toOrgMetadata(res);
    }

    # Describes the individual metadata for the specified object.
    # 
    # + sobjectName - sobject name
    # + return - `SObjectBasicInfo` record if successful else Error occured
    @display {label: "Get SObject basic information"}
    isolated remote function getSObjectBasicInfo(@display {label: "SObject name"} string sobjectName) returns
                                                 @tainted @display {label: "SObject basic information"}
                                                 SObjectBasicInfo|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName]);
        json res = check self->getRecord(path);
        return toSObjectBasicInfo(res);
    }

    # Completely describes the individual metadata at all levels for the specified object. Can be used to retrieve
    # the fields, URLs, and child relationships.
    # 
    # + sObjectName - SObject name value
    # + return - `SObjectMetaData` record if successful else Error occured
    @display {label: "Get All information about SObject"}
    isolated remote function describeSObject(@display {label: "SObject name"} string sObjectName) returns
                                             @tainted @display {label: "SObject metadata"} SObjectMetaData|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DESCRIBE]);
        json res = check self->getRecord(path);
        return toSObjectMetaData(res);
    }

    # Query for actions displayed in the UI, given a user, a context, device format, and a record ID.
    # 
    # + return - `SObjectBasicInfo` record if successful else Error occured
    @display {label: "Get SObject platform action"}
    isolated remote function sObjectPlatformAction() returns @tainted @display {label: "SObject basic information"}
                                                  SObjectBasicInfo|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, PLATFORM_ACTION]);
        json res = check self->getRecord(path);
        return toSObjectBasicInfo(res);
    }

    //Basic CRUD
    # Accesses records based on the specified object ID, can be used with external objects.
    # 
    # + path - Resource path
    # + return - `json` result if successful else Error occured
    @display {label: "Get record"}
    isolated remote function getRecord(@display {label: "Resource path"} string path) returns
                                       @tainted @display {label: "Result"} json|Error {
        http:Response|error response = self.salesforceClient->get(path);
        return checkAndSetErrors(response);
    }

    # Create records based on relevant object type sent with json record.
    # 
    # + sObjectName - SObject name value
    # + recordPayload - JSON record to be inserted
    # + return - created entity ID if successful else Error occured
    @display {label: "Create record"}
    isolated remote function createRecord(@display {label: "SObject name"} string sObjectName,
                                          @display {label: "Record payload"} json recordPayload) returns
                                          @tainted @display {label: "Created entity ID"} string|Error {
        http:Request req = new;
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
        req.setJsonPayload(recordPayload);

        http:Response|error response = self.salesforceClient->post(path, req);
        json|Error result = checkAndSetErrors(response);
        if (result is json) {
            json|error resultId = result.id;
            if (resultId is json) {
                return resultId.toString();
            } else {
                return error Error(resultId.message());
            }
        } else {
            return result;
        }
    }

    # Update records based on relevant object id.
    # 
    # + sObjectName - SObject name value
    # + id - SObject id
    # + recordPayload - JSON record to be updated
    # + return - true if successful else false or Error occured
    @display {label: "Update record"}
    isolated remote function updateRecord(@display {label: "SObject name"} string sObjectName,
                                          @display {label: "SObject ID"} string id,
                                          @display {label: "Record payload"} json recordPayload) returns
                                          @tainted @display {label: "Result"} boolean|Error {
        http:Request req = new;
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        req.setJsonPayload(recordPayload);

        http:Response|error response = self.salesforceClient->patch(path, req);
        json|Error result = checkAndSetErrors(response, false);
        if (result is json) {
            return true;
        } else {
            return result;
        }
    }

    # Delete existing records based on relevant object id.
    # 
    # + sObjectName - SObject name value
    # + id - SObject id
    # + return - true if successful else false or Error occured
    @display {label: "Delete record"}
    isolated remote function deleteRecord(@display {label: "SObject name"} string sObjectName,
                                          @display {label: "SObject ID"} string id) returns
                                          @tainted @display {label: "Result"} boolean|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        http:Response|error response = self.salesforceClient->delete(path, ());

        json|Error result = checkAndSetErrors(response, false);
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
    # + return - `json` result if successful else `Error` occured
    @display {label: "Get record by ID"}
    isolated remote function getRecordById(@display {label: "SObject name"} string sobject,
                                           @display {label: "SObject ID"} string id,
                                           @display {label: "Fields to retrieve"} string... fields) returns 
                                           @tainted @display {label: "Result"} json|Error {
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
    # + return - `json` result if successful else `Error` occured
    @display {label: "Get record by external ID"}
    isolated remote function getRecordByExtId(@display {label: "SObject name"} string sobject,
                                              @display {label: "External ID field name"} string extIdField, 
                                              @display {label: "External ID"} string extId,
                                              @display {label: "Fields to retrieve"} string... fields) returns 
                                              @tainted @display {label: "Result"} json|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobject, extIdField, extId]);
        if (fields.length() > 0) {
            path = path.concat(self.appendQueryParams(fields));
        }
        json response = check self->getRecord(path);
        return response;
    }

    //Account
    # Accesses Account SObject records based on the Account object ID.
    # 
    # + accountId - Account ID
    # + fields - Fields to retireve
    # + return - JSON response if successful or else an sfdc:Error
    @display {label: "Get account by ID"}
    isolated remote function getAccountById(@display {label: "Account ID"} string accountId,
                                            @display {label: "Fields to retrieve"} string... fields) returns 
                                            @tainted @display {label: "Result"} json|Error {
        json res = check self->getRecordById(ACCOUNT, accountId, ...fields);
        return res;
    }

    # Creates new Account object record.
    # 
    # + accountRecord - Account JSON record to be inserted
    # + return - Account ID if successful or else an sfdc:Error
    @display {label: "Create account"}
    isolated remote function createAccount(@display {label: "Account record"} json accountRecord) returns
                                           @tainted @display {label: "Account ID"} string|Error {
        return self->createRecord(ACCOUNT, accountRecord);
    }

    # Deletes existing Account's records.
    # 
    # + accountId - Account ID
    # + return - `true` if successful `false` otherwise, or an sfdc:Error in case of an error
    @display {label: "Delete account"}
    isolated remote function deleteAccount(@display {label: "Account ID"} string accountId) returns
                                           @tainted @display {label: "Result"} boolean|Error {
        return self->deleteRecord(ACCOUNT, accountId);
    }

    # Updates existing Account object record.
    # 
    # + accountId - Account ID
    # + accountRecord - account record json payload
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Update account"}
    isolated remote function updateAccount(@display {label: "Account ID"} string accountId,
                                           @display {label: "Account record"} json accountRecord) returns
                                           @tainted @display {label: "Result"} boolean|Error {
        return self->updateRecord(ACCOUNT, accountId, accountRecord);
    }

    //Lead
    # Accesses Lead SObject records based on the Lead object ID.
    # 
    # + leadId - Lead ID
    # + fields - Fields to retireve
    # + return - JSON response if successful or else an sfdc:Error
    @display {label: "Get lead by ID"}
    isolated remote function getLeadById(@display {label: "Lead ID"} string leadId,
                                         @display {label: "Fields to retrieve"} string... fields) returns
                                         @tainted @display {label: "Result"} json|Error {
        json res = check self->getRecordById(LEAD, leadId, ...fields);
        return res;
    }

    # Creates new Lead object record.
    # 
    # + leadRecord - Lead JSON record to be inserted
    # + return - Lead ID if successful or else an sfdc:Error
    @display {label: "Create lead"}
    isolated remote function createLead(@display {label: "Lead record"} json leadRecord) returns
                                        @tainted @display {label: "Lead ID"} string|Error {
        return self->createRecord(LEAD, leadRecord);
    }

    # Deletes existing Lead's records.
    # 
    # + leadId - Lead ID
    # + return - `true`  if successful, `false` otherwise or an sfdc:Error incase of an error
    @display {label: "Delete lead"}
    isolated remote function deleteLead(@display {label: "Lead ID"} string leadId) returns
                                        @tainted @display {label: "Result"} boolean|Error {
        return self->deleteRecord(LEAD, leadId);
    }

    # Updates existing Lead object record.
    # 
    # + leadId - Lead ID
    # + leadRecord - Lead JSON record
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Update lead"}
    isolated remote function updateLead(@display {label: "Lead ID"} string leadId, 
                                        @display {label: "Lead record"} json leadRecord) returns
                                        @tainted @display {label: "Result"} boolean|Error {
        return self->updateRecord(LEAD, leadId, leadRecord);
    }

    //Contact
    # Accesses Contacts SObject records based on the Contact object ID.
    # 
    # + contactId - Contact ID
    # + fields - Fields to retireve
    # + return - JSON result if successful or else an sfdc:Error
    @display {label: "Get contact by ID"}
    isolated remote function getContactById(@display {label: "Contact ID"} string contactId,
                                            @display {label: "Fields to retrieve"} string... fields) returns
                                            @tainted @display {label: "Result"} json|Error {
        json res = check self->getRecordById(CONTACT, contactId, ...fields);
        return res;
    }

    # Creates new Contact object record.
    # 
    # + contactRecord - JSON contact record
    # + return - Contact ID if successful or else an sfdc:Error
    @display {label: "Create contact"}
    isolated remote function createContact(@display {label: "Contact record"} json contactRecord) returns
                                           @tainted @display {label: "Contact ID"} string|Error {
        return self->createRecord(CONTACT, contactRecord);
    }

    # Deletes existing Contact's records.
    # 
    # + contactId - Contact ID
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Delete contact"}
    isolated remote function deleteContact(@display {label: "Contact ID"} string contactId) returns
                                           @tainted @display {label: "Result"} boolean|Error {
        return self->deleteRecord(CONTACT, contactId);
    }

    # Updates existing Contact object record.
    # 
    # + contactId - Contact ID
    # + contactRecord - JSON contact record
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Update contact"}
    isolated remote function updateContact(@display {label: "Contact ID"} string contactId,
                                           @display {label: "Contact record"} json contactRecord) returns
                                           @tainted @display {label: "Result"} boolean|Error {
        return self->updateRecord(CONTACT, contactId, contactRecord);
    }

    //Opportunity
    # Accesses Opportunities SObject records based on the Opportunity object ID.
    # 
    # + opportunityId - Opportunity ID
    # + fields - Fields to retireve
    # + return - JSON response if successful or else an sfdc:Error
    @display {label: "Get opportunity by ID"}
    isolated remote function getOpportunityById(@display {label: "Opportunity ID"} string opportunityId,
                                                @display {label: "Fields to retrieve"} string... fields) returns
                                                @tainted @display {label: "Result"} json|Error {
        json res = check self->getRecordById(OPPORTUNITY, opportunityId, ...fields);
        return res;
    }

    # Creates new Opportunity object record.
    # 
    # + opportunityRecord - JSON opportunity record
    # + return - Opportunity ID if successful or else an sfdc:Error
    @display {label: "Create opportunity"}
    isolated remote function createOpportunity(@display {label: "Opportunity record"} json opportunityRecord) returns
                                               @tainted @display {label: "Opportunity ID"} string|Error {
        return self->createRecord(OPPORTUNITY, opportunityRecord);
    }

    # Deletes existing Opportunity's records.
    # 
    # + opportunityId - Opportunity ID
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Delete opportunity"}
    isolated remote function deleteOpportunity(@display {label: "Opportunity ID"} string opportunityId) returns
                                               @tainted @display {label: "Result"} boolean|Error {
        return self->deleteRecord(OPPORTUNITY, opportunityId);
    }

    # Updates existing Opportunity object record.
    # 
    # + opportunityId - Opportunity ID
    # + opportunityRecord - Opportunity json payload
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Update opportunity"}
    isolated remote function updateOpportunity(@display {label: "Opportunity ID"} string opportunityId,
                                               @display {label: "Opportunity Record"} json opportunityRecord) returns
                                               @tainted @display {label: "Result"} boolean|Error {
        return self->updateRecord(OPPORTUNITY, opportunityId, opportunityRecord);
    }

    //Product
    # Accesses Products SObject records based on the Product object ID.
    # 
    # + productId - Product ID
    # + fields - Fields to retireve
    # + return - JSON result if successful or else an sfdc:Error
    @display {label: "Get product by ID"}
    isolated remote function getProductById(@display {label: "Product ID"} string productId,
                                            @display {label: "Fields to retrieve"} string... fields) returns
                                            @tainted @display {label: "Result"} json|Error {
        json res = check self->getRecordById(PRODUCT, productId, ...fields);
        return res;
    }

    # Creates new Product object record.
    # 
    # + productRecord - JSON product record
    # + return - Product ID if successful or else an sfdc:Error
    @display {label: "Create product"}
    isolated remote function createProduct(@display {label: "Product record"} json productRecord) returns
                                           @tainted @display {label: "Product ID"} string|Error {
        return self->createRecord(PRODUCT, productRecord);
    }

    # Deletes existing product's records.
    # 
    # + productId - Product ID
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Delete product"}
    isolated remote function deleteProduct(@display {label: "Product ID"} string productId) returns
                                           @tainted @display {label: "Result"} boolean|Error {
        return self->deleteRecord(PRODUCT, productId);
    }

    # Updates existing Product object record.
    # 
    # + productId - Product ID
    # + productRecord - JSON product record
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Update product"}
    isolated remote function updateProduct(@display {label: "Product ID"} string productId,
                                           @display {label: "Product record"} json productRecord) returns
                                           @tainted @display {label: "Result"} boolean|Error {
        return self->updateRecord(PRODUCT, productId, productRecord);
    }

    private isolated function appendQueryParams(string[] fields) returns string {
        string appended = "?fields=";
        foreach string item in fields {
            appended = appended.concat(item.trim(), ",");
        }
        appended = appended.substring(0, appended.length() - 1);
        return appended;
    }

    //Query
    # Executes the specified SOQL query.
    # 
    # + receivedQuery - Sent SOQL query
    # + return - `SoqlResult` record if successful. Else, the occurred `Error`.
    @display {label: "Get query result"}
    isolated remote function getQueryResult(@display {label: "SOQL query"} string receivedQuery) returns
                                            @tainted @display {label: "SOQL Result"} SoqlResult|Error {
        string path = prepareQueryUrl([API_BASE_PATH, QUERY], [Q], [receivedQuery]);
        json res = check self->getRecord(path);
        return toSoqlResult(res);
    }

    # If the query results are too large, retrieve the next batch of results using the nextRecordUrl.
    # 
    # + nextRecordsUrl - URL to get the next query results
    # + return - `SoqlResult` record if successful. Else, the occurred `Error`.
    @display {label: "Get next query result"}
    isolated remote function getNextQueryResult(@display {label: "Next records URL"} string nextRecordsUrl) returns
                                                @tainted @display {label: "SOQL result"} SoqlResult|Error {
        json res = check self->getRecord(nextRecordsUrl);
        return toSoqlResult(res);
    }

    //Search
    # Executes the specified SOSL search.
    # 
    # + searchString - Sent SOSL search query
    # + return - `SoslResult` record if successful. Else, the occurred `Error`.
    @display {label: "SOSL Search"}
    isolated remote function searchSOSLString(@display {label: "SOSL search query"} string searchString) returns
                                              @tainted @display {label: "SOSL result"} SoslResult|Error {
        string path = prepareQueryUrl([API_BASE_PATH, SEARCH], [Q], [searchString]);
        json res = check self->getRecord(path);
        return toSoslResult(res);
    }

    # Lists summary details about each REST API version available.
    # 
    # + return - List of `Version` if successful. Else, the occured Error.
    @display {label: "Get available API versions"}
    isolated remote function getAvailableApiVersions() returns @tainted @display {label: "Versions"} Version[]|Error {
        string path = prepareUrl([BASE_PATH]);
        json res = check self->getRecord(path);
        return toVersions(res);
    }

    # Lists the resources available for the specified API version.
    # 
    # + apiVersion - API version (v37)
    # + return - `Resources` as map of strings if successful. Else, the occurred `Error`.
    @display {label: "Get resources by API version"}
    isolated remote function getResourcesByApiVersion(@display {label: "API version"} string apiVersion) returns
                                                      @tainted @display {label: "Resources"} map<string>|Error {
        string path = prepareUrl([BASE_PATH, apiVersion]);
        json res = check self->getRecord(path);
        return toMapOfStrings(res);
    }

    # Lists the Limits information for your organization.
    # 
    # + return - `OrganizationLimits` as map of `Limit` if successful. Else, the occurred `Error`.
    @display {label: "Get organization limits"}
    isolated remote function getOrganizationLimits() returns @tainted @display {label: "Organization limits"}
                                                  map<Limit>|Error {
        string path = prepareUrl([API_BASE_PATH, LIMITS]);
        json res = check self->getRecord(path);
        return toMapOfLimits(res);
    }


    // ******************************************* Bulk Operations *****************************************************
    # Create a bulk job.
    #
    # + operation - type of operation like insert, delete, etc.
    # + sobj - kind of sobject 
    # + contentType - content type of the job 
    # + extIdFieldName - field name of the external ID incase of an Upsert operation
    # + return - returns job object or error
    @display {label: "Create job"}
    isolated remote function creatJob(@display {label: "Operation"} OPERATION operation, 
                                      @display {label: "SObject"} string sobj, 
                                      @display {label: "Content type"} JOBTYPE contentType,
                                      @display {label: "External ID field name"} string extIdFieldName = "") returns
                                      @tainted @display {label: "Bulk job"} error|BulkJob {
        json jobPayload = {
            "operation": operation,
            "object": sobj,
            "contentType": contentType
        };
        if (UPSERT == operation) {
            if (extIdFieldName.length() > 0) {
                json extField = {"externalIdFieldName": extIdFieldName};
                jobPayload = check jobPayload.mergeJson(extField);
            } else {
                return error("External ID Field Name Required for UPSERT Operation!");
            }
        }
        map<string> headerMap = check getBulkApiHeaders(self.clientHandler);
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB]);
        http:Response|error response = self.salesforceClient->post(path, jobPayload, headers = headerMap);
        json|Error jobResponse = checkJsonPayloadAndSetErrors(response);
        if (jobResponse is json) {
            json|error jobResponseId = jobResponse.id;
            if (jobResponseId is json) {
                BulkJob bulkJob = {
                    jobId: jobResponseId.toString(),
                    jobDataType: contentType,
                    operation: operation
                };
                return bulkJob;
            } else {
                return jobResponseId;
            }
        } else {
            return jobResponse;
        }
    }

    # Get information about a job.
    #
    # + bulkJob - job object of which the info is required 
    # + return - job information record or error
    @display {label: "Get job information"}
    isolated remote function getJobInfo(@display {label: "Bulk job"} BulkJob bulkJob) returns
                                        @tainted @display {label: "Job information"} error|JobInfo {
        string jobId = bulkJob.jobId;
        JOBTYPE jobDataType = bulkJob.jobDataType;
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, jobId]);
        map<string> headerMap = check getBulkApiHeaders(self.clientHandler);
        http:Response|error response = self.salesforceClient->get(path, headerMap);
        if (JSON == jobDataType) {
            json|Error jobResponse = checkJsonPayloadAndSetErrors(response);
            if (jobResponse is json) {
                JobInfo jobInfo = check jobResponse.cloneWithType(JobInfo);
                return jobInfo;
            } else {
                return jobResponse;
            }
        } else {
            xml|Error jobResponse = checkXmlPayloadAndSetErrors(response);
            if (jobResponse is xml) {
                JobInfo jobInfo = check createJobRecordFromXml(jobResponse);
                return jobInfo;
            } else {
                return jobResponse;
            }
        }
    }

    # Close a job.
    #
    # + bulkJob - job to be closed 
    # + return - job info after the state change of the job
    @display {label: "Close job"}
    remote function closeJob(@display {label: "Bulk job"} BulkJob bulkJob) returns
                             @tainted @display {label: "Job information"} error|JobInfo {
        string jobId = bulkJob.jobId;
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, jobId]);
        map<string> headerMap = check getBulkApiHeaders(self.clientHandler);
        http:Response|error response = self.salesforceClient->post(path, JSON_STATE_CLOSED_PAYLOAD, headers = headerMap);
        json|Error jobResponse = checkJsonPayloadAndSetErrors(response);
        if (jobResponse is json) {
            JobInfo jobInfo = check jobResponse.cloneWithType(JobInfo);
            return jobInfo;
        } else {
            return jobResponse;
        }
    }

    # Abort a job.
    #
    # + bulkJob - job to be aborted 
    # + return - job info after the state change of the job
    @display {label: "Abort job"}
    remote function abortJob(@display {label: "Bulk job"} BulkJob bulkJob) returns
                             @tainted @display {label: "Job information"} error|JobInfo {
        string jobId = bulkJob.jobId;
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, jobId]);
        map<string> headerMap = check getBulkApiHeaders(self.clientHandler);
        http:Response|error response = self.salesforceClient->post(path, JSON_STATE_CLOSED_PAYLOAD, headers = headerMap);
        json|Error jobResponse = checkJsonPayloadAndSetErrors(response);
        if (jobResponse is json) {
            JobInfo jobInfo = check jobResponse.cloneWithType(JobInfo);
            return jobInfo;
        } else {
            return jobResponse;
        }
    }

    # Add batch to the job.
    #
    # + bulkJob - Bulk job  
    # + content - batch content 
    # + return - batch info or error
    @display {label: "Add batch to job"}
    isolated remote function addBatch(@display {label: "Bulk job"} BulkJob bulkJob,
                                      @display {label: "Batch content"} json|string|xml|io:ReadableByteChannel content)
                                      returns @tainted @display {label: "Batch information"} error|BatchInfo {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, bulkJob.jobId, BATCH]);
        // https://github.com/ballerina-platform/ballerina-lang/issues/26798
        string|json|xml payload;
        if (bulkJob.jobDataType == JSON) {
            if (content is io:ReadableByteChannel) {
                if (QUERY == bulkJob.operation) {
                    payload = check convertToString(content);
                } else {
                    payload = check convertToJson(content);
                }
            } else {
                payload = content;
            }
            map<string> headerMap = check getBulkApiHeaders(self.clientHandler, APP_JSON);
            http:Response|error response = self.salesforceClient->post(path, payload, headers = headerMap);
            json|Error batchResponse = checkJsonPayloadAndSetErrors(response);
            if (batchResponse is json) {
                BatchInfo binfo = check batchResponse.cloneWithType(BatchInfo);
                return binfo;
            } else {
                return batchResponse;
            }
        } else if (bulkJob.jobDataType == XML) {
            if (content is io:ReadableByteChannel) {
                if (QUERY == bulkJob.operation) {
                    payload = check convertToString(content);
                } else {
                    payload = check convertToXml(content);
                }
            } else {
                payload = content;
            }
            map<string> headerMap = check getBulkApiHeaders(self.clientHandler, APP_XML);
            http:Response|error response = self.salesforceClient->post(path, payload, headers = headerMap);
            xml|Error batchResponse = checkXmlPayloadAndSetErrors(response);
            if (batchResponse is xml) {
                BatchInfo binfo = check createBatchRecordFromXml(batchResponse);
                return binfo;
            } else {
                return batchResponse;
            }
        } else if (bulkJob.jobDataType == CSV) {

            if (content is io:ReadableByteChannel) {
                payload = check convertToString(content);
            } else {
                payload = content;
            }
            map<string> headerMap = check getBulkApiHeaders(self.clientHandler, TEXT_CSV);
            http:Response|error response = self.salesforceClient->post(path, payload, headers = headerMap);
            xml|Error batchResponse = checkXmlPayloadAndSetErrors(response);
            if (batchResponse is xml) {
                BatchInfo binfo = check createBatchRecordFromXml(batchResponse);
                return binfo;
            } else {
                return batchResponse;
            }
        } else {
            return error("Invalid Job Type!");
        }
    }

    # Get information about a batch.
    #
    # + bulkJob - Bulk job 
    # + batchId - ID of the batch of which info is required 
    # + return - batch info or error
    @display {label: "Get batch information"}
    isolated remote function getBatchInfo(@display {label: "Bulk job"} @tainted BulkJob bulkJob, 
                                          @display {label: "Batch ID"} string batchId) 
                                          returns @tainted @display {label: "Batch Information"} error|BatchInfo {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, bulkJob.jobId, BATCH, batchId]);
        map<string> headerMap = check getBulkApiHeaders(self.clientHandler);
        http:Response|error response = self.salesforceClient->get(path, headerMap);
        if (JSON == bulkJob.jobDataType) {
            json|Error batchResponse = checkJsonPayloadAndSetErrors(response);
            if (batchResponse is json) {
                BatchInfo binfo = check batchResponse.cloneWithType(BatchInfo);
                return binfo;
            } else {
                return batchResponse;
            }
        } else {
            xml|Error batchResponse = checkXmlPayloadAndSetErrors(response);
            if (batchResponse is xml) {
                BatchInfo binfo = check createBatchRecordFromXml(batchResponse);
                return binfo;
            } else {
                return batchResponse;
            }
        }
    }

    # Get all batches of the job.
    #
    # + bulkJob - Bulkjob
    # + return - list of batch infos
    @display {label: "Get all batches"}
    isolated remote function getAllBatches(@display {label: "Bulkjob"} @tainted BulkJob bulkJob) returns @tainted 
                                           @display {label: "List of batch information"} error|BatchInfo[] {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, bulkJob.jobId, BATCH]);
        http:Request req = new;
        map<string> headerMap = check getBulkApiHeaders(self.clientHandler);
        http:Response|error response = self.salesforceClient->get(path, headerMap);
        BatchInfo[] batchInfoList = [];
        if (JSON == bulkJob.jobDataType) {
            json batchResponse = check checkJsonPayloadAndSetErrors(response);
            json batchInfoRes = check batchResponse.batchInfo;
            json[] batchInfoArr = <json[]>batchInfoRes;
            foreach json batchInfo in batchInfoArr {
                BatchInfo batch = check batchInfo.cloneWithType(BatchInfo);
                batchInfoList[batchInfoList.length()] = batch;
            }
        } else {
            xml batchResponse = check checkXmlPayloadAndSetErrors(response);
            foreach var batchInfo in batchResponse/<*> {
                BatchInfo batch = check createBatchRecordFromXml(batchInfo);
                batchInfoList[batchInfoList.length()] = batch;
            }
        }
        return batchInfoList;
    }

    # Get the request payload of a batch.
    #
    # + bulkJob - Bulk job
    # + batchId - ID of the batch of which the request is required 
    # + return - batch content
    @display {label: "Get batch request payload"}
    isolated remote function getBatchRequest(@display {label: "Bulk job"} @tainted BulkJob bulkJob, 
                                             @display {label: "Batch ID"} string batchId) returns
                                             @tainted @display {label: "Batch content"} error|json|xml|string {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, bulkJob.jobId, BATCH, batchId, REQUEST]);
        map<string> headerMap = check getBulkApiHeaders(self.clientHandler);
        http:Response|error response = self.salesforceClient->get(path, headerMap);
        if (QUERY == bulkJob.operation) {
            return getQueryRequest(response, bulkJob.jobDataType);
        } else {
            match bulkJob.jobDataType {
                JSON => {
                    return checkJsonPayloadAndSetErrors(response);
                }
                XML => {
                    return checkXmlPayloadAndSetErrors(response);
                }
                CSV => {
                    return checkTextPayloadAndSetErrors(response);
                }
                _ => {
                    return error("Invalid Job Type!");
                }
            }
        }
    }

    # Get result of the records processed in a batch.
    #
    # + bulkJob - Bulk job  
    # + batchId - batch ID
    # + return - result list
    @display {label: "Get batch result"}
    isolated remote function getBatchResult(@display {label: "Bulk job"} @tainted BulkJob bulkJob, 
                                            @display {label: "Batch ID"} string batchId) returns
                                            @tainted @display {label: "Result"} error|json|xml|string|Result[] {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, bulkJob.jobId, BATCH, batchId, RESULT]);
        Result[] results = [];
        map<string> headerMap = check getBulkApiHeaders(self.clientHandler);
        http:Response|error response = self.salesforceClient->get(path, headerMap);
        match bulkJob.jobDataType {
            JSON => {
                json resultResponse = check checkJsonPayloadAndSetErrors(response);
                if (QUERY == bulkJob.operation) {
                    return getJsonQueryResult(<@untainted>resultResponse, path, <@untainted>self.salesforceClient, 
                        <@untainted>self.clientHandler);
                }
                return createBatchResultRecordFromJson(resultResponse);
            }
            XML => {
                xml resultResponse = check checkXmlPayloadAndSetErrors(response);
                if (QUERY == bulkJob.operation) {
                    return getXmlQueryResult(<@untainted>resultResponse, path, <@untainted>self.salesforceClient, 
                        <@untainted>self.clientHandler);
                }
                return createBatchResultRecordFromXml(resultResponse);
            }
            CSV => {
                if (QUERY == bulkJob.operation) {
                    xml resultResponse = check checkXmlPayloadAndSetErrors(response);
                    return getCsvQueryResult(<@untainted>resultResponse, path, <@untainted>self.salesforceClient, 
                        <@untainted>self.clientHandler);
                }
                string resultResponse = check checkTextPayloadAndSetErrors(response);
                return createBatchResultRecordFromCsv(resultResponse);
            }
            _ => {
                return error("Invalid Job Type!");
            }
        }
    }
}

# Salesforce client configuration.
# 
# + baseUrl - The Salesforce endpoint URL
# + clientConfig - OAuth2 direct token configuration
# + secureSocketConfig - HTTPS secure socket configuration
public type SalesforceConfiguration record {|
    string baseUrl;
    http:OAuth2RefreshTokenGrantConfig|http:BearerTokenConfig clientConfig;
    http:ClientSecureSocket secureSocketConfig?;
|};
