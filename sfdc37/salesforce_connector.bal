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

# Salesforce Connector.
# + httpClient - OAuth2 client endpoint
public type SalesforceConnector object {
    public http:Client httpClient;

    # Lists summary details about each REST API version available.
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getAvailableApiVersions() returns (json|SalesforceConnectorError);

    # Lists the resources available for the specified API version.
    # + apiVersion - API version (v37)
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getResourcesByApiVersion(string apiVersion) returns (json|SalesforceConnectorError);

    # Lists limits information for your organization.
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getOrganizationLimits() returns (json|SalesforceConnectorError);

    // Query
    # Executes the specified SOQL query.
    # + receivedQuery - Sent SOQL query
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getQueryResult(string receivedQuery) returns (json|SalesforceConnectorError);

    # If the query results are too large, retrieve the next batch of results using nextRecordUrl.
    # + nextRecordsUrl - URL to get next query results
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getNextQueryResult(string nextRecordsUrl) returns (json|SalesforceConnectorError);

    # Returns records that have been deleted because of a merge or delete, archived Task
    # and Event records.
    # + queryString - Sent SOQL query
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getAllQueries(string queryString) returns (json|SalesforceConnectorError);

    # Get feedback on how Salesforce will execute the query, report, or list view based on performance.
    # + queryReportOrListview - Sent query
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function explainQueryOrReportOrListview(string queryReportOrListview)
                        returns (json|SalesforceConnectorError);

    //Search
    # Executes the specified SOSL search.
    # + searchString - Sent SOSL search query
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function searchSOSLString(string searchString) returns (json|SalesforceConnectorError);

    //Account
    # Accesses Account SObject records based on the Account object ID.
    # + accountId - Account ID
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getAccountById(string accountId) returns (json|SalesforceConnectorError);

    # Creates new Account object record.
    # + accountRecord - Account JSON record to be inserted
    # + return - If successful return account ID, else SalesforceConnectorError occured
    public function createAccount(json accountRecord) returns (string|SalesforceConnectorError);

    # Deletes existing Account's records.
    # + accountId - Account ID
    # + return - true if successful false otherwise, or SalesforceConnectorError occured
    public function deleteAccount(string accountId) returns (boolean|SalesforceConnectorError);

    # Updates existing Account object record.
    # + accountId - Account ID
    # + return - true if successful, false otherwise or SalesforceConnectorError occured
    public function updateAccount(string accountId, json accountRecord) returns (boolean|SalesforceConnectorError);

    //Lead
    # Accesses Lead SObject records based on the Lead object ID.
    # + leadId - Lead ID
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getLeadById(string leadId) returns (json|SalesforceConnectorError);

    # Creates new Lead object record.
    # + leadRecord - Lead JSON record to be inserted
    # + return - string lead ID result if successful else SalesforceConnectorError occured
    public function createLead(json leadRecord) returns (string|SalesforceConnectorError);

    # Deletes existing Lead's records.
    # + leadId - Lead ID
    # + return - true  if successful, flase otherwise or SalesforceConnectorError occured
    public function deleteLead(string leadId) returns (boolean|SalesforceConnectorError);

    # Updates existing Lead object record.
    # + leadId - Lead ID
    # + leadRecord - Lead JSON record
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function updateLead(string leadId, json leadRecord) returns (boolean|SalesforceConnectorError);

    //Contact
    # Accesses Contacts SObject records based on the Contact object ID.
    # + contactId - Contact ID
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getContactById(string contactId) returns (json|SalesforceConnectorError);

    # Creates new Contact object record.
    # + contactRecord - JSON contact record
    # + return - string ID if successful else SalesforceConnectorError occured
    public function createContact(json contactRecord) returns (string|SalesforceConnectorError);

    # Deletes existing Contact's records.
    # + contactId - Contact ID
    # + return - true if successful else false, or SalesforceConnectorError occured
    public function deleteContact(string contactId) returns (boolean|SalesforceConnectorError);

    # Updates existing Contact object record.
    # + contactId - Contact ID
    # + contactRecord - JSON contact record
    # + return - true if successful else false or SalesforceConnectorError occured
    public function updateContact(string contactId, json contactRecord) returns (boolean|SalesforceConnectorError);

    //Opportunity
    # Accesses Opportunities SObject records based on the Opportunity object ID.
    # + opportunityId - Opportunity ID
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getOpportunityById(string opportunityId) returns (json|SalesforceConnectorError);

    # Creates new Opportunity object record.
    # + opportunityRecord - JSON opportunity record
    # + return - Opportunity ID if successful else SalesforceConnectorError occured
    public function createOpportunity(json opportunityRecord) returns (string|SalesforceConnectorError);

    # Deletes existing Opportunity's records.
    # + opportunityId - Opportunity ID
    # + return - true if successful else false or SalesforceConnectorError occured
    public function deleteOpportunity(string opportunityId) returns (boolean|SalesforceConnectorError);

    # Updates existing Opportunity object record.
    # + opportunityId - Opportunity ID
    # + return - true if successful else false or SalesforceConnectorError occured
    public function updateOpportunity(string opportunityId, json opportunityRecord)
                        returns (boolean|SalesforceConnectorError);

    //Product
    # Accesses Products SObject records based on the Product object ID.
    # + productId - Product ID
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getProductById(string productId) returns (json|SalesforceConnectorError);

    # Creates new Product object record.
    # + productRecord - JSON product record
    # + return - Product ID if successful else SalesforceConnectorError occured
    public function createProduct(json productRecord) returns (string|SalesforceConnectorError);

    # Deletes existing product's records.
    # + productId - Product ID
    # + return - true if successful else false or SalesforceConnectorError occured
    public function deleteProduct(string productId) returns (boolean|SalesforceConnectorError);

    # Updates existing Product object record.
    # + productId - Product ID
    # + productRecord - JSON product record
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function updateProduct(string productId, json productRecord) returns (boolean|SalesforceConnectorError);

    //Records
    # Retrieve field values from a standard object record for a specified SObject ID.
    # + sObjectName - SObject name value
    # + id - SObject id
    # + fields - Relevant fields
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getFieldValuesFromSObjectRecord(string sObjectName, string id, string fields)
                        returns (json|SalesforceConnectorError);

    # Retrieve field values from an external object record using Salesforce ID or External ID.
    # + externalObjectName - External SObject name value
    # + id - External SObject id
    # + fields - Relevant fields
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getFieldValuesFromExternalObjectRecord(string externalObjectName, string id,
                                                           string fields) returns (json|SalesforceConnectorError);

    # Allows to create multiple records.
    # + sObjectName - SObject name value
    # + records - JSON records
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function createMultipleRecords(string sObjectName, json records)
                        returns (json|SalesforceConnectorError);

    # Accesses records based on the value of a specified external ID field.
    # + sObjectName - SObject name value
    # + fieldName - Relevant field name
    # + fieldValue - Relevant field value
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getRecordByExternalId(string sObjectName, string fieldName, string fieldValue)
                        returns (json|SalesforceConnectorError);

    # Creates new records or updates existing records (upserts records) based on the value of a specified
    # external ID field.
    # + sObjectName - SObject name value
    # + fieldId - Field id
    # + fieldValue - Relevant field value
    # + recordPayload - JSON record
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function upsertSObjectByExternalId(string sObjectName, string fieldId,
                                              string fieldValue, json recordPayload)
                        returns (json|SalesforceConnectorError);

    # Retrieves the list of individual records that have been deleted within the given timespan for the specified object
    # + sObjectName - SObject name value
    # + startTime - Start time relevant to records
    # + endTime - End time relevant to records
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getDeletedRecords(string sObjectName, string startTime, string endTime)
                        returns (json|SalesforceConnectorError);

    # Retrieves the list of individual records that have been updated (added or changed) within the given timespan for
    # the specified object.
    # + sObjectName - SObject name value
    # + startTime - Start time relevant to records
    # + endTime - End time relevant to records
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getUpdatedRecords(string sObjectName, string startTime, string endTime)
                        returns (json|SalesforceConnectorError);

    //Describe SObjects
    # Lists the available objects and their metadata for your organization and available to the logged-in user.
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function describeAvailableObjects() returns (json|SalesforceConnectorError);

    # Describes the individual metadata for the specified object.
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getSObjectBasicInfo(string sobjectName) returns (json|SalesforceConnectorError);

    # Completely describes the individual metadata at all levels for the specified object. Can be used to retrieve
    # the fields, URLs, and child relationships.
    # + sObjectName - SObject name value
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function describeSObject(string sObjectName) returns (json|SalesforceConnectorError);

    # Query for actions displayed in the UI, given a user, a context, device format, and a record ID.
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function sObjectPlatformAction() returns (json|SalesforceConnectorError);

    //Basic CURD
    # Accesses records based on the specified object ID, can be used with external objects.
    # + path - Resource path
    # + return - `json` result if successful else SalesforceConnectorError occured
    public function getRecord(string path) returns (json|SalesforceConnectorError);

    # Create records based on relevant object type sent with json record.
    # + sObjectName - SObject name value
    # + recordPayload - JSON record to be inserted
    # + return - created entity ID if successful else SalesforceConnectorError occured

    public function createRecord(string sObjectName, json recordPayload) returns (string|SalesforceConnectorError);

    # Update records based on relevant object id.
    # + sObjectName - SObject name value
    # + id - SObject id
    # + recordPayload - JSON record to be updated
    # + return - true if successful else false or SalesforceConnectorError occured
    public function updateRecord(string sObjectName, string id, json recordPayload)
                        returns (boolean|SalesforceConnectorError);

    # Delete existing records based on relevant object id.
    # + sObjectName - SObject name value
    # + id - SObject id
    # + return - true if successful else false or SalesforceConnectorError occured
    public function deleteRecord(string sObjectName, string id) returns (boolean|SalesforceConnectorError);
};

