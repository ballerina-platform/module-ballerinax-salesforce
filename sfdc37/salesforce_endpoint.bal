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

import ballerina/http;

# Salesforce Client object.
# + salesforceClient - OAuth2 client endpoint
public type Client client object {
    http:Client salesforceClient;

    # Salesforce Connector endpoint initialization function.
    # + config - Salesforce Connector configuration
    public function __init(SalesforceConfiguration salesforceConfig) {
        self.salesforceClient = new(salesforceConfig.baseUrl, config = salesforceConfig.clientConfig);
    }

    # Lists summary details about each REST API version available.
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getAvailableApiVersions() returns json|SalesforceConnectorError;

    # Lists the resources available for the specified API version.
    # + apiVersion - API version (v37)
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getResourcesByApiVersion(string apiVersion) returns json|SalesforceConnectorError;

    # Lists limits information for your organization.
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getOrganizationLimits() returns json|SalesforceConnectorError;

    // Query
    # Executes the specified SOQL query.
    # + receivedQuery - Sent SOQL query
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getQueryResult(string receivedQuery) returns json|SalesforceConnectorError;

    # If the query results are too large, retrieve the next batch of results using nextRecordUrl.
    # + nextRecordsUrl - URL to get next query results
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getNextQueryResult(string nextRecordsUrl) returns json|SalesforceConnectorError;

    # Returns records that have been deleted because of a merge or delete, archived Task
    # and Event records.
    # + queryString - Sent SOQL query
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getAllQueries(string queryString) returns json|SalesforceConnectorError;

    # Get feedback on how Salesforce will execute the query, report, or list view based on performance.
    # + queryReportOrListview - Sent query
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function explainQueryOrReportOrListview(string queryReportOrListview)
    returns json|SalesforceConnectorError;

    //Search
    # Executes the specified SOSL search.
    # + searchString - Sent SOSL search query
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function searchSOSLString(string searchString) returns json|SalesforceConnectorError;

    //Account
    # Accesses Account SObject records based on the Account object ID.
    # + accountId - Account ID
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getAccountById(string accountId) returns json|SalesforceConnectorError;

    # Creates new Account object record.
    # + accountRecord - Account JSON record to be inserted
    # + return - If successful return account ID, else SalesforceConnectorError occured
    public remote function createAccount(json accountRecord) returns string|SalesforceConnectorError;

    # Deletes existing Account's records.
    # + accountId - Account ID
    # + return - true if successful false otherwise, or SalesforceConnectorError occured
    public remote function deleteAccount(string accountId) returns boolean|SalesforceConnectorError;

    # Updates existing Account object record.
    # + accountId - Account ID
    # + return - true if successful, false otherwise or SalesforceConnectorError occured
    public remote function updateAccount(string accountId, json accountRecord) returns boolean|SalesforceConnectorError;

    //Lead
    # Accesses Lead SObject records based on the Lead object ID.
    # + leadId - Lead ID
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getLeadById(string leadId) returns json|SalesforceConnectorError;

    # Creates new Lead object record.
    # + leadRecord - Lead JSON record to be inserted
    # + return - string lead ID result if successful else SalesforceConnectorError occured
    public remote function createLead(json leadRecord) returns string|SalesforceConnectorError;

    # Deletes existing Lead's records.
    # + leadId - Lead ID
    # + return - true  if successful, flase otherwise or SalesforceConnectorError occured
    public remote function deleteLead(string leadId) returns boolean|SalesforceConnectorError;

    # Updates existing Lead object record.
    # + leadId - Lead ID
    # + leadRecord - Lead JSON record
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function updateLead(string leadId, json leadRecord) returns boolean|SalesforceConnectorError;

    //Contact
    # Accesses Contacts SObject records based on the Contact object ID.
    # + contactId - Contact ID
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getContactById(string contactId) returns json|SalesforceConnectorError;

    # Creates new Contact object record.
    # + contactRecord - JSON contact record
    # + return - string ID if successful else SalesforceConnectorError occured
    public remote function createContact(json contactRecord) returns string|SalesforceConnectorError;

    # Deletes existing Contact's records.
    # + contactId - Contact ID
    # + return - true if successful else false, or SalesforceConnectorError occured
    public remote function deleteContact(string contactId) returns boolean|SalesforceConnectorError;

    # Updates existing Contact object record.
    # + contactId - Contact ID
    # + contactRecord - JSON contact record
    # + return - true if successful else false or SalesforceConnectorError occured
    public remote function updateContact(string contactId, json contactRecord) returns boolean|SalesforceConnectorError;

    //Opportunity
    # Accesses Opportunities SObject records based on the Opportunity object ID.
    # + opportunityId - Opportunity ID
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getOpportunityById(string opportunityId) returns json|SalesforceConnectorError;

    # Creates new Opportunity object record.
    # + opportunityRecord - JSON opportunity record
    # + return - Opportunity ID if successful else SalesforceConnectorError occured
    public remote function createOpportunity(json opportunityRecord) returns string|SalesforceConnectorError;

    # Deletes existing Opportunity's records.
    # + opportunityId - Opportunity ID
    # + return - true if successful else false or SalesforceConnectorError occured
    public remote function deleteOpportunity(string opportunityId) returns boolean|SalesforceConnectorError;

    # Updates existing Opportunity object record.
    # + opportunityId - Opportunity ID
    # + return - true if successful else false or SalesforceConnectorError occured
    public remote function updateOpportunity(string opportunityId, json opportunityRecord)
    returns boolean|SalesforceConnectorError;

    //Product
    # Accesses Products SObject records based on the Product object ID.
    # + productId - Product ID
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getProductById(string productId) returns json|SalesforceConnectorError;

    # Creates new Product object record.
    # + productRecord - JSON product record
    # + return - Product ID if successful else SalesforceConnectorError occured
    public remote function createProduct(json productRecord) returns string|SalesforceConnectorError;

    # Deletes existing product's records.
    # + productId - Product ID
    # + return - true if successful else false or SalesforceConnectorError occured
    public remote function deleteProduct(string productId) returns boolean|SalesforceConnectorError;

    # Updates existing Product object record.
    # + productId - Product ID
    # + productRecord - JSON product record
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function updateProduct(string productId, json productRecord) returns boolean|SalesforceConnectorError;

    //Records
    # Retrieve field values from a standard object record for a specified SObject ID.
    # + sObjectName - SObject name value
    # + id - SObject id
    # + fields - Relevant fields
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getFieldValuesFromSObjectRecord(string sObjectName, string id, string fields)
    returns json|SalesforceConnectorError;

    # Retrieve field values from an external object record using Salesforce ID or External ID.
    # + externalObjectName - External SObject name value
    # + id - External SObject id
    # + fields - Relevant fields
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getFieldValuesFromExternalObjectRecord(string externalObjectName, string id,
    string fields) returns json|SalesforceConnectorError;

    # Allows to create multiple records.
    # + sObjectName - SObject name value
    # + records - JSON records
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function createMultipleRecords(string sObjectName, json records)
    returns json|SalesforceConnectorError;

    # Accesses records based on the value of a specified external ID field.
    # + sObjectName - SObject name value
    # + fieldName - Relevant field name
    # + fieldValue - Relevant field value
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getRecordByExternalId(string sObjectName, string fieldName, string fieldValue)
    returns json|SalesforceConnectorError;

    # Creates new records or updates existing records (upserts records) based on the value of a specified
    # external ID field.
    # + sObjectName - SObject name value
    # + fieldId - Field id
    # + fieldValue - Relevant field value
    # + recordPayload - JSON record
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function upsertSObjectByExternalId(string sObjectName, string fieldId,
    string fieldValue, json recordPayload)
    returns json|SalesforceConnectorError;

    # Retrieves the list of individual records that have been deleted within the given timespan for the specified object
    # + sObjectName - SObject name value
    # + startTime - Start time relevant to records
    # + endTime - End time relevant to records
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getDeletedRecords(string sObjectName, string startTime, string endTime)
    returns json|SalesforceConnectorError;

    # Retrieves the list of individual records that have been updated (added or changed) within the given timespan for
    # the specified object.
    # + sObjectName - SObject name value
    # + startTime - Start time relevant to records
    # + endTime - End time relevant to records
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getUpdatedRecords(string sObjectName, string startTime, string endTime)
    returns json|SalesforceConnectorError;

    //Describe SObjects
    # Lists the available objects and their metadata for your organization and available to the logged-in user.
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function describeAvailableObjects() returns json|SalesforceConnectorError;

    # Describes the individual metadata for the specified object.
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getSObjectBasicInfo(string sobjectName) returns json|SalesforceConnectorError;

    # Completely describes the individual metadata at all levels for the specified object. Can be used to retrieve
    # the fields, URLs, and child relationships.
    # + sObjectName - SObject name value
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function describeSObject(string sObjectName) returns json|SalesforceConnectorError;

    # Query for actions displayed in the UI, given a user, a context, device format, and a record ID.
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function sObjectPlatformAction() returns json|SalesforceConnectorError;

    //Basic CURD
    # Accesses records based on the specified object ID, can be used with external objects.
    # + path - Resource path
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getRecord(string path) returns json|SalesforceConnectorError;

    # Create records based on relevant object type sent with json record.
    # + sObjectName - SObject name value
    # + recordPayload - JSON record to be inserted
    # + return - created entity ID if successful else SalesforceConnectorError occured

    public remote function createRecord(string sObjectName, json recordPayload) returns string|SalesforceConnectorError;

    # Update records based on relevant object id.
    # + sObjectName - SObject name value
    # + id - SObject id
    # + recordPayload - JSON record to be updated
    # + return - true if successful else false or SalesforceConnectorError occured
    public remote function updateRecord(string sObjectName, string id, json recordPayload)
    returns boolean|SalesforceConnectorError;

    # Delete existing records based on relevant object id.
    # + sObjectName - SObject name value
    # + id - SObject id
    # + return - true if successful else false or SalesforceConnectorError occured
    public remote function deleteRecord(string sObjectName, string id) returns boolean|SalesforceConnectorError;
};

