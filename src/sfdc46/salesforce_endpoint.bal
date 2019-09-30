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

import ballerina/http;
import ballerina/oauth2;

# Salesforce Client object.
# + salesforceClient - OAuth2 client endpoint
# + salesforceConfiguration - Salesforce Connector configuration
public type Client client object {
    http:Client salesforceClient;
    SalesforceConfiguration salesforceConfiguration;

    # Salesforce Connector endpoint initialization function.
    # + salesforceConfig - Salesforce Connector configuration
    public function __init(SalesforceConfiguration salesforceConfig) {
        self.salesforceConfiguration = salesforceConfig;
        // Create OAuth2 provider.
        oauth2:OutboundOAuth2Provider oauth2Provider = new(salesforceConfig.clientConfig);
        // Create bearer auth handler using created provider.
        http:BearerAuthHandler bearerHandler = new(oauth2Provider);

        http:ClientSecureSocket? socketConfig = salesforceConfig?.secureSocketConfig;
        
        // Create salesforce http client.
        if (socketConfig is http:ClientSecureSocket) {
            self.salesforceClient = new(salesforceConfig.baseUrl, {
                secureSocket: socketConfig,
                auth: {
                    authHandler: bearerHandler
                }
            });
        } else {
            self.salesforceClient = new(salesforceConfig.baseUrl, {
                auth: {
                    authHandler: bearerHandler
                }
            });
        }
    }

    # Create salesforce bulk API client.
    # + return - salesforce bulk client
    public remote function createSalesforceBulkClient() returns SalesforceBulkClient {
        SalesforceBulkClient salesforceBulkClient = new(self.salesforceConfiguration);
        return salesforceBulkClient;
    }

    # Lists summary details about each REST API version available.
    # + return - List of `Version` if successful else ConnectorError occured
    public remote function getAvailableApiVersions() returns @tainted Version[]|ConnectorError {
        string path = prepareUrl([BASE_PATH]);
        json res = check self->getRecord(path);
        return toVersions(res);
    }

    # Lists the resources available for the specified API version.
    # + apiVersion - API version (v37)
    # + return - `Resources` as map of strings if successful else ConnectorError occured
    public remote function getResourcesByApiVersion(string apiVersion) returns @tainted map<string>|ConnectorError {
        string path = prepareUrl([BASE_PATH, apiVersion]);
        json res = check self->getRecord(path);
        return toMapOfStrings(res);            
    }

    # Lists limits information for your organization.
    # + return - `OrganizationLimits` as map of `Limit` if successful else ConnectorError occured
    public remote function getOrganizationLimits() returns @tainted map<Limit>|ConnectorError {
        string path = prepareUrl([API_BASE_PATH, LIMITS]);
        json res = check self->getRecord(path);
        return toMapOfLimits(res);
    }

    //Query

    # Executes the specified SOQL query.
    # + receivedQuery - Sent SOQL query
    # + return - `SoqlResult` record if successful else ConnectorError occured
    public remote function getQueryResult(string receivedQuery) returns @tainted SoqlResult|ConnectorError {
        string path = prepareQueryUrl([API_BASE_PATH, QUERY], [Q], [receivedQuery]);
        json res = check self->getRecord(path);
        return toSoqlResult(res);
    }

    # If the query results are too large, retrieve the next batch of results using nextRecordUrl.
    # + nextRecordsUrl - URL to get next query results
    # + return - `SoqlResult` record if successful else ConnectorError occured
    public remote function getNextQueryResult(string nextRecordsUrl) returns @tainted SoqlResult|ConnectorError {
        json res = check self->getRecord(nextRecordsUrl);
        return toSoqlResult(res);
    }

    # Executes the specified SOQL query. Unlike the Query resource, QueryAll will return records that have been deleted 
    # because of a merge or delete. QueryAll will also return information about archived Task and Event records. 
    # + queryString - Sent SOQL query
    # + return - `SoqlResult` record if successful else ConnectorError occured
    public remote function getQueryAllResult(string queryString) returns @tainted SoqlResult|ConnectorError {
        string path = prepareQueryUrl([API_BASE_PATH, QUERYALL], [Q], [queryString]);
        json res = check self->getRecord(path);
        return toSoqlResult(res);
    }

    # Get feedback on how Salesforce will execute the query, report, or list view based on performance.
    # + queryReportOrListview - Sent query
    # + return - `SoqlResult` record if successful else ConnectorError occured
    public remote function explainQueryOrReportOrListview(string queryReportOrListview)
        returns @tainted ExecutionFeedback|ConnectorError {
        string path = prepareQueryUrl([API_BASE_PATH, QUERY], [EXPLAIN], [queryReportOrListview]);
        json res = check self->getRecord(path);
        return toExecutionFeedback(res);        
    }

    //Search

    # Executes the specified SOSL search.
    # + searchString - Sent SOSL search query
    # + return - `SoslResult` record if successful else ConnectorError occured
    public remote function searchSOSLString(string searchString) returns @tainted SoslResult|ConnectorError {
        string path = prepareQueryUrl([API_BASE_PATH, SEARCH], [Q], [searchString]);
        json res = check self->getRecord(path);
        return toSoslResult(res);
    }

    //Account

    # Accesses Account SObject records based on the Account object ID.
    # + accountId - Account ID
    # + return - `SObject` record if successful else ConnectorError occured
    public remote function getAccountById(string accountId) returns @tainted SObject|ConnectorError {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, ACCOUNT, accountId]);
        json res = check self->getRecord(path);
        return toSObject(res);
    }

    # Creates new Account object record.
    # + accountRecord - Account JSON record to be inserted
    # + return - If successful return account ID, else ConnectorError occured
    public remote function createAccount(json accountRecord) returns @tainted string|ConnectorError {
        return self->createRecord(ACCOUNT, accountRecord);
    }

    # Deletes existing Account's records.
    # + accountId - Account ID
    # + return - true if successful false otherwise, or ConnectorError occured
    public remote function deleteAccount(string accountId) returns @tainted boolean|ConnectorError {
        return self->deleteRecord(ACCOUNT, accountId);
    }

    # Updates existing Account object record.
    # + accountId - Account ID
    # + accountRecord - account record json payload
    # + return - true if successful, false otherwise or ConnectorError occured
    public remote function updateAccount(string accountId, json accountRecord)
    returns @tainted boolean|ConnectorError {
        return self->updateRecord(ACCOUNT, accountId, accountRecord);
    }

    //Lead

    # Accesses Lead SObject records based on the Lead object ID.
    # + leadId - Lead ID
    # + return - `SObject` record if successful else ConnectorError occured
    public remote function getLeadById(string leadId) returns @tainted SObject|ConnectorError {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, LEAD, leadId]);
        json res = check self->getRecord(path);
        return toSObject(res);
    }
    # Creates new Lead object record.
    # + leadRecord - Lead JSON record to be inserted
    # + return - string lead ID result if successful else ConnectorError occured
    public remote function createLead(json leadRecord) returns @tainted string|ConnectorError {
        return self->createRecord(LEAD, leadRecord);
    }

    # Deletes existing Lead's records.
    # + leadId - Lead ID
    # + return - true  if successful, flase otherwise or ConnectorError occured
    public remote function deleteLead(string leadId) returns @tainted boolean|ConnectorError {
        return self->deleteRecord(LEAD, leadId);
    }

    # Updates existing Lead object record.
    # + leadId - Lead ID
    # + leadRecord - Lead JSON record
    # + return - `json` result if successful else ConnectorError occured
    public remote function updateLead(string leadId, json leadRecord) returns @tainted boolean|ConnectorError {
        return self->updateRecord(LEAD, leadId, leadRecord);
    }

    //Contact

    # Accesses Contacts SObject records based on the Contact object ID.
    # + contactId - Contact ID
    # + return - `SObject` record if successful else ConnectorError occured
    public remote function getContactById(string contactId) returns @tainted SObject|ConnectorError {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, CONTACT, contactId]);
        json res = check self->getRecord(path);
        return toSObject(res);
    }

    # Creates new Contact object record.
    # + contactRecord - JSON contact record
    # + return - string ID if successful else ConnectorError occured
    public remote function createContact(json contactRecord) returns @tainted string|ConnectorError {
        return self->createRecord(CONTACT, contactRecord);
    }

    # Deletes existing Contact's records.
    # + contactId - Contact ID
    # + return - true if successful else false, or ConnectorError occured
    public remote function deleteContact(string contactId) returns @tainted boolean|ConnectorError {
        return self->deleteRecord(CONTACT, contactId);
    }

    # Updates existing Contact object record.
    # + contactId - Contact ID
    # + contactRecord - JSON contact record
    # + return - true if successful else false or ConnectorError occured
    public remote function updateContact(string contactId, json contactRecord) returns @tainted boolean|ConnectorError {
        return self->updateRecord(CONTACT, contactId, contactRecord);
    }

    //Opportunity

    # Accesses Opportunities SObject records based on the Opportunity object ID.
    # + opportunityId - Opportunity ID
    # + return - `SObject` record if successful else ConnectorError occured
    public remote function getOpportunityById(string opportunityId) returns @tainted SObject|ConnectorError {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, OPPORTUNITY, opportunityId]);
        json res = check self->getRecord(path);
        return toSObject(res);
    }

    # Creates new Opportunity object record.
    # + opportunityRecord - JSON opportunity record
    # + return - Opportunity ID if successful else ConnectorError occured
    public remote function createOpportunity(json opportunityRecord) returns @tainted string|ConnectorError {
        return self->createRecord(OPPORTUNITY, opportunityRecord);
    }

    # Deletes existing Opportunity's records.
    # + opportunityId - Opportunity ID
    # + return - true if successful else false or ConnectorError occured
    public remote function deleteOpportunity(string opportunityId) returns @tainted boolean|ConnectorError {
        return self->deleteRecord(OPPORTUNITY, opportunityId);
    }

    # Updates existing Opportunity object record.
    # + opportunityId - Opportunity ID
    # + opportunityRecord - opportunity json payload
    # + return - true if successful else false or ConnectorError occured
    public remote function updateOpportunity(string opportunityId, json opportunityRecord)
    returns @tainted boolean|ConnectorError {
        return self->updateRecord(OPPORTUNITY, opportunityId, opportunityRecord);
    }

    //Product

    # Accesses Products SObject records based on the Product object ID.
    # + productId - Product ID
    # + return - `SObject` record if successful else ConnectorError occured
    public remote function getProductById(string productId) returns @tainted SObject|ConnectorError {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, PRODUCT, productId]);
        json res = check self->getRecord(path);
        return toSObject(res);
    }

    # Creates new Product object record.
    # + productRecord - JSON product record
    # + return - Product ID if successful else ConnectorError occured
    public remote function createProduct(json productRecord) returns @tainted string|ConnectorError {
        return self->createRecord(PRODUCT, productRecord);
    }

    # Deletes existing product's records.
    # + productId - Product ID
    # + return - true if successful else false or ConnectorError occured
    public remote function deleteProduct(string productId) returns @tainted boolean|ConnectorError {
        return self->deleteRecord(PRODUCT, productId);
    }

    # Updates existing Product object record.
    # + productId - Product ID
    # + productRecord - JSON product record
    # + return - `json` result if successful else ConnectorError occured
    public remote function updateProduct(string productId, json productRecord) returns @tainted boolean|ConnectorError {
        return self->updateRecord(PRODUCT, productId, productRecord);
    }

    //Records

    # Retrieve field values from a standard object record for a specified SObject ID.
    # + sObjectName - SObject name value
    # + id - SObject id
    # + fields - Relevant fields
    # + return - `SObject` record if successful else ConnectorError occured
    public remote function getFieldValuesFromSObjectRecord(string sObjectName, string id, string fields)
        returns @tainted SObject|ConnectorError {
        string prefixPath = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        json res = check self->getRecord(prefixPath + QUESTION_MARK + FIELDS + EQUAL_SIGN + fields);
        return toSObject(res);
    }

    # Retrieve field values from an external object record using Salesforce ID or External ID.
    # + externalObjectName - External SObject name value
    # + id - External SObject id
    # + fields - Relevant fields
    # + return - `SObject` record if successful else ConnectorError occured
    public remote function getFieldValuesFromExternalObjectRecord(string externalObjectName, string id, string fields)
        returns @tainted SObject|ConnectorError {
        string prefixPath = prepareUrl([API_BASE_PATH, SOBJECTS, externalObjectName, id]);
        json res = check self->getRecord(prefixPath + QUESTION_MARK + FIELDS + EQUAL_SIGN + fields);
        return toSObject(res);
    }

    # Allows to create multiple records.
    # + sObjectName - SObject name value
    # + records - JSON records
    # + return - `json` result if successful else ConnectorError occured
    public remote function createMultipleRecords(string sObjectName, json records) 
        returns @tainted SObjectTreeResponse|ConnectorError {
        http:Request req = new;
        string path = string `${API_BASE_PATH}/${MULTIPLE_RECORDS}/${sObjectName}`;
        req.setJsonPayload(records);

        http:Response|error response = self.salesforceClient->post(path, req);
        json res = check checkAndSetErrors(response);
        return toSObjectTreeResponse(res);
    }

    # Accesses records based on the value of a specified external ID field.
    # + sObjectName - SObject name value
    # + fieldName - Relevant field name
    # + fieldValue - Relevant field value
    # + return - `SObject` record if successful else ConnectorError occured
    public remote function getRecordByExternalId(string sObjectName, string fieldName, string fieldValue)
        returns @tainted SObject|ConnectorError {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, fieldName, fieldValue]);
        json res = check self->getRecord(path);
        return toSObject(res);
    }

    # Creates new records or updates existing records (upserts records) based on the value of a specified
    # external ID field.
    # + sObjectName - SObject name value
    # + fieldId - Field id
    # + fieldValue - Relevant field value
    # + recordPayload - JSON record
    # + return - `SObjectResult` record if successful else ConnectorError occured
    public remote function upsertSObjectByExternalId(string sObjectName, string fieldId, string fieldValue,
        json recordPayload) returns @tainted SObjectResult|ConnectorError {
        http:Request req = new;
        string path = string `${API_BASE_PATH}/${SOBJECTS}/${sObjectName}/${fieldId}/${fieldValue}`;
        req.setJsonPayload(recordPayload);

        http:Response|error response = self.salesforceClient->patch(path, req);
        json res = check checkAndSetErrors(response, true);
        return toSObjectResult(res);
    }

    # Retrieves the list of individual records that have been deleted within the given timespan for the specified 
    # object.
    # + sObjectName - SObject name value
    # + startTime - Start time relevant to records
    # + endTime - End time relevant to records
    # + return - `DeletedRecordsResponse` record if successful else ConnectorError occured
    public remote function getDeletedRecords(string sObjectName, string startTime, string endTime)
        returns @tainted DeletedRecordsInfo|ConnectorError {
        string path = prepareQueryUrl([API_BASE_PATH, SOBJECTS, sObjectName, DELETED], [START, END], 
            [startTime, endTime]);
        json res = check self->getRecord(path);
        return toDeletedRecordsInfo(res);
    }

    # Retrieves the list of individual records that have been updated (added or changed) within the given timespan for
    # the specified object.
    # + sObjectName - SObject name value
    # + startTime - Start time relevant to records
    # + endTime - End time relevant to records
    # + return - `UpdatedRecordsInfo` record if successful else ConnectorError occured
    public remote function getUpdatedRecords(string sObjectName, string startTime, string endTime)
        returns @tainted UpdatedRecordsInfo|ConnectorError {
        string path = prepareQueryUrl([API_BASE_PATH, SOBJECTS, sObjectName, UPDATED], [START, END], [startTime, endTime]);
        json res = check self->getRecord(path);
        return toUpdatedRecordsInfo(res);
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
};

# Salesforce client configuration.
# + baseUrl - The Salesforce endpoint URL
# + clientConfig - OAuth2 direct token configuration
# + secureSocketConfig - HTTPS secure socket configuration
public type SalesforceConfiguration record {
    string baseUrl;
    oauth2:DirectTokenConfig clientConfig;
    http:ClientSecureSocket secureSocketConfig?;
};