function SalesforceConnector::getAvailableApiVersions() returns json|SalesforceConnectorError {
    string path = prepareUrl([BASE_PATH]);
    return self.getRecord(path);
}

function SalesforceConnector::getResourcesByApiVersion(string apiVersion) returns json|SalesforceConnectorError {
    string path = prepareUrl([BASE_PATH, apiVersion]);
    return self.getRecord(path);
}

function SalesforceConnector::getOrganizationLimits() returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, LIMITS]);
    return self.getRecord(path);
}

//=============================== Query =======================================//

function SalesforceConnector::getQueryResult(string receivedQuery)
                                         returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, QUERY], [Q], [receivedQuery]);
    return self.getRecord(path);
}

function SalesforceConnector::getNextQueryResult(string nextRecordsUrl)
                                         returns json|SalesforceConnectorError {
    return self.getRecord(nextRecordsUrl);
}

function SalesforceConnector::getAllQueries(string queryString) returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, QUERYALL], [Q], [queryString]);
    return self.getRecord(path);
}

function SalesforceConnector::explainQueryOrReportOrListview(string queryReportOrListview)
                                         returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, QUERY], [EXPLAIN], [queryReportOrListview]);
    return self.getRecord(path);
}

// ================================= Search ================================ //

function SalesforceConnector::searchSOSLString(string searchString) returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, SEARCH], [Q], [searchString]);
    return self.getRecord(path);
}