# Salesforce client configuration.
# + clientConfig - HTTP configuration
# + baseUrl - The Salesforce API URL
public type SalesforceConfiguration record {
    string baseUrl;
    http:ClientEndpointConfig clientConfig;
};

remote function Client.getAvailableApiVersions() returns json|SalesforceConnectorError {
    string path = prepareUrl([BASE_PATH]);
    return self->getRecord(path);
}

remote function Client.getResourcesByApiVersion(string apiVersion) returns json|SalesforceConnectorError {
    string path = prepareUrl([BASE_PATH, apiVersion]);
    return self->getRecord(path);
}

remote function Client.getOrganizationLimits() returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, LIMITS]);
    return self->getRecord(path);
}

//=============================== Query =======================================//

remote function Client.getQueryResult(string receivedQuery)
    returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, QUERY], [Q], [receivedQuery]);
    return self->getRecord(path);
}

remote function Client.getNextQueryResult(string nextRecordsUrl)
    returns json|SalesforceConnectorError {
    return self->getRecord(nextRecordsUrl);
}

remote function Client.getAllQueries(string queryString) returns json|SalesforceConnectorError {
string path = prepareQueryUrl([API_BASE_PATH, QUERYALL], [Q], [queryString]);
return self->getRecord(path);
}

remote function Client.explainQueryOrReportOrListview(string queryReportOrListview)
    returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, QUERY], [EXPLAIN], [queryReportOrListview]);
    return self->getRecord(path);
}

