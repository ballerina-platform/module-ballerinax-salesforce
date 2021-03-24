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
import ballerina/io;

# The Salesforce Client object.
# + salesforceClient - OAuth2 client endpoint
# + salesforceConfiguration - Salesforce Connector configuration
# + authHandler - SalesforceAuthHandler class object 
@display {label: "Salesforce Client", iconPath: "SalesforceLogo.png"}
public client class Client {

    http:Client salesforceClient;
    SalesforceConfiguration salesforceConfiguration;
    SalesforceAuthHandler authHandler;

    # Salesforce Connector endpoint initialization function.
    # + salesforceConfig - Salesforce Connector configuration
    public function init(SalesforceConfiguration salesforceConfig) returns error? {

        self.salesforceConfiguration = salesforceConfig;

        http:ClientSecureSocket? socketConfig = salesforceConfig?.secureSocketConfig;
        self.authHandler = new (salesforceConfig.clientConfig);
        // Create an HTTP client.
        if (socketConfig is http:ClientSecureSocket) {
            self.salesforceClient = check new (salesforceConfig.baseUrl, {
                auth: salesforceConfig.clientConfig,
                secureSocket: socketConfig
            });
        } else {
            self.salesforceClient = check new (salesforceConfig.baseUrl, {
                auth: salesforceConfig.clientConfig
            });
        }
    }

    //Describe SObjects

    # Lists the available objects and their metadata for your organization and available to the logged-in user.
    # + return - `OrgMetadata` record if successful else Error occured
    @display {label: "Get available objects"}
    remote function describeAvailableObjects() returns @tainted @display {label: "Organization metadata"} 
            OrgMetadata|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS]);
        json res = check self->getRecord(path);
        return toOrgMetadata(res);
    }

    # Describes the individual metadata for the specified object.
    # + sobjectName - sobject name
    # + return - `SObjectBasicInfo` record if successful else Error occured
    @display {label: "Get SObject basic information"}
    remote function getSObjectBasicInfo(@display {label: "SObject name"} string sobjectName) returns @tainted 
                                        @display {label: "SObject basic information"} SObjectBasicInfo|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName]);
        json res = check self->getRecord(path);
        return toSObjectBasicInfo(res);
    }

    # Completely describes the individual metadata at all levels for the specified object. Can be used to retrieve
    # the fields, URLs, and child relationships.
    # + sObjectName - SObject name value
    # + return - `SObjectMetaData` record if successful else Error occured
    @display {label: "Get All information about SObject"}
    remote function describeSObject(@display {label: "SObject name"} string sObjectName) 
                                    returns @tainted @display {label: "SObject metadata"} SObjectMetaData|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DESCRIBE]);
        json res = check self->getRecord(path);
        return toSObjectMetaData(res);
    }

    # Query for actions displayed in the UI, given a user, a context, device format, and a record ID.
    # + return - `SObjectBasicInfo` record if successful else Error occured
    @display {label: "Get SObject platform action"}
    remote function sObjectPlatformAction() returns @tainted @display {label: "SObject basic information"} 
            SObjectBasicInfo|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, PLATFORM_ACTION]);
        json res = check self->getRecord(path);
        return toSObjectBasicInfo(res);
    }

    //Basic CRUD

    # Accesses records based on the specified object ID, can be used with external objects.
    # + path - Resource path
    # + return - `json` result if successful else Error occured
    @display {label: "Get record"}
    remote function getRecord(@display {label: "Resource path"} string path) 
                              returns @tainted @display {label: "Result"} json|Error {
        http:Response|http:PayloadType|error response = self.salesforceClient->get(path);
        return checkAndSetErrors(response);
    }

    # Create records based on relevant object type sent with json record.
    # + sObjectName - SObject name value
    # + recordPayload - JSON record to be inserted
    # + return - created entity ID if successful else Error occured
    @display {label: "Create record"}
    remote function createRecord(@display {label: "SObject name"} string sObjectName, 
                                 @display {label: "Record payload"} json recordPayload) 
                                 returns @tainted @display {label: "Created entity ID"} string|Error {
        http:Request req = new;
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
        req.setJsonPayload(recordPayload);

        var response = self.salesforceClient->post(path, req);

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
    # + sObjectName - SObject name value
    # + id - SObject id
    # + recordPayload - JSON record to be updated
    # + return - true if successful else false or Error occured
    @display {label: "Update record"}
    remote function updateRecord(@display {label: "SObject name"} string sObjectName, 
                                 @display {label: "SObject ID"} string id, 
                                 @display {label: "Record payload"} json recordPayload) 
                                 returns @tainted @display {label: "Result"} boolean|Error {
        http:Request req = new;
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        req.setJsonPayload(recordPayload);

        var response = self.salesforceClient->patch(path, req);

        json|Error result = checkAndSetErrors(response, false);

        if (result is json) {
            return true;
        } else {
            return result;
        }
    }

    # Delete existing records based on relevant object id.
    # + sObjectName - SObject name value
    # + id - SObject id
    # + return - true if successful else false or Error occured
    @display {label: "Delete record"}
    remote function deleteRecord(@display {label: "SObject name"} string sObjectName, 
                                 @display {label: "SObject ID"} string id) 
                                 returns @tainted @display {label: "Result"} boolean|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        var response = self.salesforceClient->delete(path, ());

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
    remote function getRecordById(@display {label: "SObject name"} string sobject, 
                                  @display {label: "SObject ID"} string id, 
                                  @display {label: "Fields to retrieve"} string... fields) 
                                  returns @tainted @display {label: "Result"} json|Error {
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
    remote function getRecordByExtId(@display {label: "SObject name"} string sobject, 
                                     @display {label: "External ID field name"} string extIdField, 
                                     @display {label: "External ID"} string extId, 
                                     @display {label: "Fields to retrieve"} string... fields) 
                                     returns @tainted @display {label: "Result"} json|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobject, extIdField, extId]);
        if (fields.length() > 0) {
            path = path.concat(self.appendQueryParams(fields));
        }
        json response = check self->getRecord(path);
        return response;
    }

    //Account

    # Accesses Account SObject records based on the Account object ID.
    # + accountId - Account ID
    # + fields - Fields to retireve
    # + return - JSON response if successful or else an sfdc:Error
    @display {label: "Get account by ID"}
    remote function getAccountById(@display {label: "Account ID"} string accountId, 
                                   @display {label: "Fields to retrieve"} string... fields) 
                                   returns @tainted @display {label: "Result"} json|Error {
        json res = check self->getRecordById(ACCOUNT, accountId, ...fields);
        return res;
    }

    # Creates new Account object record.
    # + accountRecord - Account JSON record to be inserted
    # + return - Account ID if successful or else an sfdc:Error
    @display {label: "Create account"}
    remote function createAccount(@display {label: "Account record"} json accountRecord) 
                                  returns @tainted @display {label: "Account ID"} string|Error {
        return self->createRecord(ACCOUNT, accountRecord);
    }

    # Deletes existing Account's records.
    # + accountId - Account ID
    # + return - `true` if successful `false` otherwise, or an sfdc:Error in case of an error
    @display {label: "Delete account"}
    remote function deleteAccount(@display {label: "Account ID"} string accountId) 
                                  returns @tainted @display {label: "Result"} boolean|Error {
        return self->deleteRecord(ACCOUNT, accountId);
    }

    # Updates existing Account object record.
    # + accountId - Account ID
    # + accountRecord - account record json payload
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Update account"}
    remote function updateAccount(@display {label: "Account ID"} string accountId, 
                                  @display {label: "Account record"} json accountRecord) 
                                  returns @tainted @display {label: "Result"} boolean|Error {
        return self->updateRecord(ACCOUNT, accountId, accountRecord);
    }

    //Lead

    # Accesses Lead SObject records based on the Lead object ID.
    # + leadId - Lead ID
    # + fields - Fields to retireve
    # + return - JSON response if successful or else an sfdc:Error
    @display {label: "Get lead by ID"}
    remote function getLeadById(@display {label: "Lead ID"} string leadId, 
                                @display {label: "Fields to retrieve"} string... fields) 
                                returns @tainted @display {label: "Result"} json|Error {
        json res = check self->getRecordById(LEAD, leadId, ...fields);
        return res;
    }

    # Creates new Lead object record.
    # + leadRecord - Lead JSON record to be inserted
    # + return - Lead ID if successful or else an sfdc:Error
    @display {label: "Create lead"}
    remote function createLead(@display {label: "Lead record"} json leadRecord) 
                               returns @tainted @display {label: "Lead ID"} string|Error {
        return self->createRecord(LEAD, leadRecord);
    }

    # Deletes existing Lead's records.
    # + leadId - Lead ID
    # + return - `true`  if successful, `false` otherwise or an sfdc:Error incase of an error
    @display {label: "Delete lead"}
    remote function deleteLead(@display {label: "Lead ID"} string leadId) 
                               returns @tainted @display {label: "Result"} boolean|Error {
        return self->deleteRecord(LEAD, leadId);
    }

    # Updates existing Lead object record.
    # + leadId - Lead ID
    # + leadRecord - Lead JSON record
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Update lead"}
    remote function updateLead(@display {label: "Lead ID"} string leadId, 
                               @display {label: "Lead record"} json leadRecord) 
                               returns @tainted @display {label: "Result"} boolean|Error {
        return self->updateRecord(LEAD, leadId, leadRecord);
    }

    //Contact

    # Accesses Contacts SObject records based on the Contact object ID.
    # + contactId - Contact ID
    # + fields - Fields to retireve
    # + return - JSON result if successful or else an sfdc:Error
    @display {label: "Get contact by ID"}
    remote function getContactById(@display {label: "Contact ID"} string contactId, 
                                   @display {label: "Fields to retrieve"} string... fields) 
                                   returns @tainted @display {label: "Result"} json|Error {
        json res = check self->getRecordById(CONTACT, contactId, ...fields);
        return res;
    }

    # Creates new Contact object record.
    # + contactRecord - JSON contact record
    # + return - Contact ID if successful or else an sfdc:Error
    @display {label: "Create contact"}
    remote function createContact(@display {label: "Contact record"} json contactRecord) 
                                  returns @tainted @display {label: "Contact ID"} string|Error {
        return self->createRecord(CONTACT, contactRecord);
    }

    # Deletes existing Contact's records.
    # + contactId - Contact ID
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Delete contact"}
    remote function deleteContact(@display {label: "Contact ID"} string contactId) 
                                  returns @tainted @display {label: "Result"} boolean|Error {
        return self->deleteRecord(CONTACT, contactId);
    }

    # Updates existing Contact object record.
    # + contactId - Contact ID
    # + contactRecord - JSON contact record
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Update contact"}
    remote function updateContact(@display {label: "Contact ID"} string contactId, 
                                  @display {label: "Contact record"} json contactRecord) 
                                  returns @tainted @display {label: "Result"} boolean|Error {
        return self->updateRecord(CONTACT, contactId, contactRecord);
    }

    //Opportunity

    # Accesses Opportunities SObject records based on the Opportunity object ID.
    # + opportunityId - Opportunity ID
    # + fields - Fields to retireve
    # + return - JSON response if successful or else an sfdc:Error
    @display {label: "Get opportunity by ID"}
    remote function getOpportunityById(@display {label: "Opportunity ID"} string opportunityId, 
                                       @display {label: "Fields to retrieve"} string... fields) 
                                       returns @tainted @display {label: "Result"} json|Error {
        json res = check self->getRecordById(OPPORTUNITY, opportunityId, ...fields);
        return res;
    }

    # Creates new Opportunity object record.
    # + opportunityRecord - JSON opportunity record
    # + return - Opportunity ID if successful or else an sfdc:Error
    @display {label: "Create opportunity"}
    remote function createOpportunity(@display {label: "Opportunity record"} json opportunityRecord) 
                                      returns @tainted @display {label: "Opportunity ID"} string|Error {
        return self->createRecord(OPPORTUNITY, opportunityRecord);
    }

    # Deletes existing Opportunity's records.
    # + opportunityId - Opportunity ID
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Delete opportunity"}
    remote function deleteOpportunity(@display {label: "Opportunity ID"} string opportunityId) 
                                      returns @tainted @display {label: "Result"} boolean|Error {
        return self->deleteRecord(OPPORTUNITY, opportunityId);
    }

    # Updates existing Opportunity object record.
    # + opportunityId - Opportunity ID
    # + opportunityRecord - Opportunity json payload
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Update opportunity"}
    remote function updateOpportunity(@display {label: "Opportunity ID"} string opportunityId, 
                                      @display {label: "Opportunity Record"} json opportunityRecord) 
                                      returns @tainted @display {label: "Result"} boolean|Error {
        return self->updateRecord(OPPORTUNITY, opportunityId, opportunityRecord);
    }

    //Product

    # Accesses Products SObject records based on the Product object ID.
    # + productId - Product ID
    # + fields - Fields to retireve
    # + return - JSON result if successful or else an sfdc:Error
    @display {label: "Get product by ID"}
    remote function getProductById(@display {label: "Product ID"} string productId, 
                                   @display {label: "Fields to retrieve"} string... fields) 
                                   returns @tainted @display {label: "Result"} json|Error {
        json res = check self->getRecordById(PRODUCT, productId, ...fields);
        return res;
    }

    # Creates new Product object record.
    # + productRecord - JSON product record
    # + return - Product ID if successful or else an sfdc:Error
    @display {label: "Create product"}
    remote function createProduct(@display {label: "Product record"} json productRecord) 
                                  returns @tainted @display {label: "Product ID"} string|Error {
        return self->createRecord(PRODUCT, productRecord);
    }

    # Deletes existing product's records.
    # + productId - Product ID
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Delete product"}
    remote function deleteProduct(@display {label: "Product ID"} string productId) 
                                  returns @tainted @display {label: "Result"} boolean|Error {
        return self->deleteRecord(PRODUCT, productId);
    }

    # Updates existing Product object record.
    # + productId - Product ID
    # + productRecord - JSON product record
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Update product"}
    remote function updateProduct(@display {label: "Product ID"} string productId, 
                                  @display {label: "Product record"} json productRecord) 
                                  returns @tainted @display {label: "Result"} boolean|Error {
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
    # + receivedQuery - Sent SOQL query
    # + return - `SoqlResult` record if successful. Else, the occurred `Error`.
    @display {label: "Get query result"}
    remote function getQueryResult(@display {label: "SOQL query"} string receivedQuery) 
                                   returns @tainted @display {label: "SOQL Result"} SoqlResult|Error {
        string path = prepareQueryUrl([API_BASE_PATH, QUERY], [Q], [receivedQuery]);
        json res = check self->getRecord(path);
        return toSoqlResult(res);
    }

    # If the query results are too large, retrieve the next batch of results using the nextRecordUrl.
    # + nextRecordsUrl - URL to get the next query results
    # + return - `SoqlResult` record if successful. Else, the occurred `Error`.
    @display {label: "Get next query result"}
    remote function getNextQueryResult(@display {label: "Next records URL"} string nextRecordsUrl) 
                                       returns @tainted @display {label: "SOQL result"} SoqlResult|Error {
        json res = check self->getRecord(nextRecordsUrl);
        return toSoqlResult(res);
    }

    //Search

    # Executes the specified SOSL search.
    # + searchString - Sent SOSL search query
    # + return - `SoslResult` record if successful. Else, the occurred `Error`.
    @display {label: "SOSL Search"}
    remote function searchSOSLString(@display {label: "SOSL search query"} string searchString) 
                                     returns @tainted @display {label: "SOSL result"} SoslResult|Error {
        string path = prepareQueryUrl([API_BASE_PATH, SEARCH], [Q], [searchString]);
        json res = check self->getRecord(path);
        return toSoslResult(res);
    }

    # Lists summary details about each REST API version available.
    # + return - List of `Version` if successful. Else, the occured Error.
    @display {label: "Get available API versions"}
    remote function getAvailableApiVersions() returns @tainted @display {label: "Versions"} Version[]|Error {
        string path = prepareUrl([BASE_PATH]);
        json res = check self->getRecord(path);
        return toVersions(res);
    }

    # Lists the resources available for the specified API version.
    # + apiVersion - API version (v37)
    # + return - `Resources` as map of strings if successful. Else, the occurred `Error`.
    @display {label: "Get resources by API version"}
    remote function getResourcesByApiVersion(@display {label: "API version"} string apiVersion) 
                                             returns @tainted @display {label: "Resources"} map<string>|Error {
        string path = prepareUrl([BASE_PATH, apiVersion]);
        json res = check self->getRecord(path);
        return toMapOfStrings(res);
    }

    # Lists the Limits information for your organization.
    # + return - `OrganizationLimits` as map of `Limit` if successful. Else, the occurred `Error`.
    @display {label: "Get organization limits"}
    remote function getOrganizationLimits() returns @tainted @display {label: "Organization limits"} map<Limit>|Error {
        string path = prepareUrl([API_BASE_PATH, LIMITS]);
        json res = check self->getRecord(path);
        return toMapOfLimits(res);
    }

    # Create a bulk job.
    #
    # + operation - type of operation like insert, delete, etc.
    # + sobj - kind of sobject 
    # + contentType - content type of the job 
    # + extIdFieldName - field name of the external ID incase of an Upsert operation
    # + return - returns job object or error
    @display {label: "Create job"}
    remote function creatJob(@display {label: "Operation"} OPERATION operation, 
                             @display {label: "SObject"} string sobj, 
                             @display {label: "Content type"} JOBTYPE contentType, 
                             @display {label: "External ID field name"} string extIdFieldName = "") 
                             returns @tainted @display {label: "Bulk job"} error|BulkJob {
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
        http:Request req = new;
        http:ClientAuthError|http:Request authorizedReq = self.authHandler.enrich(req);
        if (authorizedReq is http:Request) {
            authorizedReq.setJsonPayload(jobPayload);
            string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB]);
            var response = self.salesforceClient->post(path, authorizedReq);
            json|Error jobResponse = checkJsonPayloadAndSetErrors(response);
            if (jobResponse is json) {
                json|error jobResponseId = jobResponse.id;
                if (jobResponseId is json) {
                    BulkJob bulkJob = {jobId: jobResponseId.toString(), jobDataType: contentType, operation: operation};
                    return bulkJob;
                } else {
                    return jobResponseId;
                }
            } else {
                return jobResponse;
            }
        } else {
            return authorizedReq;
        }

    }

    # Get information about a job.
    #
    # + bulkJob - job object of which the info is required 
    # + return - job information record or error
    @display {label: "Get job information"}
    remote function getJobInfo(@display {label: "Bulk job"} BulkJob bulkJob) 
                               returns @tainted @display {label: "Job information"} error|JobInfo {
        string jobId = bulkJob.jobId;
        JOBTYPE jobDataType = bulkJob.jobDataType;
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, jobId]);
        http:Request req = new;
        http:ClientAuthError|http:Request authorizedReq = self.authHandler.enrich(req);
        if (authorizedReq is http:Request) {
            var response = self.salesforceClient->get(path, authorizedReq);
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
        } else {
            return authorizedReq;
        }

    }

    # Close a job.
    #
    # + bulkJob - job to be closed 
    # + return - job info after the state change of the job
    @display {label: "Close job"}
    remote function closeJob(@display {label: "Bulk job"} BulkJob bulkJob) 
                             returns @tainted @display {label: "Job information"} error|JobInfo {
        string jobId = bulkJob.jobId;
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, jobId]);
        http:Request req = new;
        http:ClientAuthError|http:Request authorizedReq = self.authHandler.enrich(req);
        if (authorizedReq is http:Request) {
            authorizedReq.setJsonPayload(JSON_STATE_CLOSED_PAYLOAD);
            var response = self.salesforceClient->post(path, authorizedReq);
            json|Error jobResponse = checkJsonPayloadAndSetErrors(response);
            if (jobResponse is json) {
                JobInfo jobInfo = check jobResponse.cloneWithType(JobInfo);
                return jobInfo;
            } else {
                return jobResponse;
            }
        } else {
            return authorizedReq;
        }

    }

    # Abort a job.
    #
    # + bulkJob - job to be aborted 
    # + return - job info after the state change of the job
    @display {label: "Abort job"}
    remote function abortJob(@display {label: "Bulk job"} BulkJob bulkJob) 
                             returns @tainted @display {label: "Job information"} error|JobInfo {
        string jobId = bulkJob.jobId;
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, jobId]);
        http:Request req = new;
        http:ClientAuthError|http:Request authorizedReq = self.authHandler.enrich(req);
        if (authorizedReq is http:Request) {
            req.setJsonPayload(JSON_STATE_CLOSED_PAYLOAD);
            var response = self.salesforceClient->post(path, req);
            json|Error jobResponse = checkJsonPayloadAndSetErrors(response);
            if (jobResponse is json) {
                JobInfo jobInfo = check jobResponse.cloneWithType(JobInfo);
                return jobInfo;
            } else {
                return jobResponse;
            }
        } else {
            return authorizedReq;
        }
    }

    # Add batch to the job.
    #
    # + content - batch content 
    # + return - batch info or error
    @display {label: "Add batch to job"}
    remote function addBatch(@display {label: "Bulk job"} BulkJob bulkJob, 
                             @display {label: "Batch content"} json|string|xml|io:ReadableByteChannel content) 
                             returns @tainted @display {label: "Batch information"} error|BatchInfo {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, bulkJob.jobId, BATCH]);
        // https://github.com/ballerina-platform/ballerina-lang/issues/26798
        http:Request req = new;
        http:ClientAuthError|http:Request authorizedReq = self.authHandler.enrich(req);
        if (authorizedReq is http:Request) {
            if (bulkJob.jobDataType == JSON) {
                if (content is json) {
                    authorizedReq.setJsonPayload(content);
                }
                if (content is string) {
                    authorizedReq.setTextPayload(content);
                }
                if (content is io:ReadableByteChannel) {
                    if (QUERY == bulkJob.operation) {
                        string payload = check convertToString(content);
                        authorizedReq.setTextPayload(<@untainted>payload);
                    } else {
                        json payload = check convertToJson(content);
                        authorizedReq.setJsonPayload(<@untainted>payload);
                    }
                }
                authorizedReq.setHeader(CONTENT_TYPE, APP_JSON);
                var response = self.salesforceClient->post(path, authorizedReq);
                json|Error batchResponse = checkJsonPayloadAndSetErrors(response);
                if (batchResponse is json) {
                    BatchInfo binfo = check batchResponse.cloneWithType(BatchInfo);
                    return binfo;
                } else {
                    return batchResponse;
                }
            } else if (bulkJob.jobDataType == XML) {
                if (content is xml) {
                    authorizedReq.setXmlPayload(content);
                }
                if (content is string) {
                    authorizedReq.setTextPayload(content);
                }
                if (content is io:ReadableByteChannel) {
                    if (QUERY == bulkJob.operation) {
                        string payload = check convertToString(content);
                        authorizedReq.setTextPayload(<@untainted>payload);
                    } else {
                        xml payload = check convertToXml(content);
                        authorizedReq.setXmlPayload(<@untainted>payload);
                    }
                }
                authorizedReq.setHeader(CONTENT_TYPE, APP_XML);
                var response = self.salesforceClient->post(path, authorizedReq);
                xml|Error batchResponse = checkXmlPayloadAndSetErrors(response);
                if (batchResponse is xml) {
                    BatchInfo binfo = check createBatchRecordFromXml(batchResponse);
                    return binfo;
                } else {
                    return batchResponse;
                }
            } else if (bulkJob.jobDataType == CSV) {
                if (content is string) {
                    authorizedReq.setTextPayload(content);
                }
                if (content is io:ReadableByteChannel) {
                    string textcontent = check convertToString(content);
                    authorizedReq.setTextPayload(<@untainted>textcontent);
                }
                authorizedReq.setHeader(CONTENT_TYPE, TEXT_CSV);
                var response = self.salesforceClient->post(path, authorizedReq);
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
        } else {
            return authorizedReq;
        }

    }

    # Get information about a batch.
    #
    # + batchId - ID of the batch of which info is required 
    # + return - batch info or error
    @display {label: "Get batch information"}
    remote function getBatchInfo(@display {label: "Bulk job"} BulkJob bulkJob, 
                                 @display {label: "Batch ID"} string batchId) 
                                 returns @tainted @display {label: "Batch Information"} error|BatchInfo {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, bulkJob.jobId, BATCH, batchId]);
        http:Request req = new;
        http:ClientAuthError|http:Request authorizedReq = self.authHandler.enrich(req);
        if (authorizedReq is http:Request) {
            var response = self.salesforceClient->get(path, authorizedReq);
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
        } else {
            return authorizedReq;
        }

    }

    # Get all batches of the job.
    #
    # + return - list of batch infos
    @display {label: "Get all batches"}
    remote function getAllBatches(@display {label: "Bulkjob"} BulkJob bulkJob) 
                                  returns @tainted @display {label: "List of batch information"} error|BatchInfo[] {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, bulkJob.jobId, BATCH]);
        http:Request req = new;
        http:ClientAuthError|http:Request authorizedReq = self.authHandler.enrich(req);
        if (authorizedReq is http:Request) {
            var response = self.salesforceClient->get(path, authorizedReq);
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
        } else {
            return authorizedReq;
        }
    }

    # Get the request payload of a batch.
    #
    # + batchId - ID of the batch of which the request is required 
    # + return - batch content
    @display {label: "Get batch request payload"}
    remote function getBatchRequest(@display {label: "Bulk job"} BulkJob bulkJob, 
                                    @display {label: "Batch ID"} string batchId) 
                                    returns @tainted @display {label: "Batch content"} error|json|xml|string {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, bulkJob.jobId, BATCH, batchId, REQUEST]);
        http:Request req = new;
        http:ClientAuthError|http:Request authorizedReq = self.authHandler.enrich(req);
        if (authorizedReq is http:Request) {
            var response = self.salesforceClient->get(path, authorizedReq);
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
        } else {
            return authorizedReq;
        }

    }

    # Get result of the records processed in a batch.
    #
    # + batchId - batch ID
    # + return - result list
    @display {label: "Get batch result"}
    remote function getBatchResult(@display {label: "Bulk job"} BulkJob bulkJob, 
                                   @display {label: "Batch ID"} string batchId) 
                                   returns @tainted @display {label: "Result"} error|json|xml|string|Result[] {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, bulkJob.jobId, BATCH, batchId, RESULT]);
        Result[] results = [];
        http:Request req = new;
        http:ClientAuthError|http:Request authorizedReq = self.authHandler.enrich(req);
        if (authorizedReq is http:Request) {
            var response = self.salesforceClient->get(path, authorizedReq);
            match bulkJob.jobDataType {
                JSON => {
                    json resultResponse = check checkJsonPayloadAndSetErrors(response);
                    if (QUERY == bulkJob.operation) {
                        return getJsonQueryResult(<@untainted>resultResponse, path, <@untainted>self.salesforceClient, <@untainted>
                        self.authHandler);
                    }
                    return createBatchResultRecordFromJson(resultResponse);
                }
                XML => {
                    xml resultResponse = check checkXmlPayloadAndSetErrors(response);
                    if (QUERY == bulkJob.operation) {
                        return getXmlQueryResult(<@untainted>resultResponse, path, <@untainted>self.salesforceClient, <@untainted>
                        self.authHandler);
                    }
                    return createBatchResultRecordFromXml(resultResponse);
                }
                CSV => {
                    if (QUERY == bulkJob.operation) {
                        xml resultResponse = check checkXmlPayloadAndSetErrors(response);
                        return getCsvQueryResult(<@untainted>resultResponse, path, <@untainted>self.salesforceClient, <@untainted>
                        self.authHandler);
                    }
                    string resultResponse = check checkTextPayloadAndSetErrors(response);
                    return createBatchResultRecordFromCsv(resultResponse);
                }
                _ => {
                    return error("Invalid Job Type!");
                }
            }
        } else {
            return authorizedReq;
        }
    }
}

# Salesforce client configuration.
# + baseUrl - The Salesforce endpoint URL
# + clientConfig - OAuth2 direct token configuration
# + secureSocketConfig - HTTPS secure socket configuration
public type SalesforceConfiguration record {|
    string baseUrl;
    http:OAuth2DirectTokenConfig|http:BearerTokenConfig clientConfig;
    http:ClientSecureSocket secureSocketConfig?;
|};