// ============================ ACCOUNT SObject: get, create, update, delete ===================== //

function SalesforceConnector::getAccountById(string accountId) returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, ACCOUNT, accountId]);
    return self.getRecord(path);
}

function SalesforceConnector::createAccount(json accountRecord) returns string|SalesforceConnectorError {
    return self.createRecord(ACCOUNT, accountRecord);
}

function SalesforceConnector::updateAccount(string accountId, json accountRecord)
                                         returns boolean|SalesforceConnectorError {
    return self.updateRecord(ACCOUNT, accountId, accountRecord);
}

function SalesforceConnector::deleteAccount(string accountId) returns boolean|SalesforceConnectorError {
    return self.deleteRecord(ACCOUNT, accountId);
}

// ============================ LEAD SObject: get, create, update, delete ===================== //

function SalesforceConnector::getLeadById(string leadId) returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, LEAD, leadId]);
    return self.getRecord(path);
}

function SalesforceConnector::createLead(json leadRecord) returns string|SalesforceConnectorError {
    return self.createRecord(LEAD, leadRecord);
}

function SalesforceConnector::updateLead(string leadId, json leadRecord)
                                         returns boolean|SalesforceConnectorError {
    return self.updateRecord(LEAD, leadId, leadRecord);
}

function SalesforceConnector::deleteLead(string leadId) returns boolean|SalesforceConnectorError {
    return self.deleteRecord(LEAD, leadId);
}