// ================================= Search ================================ //

remote function Client.searchSOSLString(string searchString) returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, SEARCH], [Q], [searchString]);
    return self->getRecord(path);
}

// ============================ ACCOUNT SObject: get, create, update, delete ===================== //

remote function Client.getAccountById(string accountId) returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, ACCOUNT, accountId]);
    return self->getRecord(path);
}

remote function Client.createAccount(json accountRecord) returns string|SalesforceConnectorError {
    return self->createRecord(ACCOUNT, accountRecord);
}

remote function Client.updateAccount(string accountId, json accountRecord)
    returns boolean|SalesforceConnectorError {
    return self->updateRecord(ACCOUNT, accountId, accountRecord);
}

remote function Client.deleteAccount(string accountId) returns boolean|SalesforceConnectorError {
    return self->deleteRecord(ACCOUNT, accountId);
}

// ============================ LEAD SObject: get, create, update, delete ===================== //

remote function Client.getLeadById(string leadId) returns json|SalesforceConnectorError {
string path = prepareUrl([API_BASE_PATH, SOBJECTS, LEAD, leadId]);
    return self->getRecord(path);
}

remote function Client.createLead(json leadRecord) returns string|SalesforceConnectorError {
    return self->createRecord(LEAD, leadRecord);
}

remote function Client.updateLead(string leadId, json leadRecord)
    returns boolean|SalesforceConnectorError {
    return self->updateRecord(LEAD, leadId, leadRecord);
}

remote function Client.deleteLead(string leadId) returns boolean|SalesforceConnectorError {
    return self->deleteRecord(LEAD, leadId);
}

// ============================ CONTACTS SObject: get, create, update, delete ===================== //

remote function Client.getContactById(string contactId) returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, CONTACT, contactId]);
    return self->getRecord(path);
}

remote function Client.createContact(json contactRecord) returns string|SalesforceConnectorError {
    return self->createRecord(CONTACT, contactRecord);
}

remote function Client.updateContact(string contactId, json contactRecord)
    returns boolean|SalesforceConnectorError {
    return self->updateRecord(CONTACT, contactId, contactRecord);
}

remote function Client.deleteContact(string contactId) returns boolean|SalesforceConnectorError {
    return self->deleteRecord(CONTACT, contactId);
}

// ============================ OPPORTUNITIES SObject: get, create, update, delete ===================== //

remote function Client.getOpportunityById(string opportunityId) returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, OPPORTUNITY, opportunityId]);
    return self->getRecord(path);
}

remote function Client.createOpportunity(json opportunityRecord) returns string|SalesforceConnectorError {
    return self->createRecord(OPPORTUNITY, opportunityRecord);
}

remote function Client.updateOpportunity(string opportunityId, json opportunityRecord)
    returns boolean|SalesforceConnectorError {
    return self->updateRecord(OPPORTUNITY, opportunityId, opportunityRecord);
}

remote function Client.deleteOpportunity(string opportunityId) returns boolean|SalesforceConnectorError {
    return self->deleteRecord(OPPORTUNITY, opportunityId);
}

// ============================ PRODUCTS SObject: get, create, update, delete ===================== //

remote function Client.getProductById(string productId) returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, PRODUCT, productId]);
    return self->getRecord(path);
}

remote function Client.createProduct(json productRecord) returns string|SalesforceConnectorError {
    return self->createRecord(PRODUCT, productRecord);
}

remote function Client.updateProduct(string productId, json productRecord)
    returns boolean|SalesforceConnectorError {
    return self->updateRecord(PRODUCT, productId, productRecord);
}

remote function Client.deleteProduct(string productId) returns boolean|SalesforceConnectorError {
    return self->deleteRecord(PRODUCT, productId);
}

//===========================================================================================================//

remote function Client.getFieldValuesFromSObjectRecord(string sObjectName, string id, string fields)
    returns json|SalesforceConnectorError {
    string prefixPath = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    return self->getRecord(prefixPath + QUESTION_MARK + FIELDS + EQUAL_SIGN + fields);
}