// ============================ CONTACTS SObject: get, create, update, delete ===================== //

function SalesforceConnector::getContactById(string contactId) returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, CONTACT, contactId]);
    return self.getRecord(path);
}

function SalesforceConnector::createContact(json contactRecord) returns string|SalesforceConnectorError {
    return self.createRecord(CONTACT, contactRecord);
}

function SalesforceConnector::updateContact(string contactId, json contactRecord)
                                         returns boolean|SalesforceConnectorError {
    return self.updateRecord(CONTACT, contactId, contactRecord);
}

function SalesforceConnector::deleteContact(string contactId) returns boolean|SalesforceConnectorError {
    return self.deleteRecord(CONTACT, contactId);
}

// ============================ OPPORTUNITIES SObject: get, create, update, delete ===================== //

function SalesforceConnector::getOpportunityById(string opportunityId) returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, OPPORTUNITY, opportunityId]);
    return self.getRecord(path);
}

function SalesforceConnector::createOpportunity(json opportunityRecord) returns string|SalesforceConnectorError {
    return self.createRecord(OPPORTUNITY, opportunityRecord);
}

function SalesforceConnector::updateOpportunity(string opportunityId, json opportunityRecord)
                                         returns boolean|SalesforceConnectorError {
    return self.updateRecord(OPPORTUNITY, opportunityId, opportunityRecord);
}

function SalesforceConnector::deleteOpportunity(string opportunityId) returns boolean|SalesforceConnectorError {
    return self.deleteRecord(OPPORTUNITY, opportunityId);
}

// ============================ PRODUCTS SObject: get, create, update, delete ===================== //

function SalesforceConnector::getProductById(string productId) returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, PRODUCT, productId]);
    return self.getRecord(path);
}

function SalesforceConnector::createProduct(json productRecord) returns string|SalesforceConnectorError {
    return self.createRecord(PRODUCT, productRecord);
}

function SalesforceConnector::updateProduct(string productId, json productRecord)
                                         returns boolean|SalesforceConnectorError {
    return self.updateRecord(PRODUCT, productId, productRecord);
}

function SalesforceConnector::deleteProduct(string productId) returns boolean|SalesforceConnectorError {
    return self.deleteRecord(PRODUCT, productId);
}

//===========================================================================================================//

function SalesforceConnector::getFieldValuesFromSObjectRecord(string sObjectName, string id, string fields)
                                         returns json|SalesforceConnectorError {
    string prefixPath = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    return self.getRecord(prefixPath + QUESTION_MARK + FIELDS + EQUAL_SIGN + fields);
}

function SalesforceConnector::getFieldValuesFromExternalObjectRecord(string externalObjectName, string id, string fields)
                                         returns json|SalesforceConnectorError {
    string prefixPath = prepareUrl([API_BASE_PATH, SOBJECTS, externalObjectName, id]);
    return self.getRecord(prefixPath + QUESTION_MARK + FIELDS + EQUAL_SIGN + fields);

}