remote function Client.getFieldValuesFromExternalObjectRecord(string externalObjectName, string id,
    string fields) returns json|SalesforceConnectorError {
    string prefixPath = prepareUrl([API_BASE_PATH, SOBJECTS, externalObjectName, id]);
    return self->getRecord(prefixPath + QUESTION_MARK + FIELDS + EQUAL_SIGN + fields);
}

remote function Client.createMultipleRecords(string sObjectName, json records)
    returns json|SalesforceConnectorError {

    json payload;
    http:Request req = new;
    string path = string `{{API_BASE_PATH}}/{{MULTIPLE_RECORDS}}/{{sObjectName}}`;
    req.setJsonPayload(records);

    http:Response|error response = self.salesforceClient->post(path, req);

    return checkAndSetErrors(response, true);
}

// ============================ Create, update, delete records by External IDs ===================== //

remote function Client.getRecordByExternalId(string sObjectName, string fieldName, string fieldValue)
    returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, fieldName, fieldValue]);
    return self->getRecord(path);
}

remote function Client.upsertSObjectByExternalId(string sObjectName, string fieldId, string fieldValue,
    json recordPayload) returns json|SalesforceConnectorError {

    json payload;
    http:Request req = new;
    string path = string `{{API_BASE_PATH}}/{{SOBJECTS}}/{{sObjectName}}/{{fieldId}}/{{fieldValue}}`;
    req.setJsonPayload(recordPayload);

    http:Response|error response = self.salesforceClient->patch(path, req);

    return checkAndSetErrors(response, false);
}

// ============================ Get updated and deleted records ===================== //

remote function Client.getDeletedRecords(string sObjectName, string startTime, string endTime)
    returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, SOBJECTS, sObjectName, DELETED], [START, END], [startTime, endTime]);
    return self->getRecord(path);
}

remote function Client.getUpdatedRecords(string sObjectName, string startTime, string endTime)
    returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, SOBJECTS, sObjectName, UPDATED], [START, END], [startTime, endTime]);
    return self->getRecord(path);
}

// ============================ Describe SObjects available and their fields/metadata ===================== //

remote function Client.describeAvailableObjects() returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS]);
    return self->getRecord(path);
}

remote function Client.getSObjectBasicInfo(string sobjectName) returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName]);
    return self->getRecord(path);
}

remote function Client.describeSObject(string sObjectName) returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DESCRIBE]);
    return self->getRecord(path);
}

remote function Client.sObjectPlatformAction() returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, PLATFORM_ACTION]);
    return self->getRecord(path);
}

//============================ utility functions================================//

remote function Client.getRecord(string path) returns json|SalesforceConnectorError {
    http:Response|error response = self.salesforceClient->get(path);
    return checkAndSetErrors(response, true);
}

remote function Client.createRecord(string sObjectName, json recordPayload)
    returns string|SalesforceConnectorError {
    http:Request req = new;
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
    req.setJsonPayload(recordPayload);

    var response = self.salesforceClient->post(path, req);

    json|SalesforceConnectorError result = checkAndSetErrors(response, true);
    if (result is json) {
        return result.id.toString();
    } else {
        return result;
    }
}

remote function Client.updateRecord(string sObjectName, string id, json recordPayload)
    returns boolean|SalesforceConnectorError {
    http:Request req = new;
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    req.setJsonPayload(recordPayload);

    var response = self.salesforceClient->patch(path, req);

    json|SalesforceConnectorError result = checkAndSetErrors(response, false);

    if (result is json) {
        return true;
    } else {
        return result;
    }
}

remote function Client.deleteRecord(string sObjectName, string id)
    returns boolean|SalesforceConnectorError {
    http:Request req = new;
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);

    var response = self.salesforceClient->delete(path, req);

    json|SalesforceConnectorError result = checkAndSetErrors(response, false);

    if (result is json) {
        return true;
    } else {
        return result;
    }
}