function SalesforceConnector::createMultipleRecords(string sObjectName, json records)
                                         returns json|SalesforceConnectorError {
    endpoint http:Client httpClient = self.httpClient;

    json payload;
    http:Request req = new;
    string path = string `{{API_BASE_PATH}}/{{MULTIPLE_RECORDS}}/{{sObjectName}}`;
    req.setJsonPayload(records);

    http:Response|error response = httpClient->post(path, req);

    return checkAndSetErrors(response, true);
}

// ============================ Create, update, delete records by External IDs ===================== //

function SalesforceConnector::getRecordByExternalId(string sObjectName, string fieldName, string fieldValue)
                                         returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, fieldName, fieldValue]);
    return self.getRecord(path);
}

function SalesforceConnector::upsertSObjectByExternalId(string sObjectName, string fieldId, string fieldValue,
                                                               json recordPayload) returns json|SalesforceConnectorError {
    endpoint http:Client httpClient = self.httpClient;
    json payload;
    http:Request req = new;
    string path = string `{{API_BASE_PATH}}/{{SOBJECTS}}/{{sObjectName}}/{{fieldId}}/{{fieldValue}}`;
    req.setJsonPayload(recordPayload);

    http:Response|error response = httpClient->patch(path, req);

    return checkAndSetErrors(response, false);
}

// ============================ Get updated and deleted records ===================== //

function SalesforceConnector::getDeletedRecords(string sObjectName, string startTime, string endTime)
                                         returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, SOBJECTS, sObjectName, DELETED], [START, END], [startTime, endTime]);
    return self.getRecord(path);
}

function SalesforceConnector::getUpdatedRecords(string sObjectName, string startTime, string endTime)
                                         returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, SOBJECTS, sObjectName, UPDATED], [START, END], [startTime, endTime]);
    return self.getRecord(path);
}

// ============================ Describe SObjects available and their fields/metadata ===================== //

function SalesforceConnector::describeAvailableObjects() returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS]);
    return self.getRecord(path);
}

function SalesforceConnector::getSObjectBasicInfo(string sobjectName) returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName]);
    return self.getRecord(path);
}

function SalesforceConnector::describeSObject(string sObjectName) returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DESCRIBE]);
    return self.getRecord(path);
}

function SalesforceConnector::sObjectPlatformAction() returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, PLATFORM_ACTION]);
    return self.getRecord(path);
}

//============================ utility functions================================//

function SalesforceConnector::getRecord(string path) returns json|SalesforceConnectorError {
    endpoint http:Client httpClient = self.httpClient;
    http:Response|error response = httpClient->get(path);
    return checkAndSetErrors(response, true);
}

function SalesforceConnector::createRecord(string sObjectName, json recordPayload)
                                         returns string|SalesforceConnectorError {
    endpoint http:Client httpClient = self.httpClient;
    http:Request req = new;
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
    req.setJsonPayload(recordPayload);

    http:Response|error response = httpClient->post(path, req);

    json|SalesforceConnectorError result = checkAndSetErrors(response, true);
    match result {
        json jsonResult => {
            return jsonResult.id.toString();
        }
        SalesforceConnectorError err => {
            return err;
        }
    }
}

function SalesforceConnector::updateRecord(string sObjectName, string id, json recordPayload)
                                         returns boolean|SalesforceConnectorError {
    endpoint http:Client httpClient = self.httpClient;
    http:Request req = new;
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    req.setJsonPayload(recordPayload);

    http:Response|error response = httpClient->patch(path, req);

    json|SalesforceConnectorError result = checkAndSetErrors(response, false);
    match result {
        json => {
            return true;
        }
        SalesforceConnectorError err => {
            return err;
        }
    }
}

function SalesforceConnector::deleteRecord(string sObjectName, string id)
                                         returns boolean|SalesforceConnectorError {
    endpoint http:Client httpClient = self.httpClient;
    http:Request req = new;
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);

    http:Response|error response = httpClient->delete(path, req);

    json|SalesforceConnectorError result = checkAndSetErrors(response, false);
    match result {
        json => {
            return true;
        }
        SalesforceConnectorError err => {
            return err;
        }
    }
}
