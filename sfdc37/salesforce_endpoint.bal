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

# Salesforce client configuration.
# + clientConfig - HTTP configuration
# + baseUrl - The Salesforce API URL
public type SalesforceConfiguration record {
    string baseUrl;
    http:ClientEndpointConfig clientConfig;
};

# Salesforce Client object.
# + salesforceConnector - Salesforce Connector
public type Client client object {
    public SalesforceConnector salesforceConnector;

    # Salesforce Connector endpoint initialization function.
    # + config - Salesforce Connector configuration
    public function __init(SalesforceConfiguration salesforceConfig) {
        self.salesforceConnector = new(salesforceConfig.baseUrl, salesforceConfig);
    }

    # Lists summary details about each REST API version available.
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getAvailableApiVersions() returns json|SalesforceConnectorError {
        return self.salesforceConnector->getAvailableApiVersions();
    }

    # Lists the resources available for the specified API version.
    # + apiVersion - API version (v37)
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getResourcesByApiVersion(string apiVersion) returns json|SalesforceConnectorError {
        return self.salesforceConnector->getResourcesByApiVersion(apiVersion);
    }

    # Lists limits information for your organization.
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getOrganizationLimits() returns json|SalesforceConnectorError {
        return self.salesforceConnector->getOrganizationLimits();
    }

    // Query
    # Executes the specified SOQL query.
    # + receivedQuery - Sent SOQL query
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getQueryResult(string receivedQuery) returns json|SalesforceConnectorError {
        return self.salesforceConnector->getQueryResult(receivedQuery);
    }

    # If the query results are too large, retrieve the next batch of results using nextRecordUrl.
    # + nextRecordsUrl - URL to get next query results
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getNextQueryResult(string nextRecordsUrl) returns json|SalesforceConnectorError {
        return self.salesforceConnector->getNextQueryResult(nextRecordsUrl);
    }

    # Returns records that have been deleted because of a merge or delete, archived Task
    # and Event records.
    # + queryString - Sent SOQL query
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getAllQueries(string queryString) returns json|SalesforceConnectorError {
        return self.salesforceConnector->getAllQueries(queryString);
    }

    # Get feedback on how Salesforce will execute the query, report, or list view based on performance.
    # + queryReportOrListview - Sent query
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function explainQueryOrReportOrListview(string queryReportOrListview)
    returns json|SalesforceConnectorError {
        return self.salesforceConnector->explainQueryOrReportOrListview(queryReportOrListview);
    }

    //Search
    # Executes the specified SOSL search.
    # + searchString - Sent SOSL search query
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function searchSOSLString(string searchString) returns json|SalesforceConnectorError {
        return self.salesforceConnector->searchSOSLString(searchString);
    }

    //Account
    # Accesses Account SObject records based on the Account object ID.
    # + accountId - Account ID
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getAccountById(string accountId) returns json|SalesforceConnectorError {
        return self.salesforceConnector->getAccountById(accountId);
    }

    # Creates new Account object record.
    # + accountRecord - Account JSON record to be inserted
    # + return - If successful return account ID, else SalesforceConnectorError occured
    public remote function createAccount(json accountRecord) returns string|SalesforceConnectorError {
        return self.salesforceConnector->createAccount(accountRecord);
    }

    # Deletes existing Account's records.
    # + accountId - Account ID
    # + return - true if successful false otherwise, or SalesforceConnectorError occured
    public remote function deleteAccount(string accountId) returns boolean|SalesforceConnectorError {
        return self.salesforceConnector->deleteAccount(accountId);
    }

    # Updates existing Account object record.
    # + accountId - Account ID
    # + return - true if successful, false otherwise or SalesforceConnectorError occured
    public remote function updateAccount(string accountId, json accountRecord)
    returns boolean|SalesforceConnectorError {
        return self.salesforceConnector->updateAccount(accountId, accountRecord);
    }

    //Lead
    # Accesses Lead SObject records based on the Lead object ID.
    # + leadId - Lead ID
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getLeadById(string leadId) returns json|SalesforceConnectorError {
        return self.salesforceConnector->getLeadById(leadId);
    }

    # Creates new Lead object record.
    # + leadRecord - Lead JSON record to be inserted
    # + return - string lead ID result if successful else SalesforceConnectorError occured
    public remote function createLead(json leadRecord) returns string|SalesforceConnectorError {
        return self.salesforceConnector->createLead(leadRecord);
    }

    # Deletes existing Lead's records.
    # + leadId - Lead ID
    # + return - true  if successful, flase otherwise or SalesforceConnectorError occured
    public remote function deleteLead(string leadId) returns boolean|SalesforceConnectorError {
        return self.salesforceConnector->deleteLead(leadId);
    }

    # Updates existing Lead object record.
    # + leadId - Lead ID
    # + leadRecord - Lead JSON record
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function updateLead(string leadId, json leadRecord) returns boolean|SalesforceConnectorError {
        return self.salesforceConnector->updateLead(leadId, leadRecord);
    }

    //Contact
    # Accesses Contacts SObject records based on the Contact object ID.
    # + contactId - Contact ID
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getContactById(string contactId) returns json|SalesforceConnectorError {
        return self.salesforceConnector->getContactById(contactId);
    }

    # Creates new Contact object record.
    # + contactRecord - JSON contact record
    # + return - string ID if successful else SalesforceConnectorError occured
    public remote function createContact(json contactRecord) returns string|SalesforceConnectorError {
        return self.salesforceConnector->createContact(contactRecord);
    }

    # Deletes existing Contact's records.
    # + contactId - Contact ID
    # + return - true if successful else false, or SalesforceConnectorError occured
    public remote function deleteContact(string contactId) returns boolean|SalesforceConnectorError {
        return self.salesforceConnector->deleteContact(contactId);
    }

    # Updates existing Contact object record.
    # + contactId - Contact ID
    # + contactRecord - JSON contact record
    # + return - true if successful else false or SalesforceConnectorError occured
    public remote function updateContact(string contactId, json contactRecord)
    returns boolean|SalesforceConnectorError {
        return self.salesforceConnector->updateContact(contactId, contactRecord);
    }

    //Opportunity
    # Accesses Opportunities SObject records based on the Opportunity object ID.
    # + opportunityId - Opportunity ID
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getOpportunityById(string opportunityId) returns json|SalesforceConnectorError {
        return self.salesforceConnector->getOpportunityById(opportunityId);
    }

    # Creates new Opportunity object record.
    # + opportunityRecord - JSON opportunity record
    # + return - Opportunity ID if successful else SalesforceConnectorError occured
    public remote function createOpportunity(json opportunityRecord) returns string|SalesforceConnectorError {
        return self.salesforceConnector->createOpportunity(opportunityRecord);
    }

    # Deletes existing Opportunity's records.
    # + opportunityId - Opportunity ID
    # + return - true if successful else false or SalesforceConnectorError occured
    public remote function deleteOpportunity(string opportunityId) returns boolean|SalesforceConnectorError {
        return self.salesforceConnector->deleteOpportunity(opportunityId);
    }

    # Updates existing Opportunity object record.
    # + opportunityId - Opportunity ID
    # + return - true if successful else false or SalesforceConnectorError occured
    public remote function updateOpportunity(string opportunityId, json opportunityRecord)
    returns boolean|SalesforceConnectorError {
        return self.salesforceConnector->updateOpportunity(opportunityId, opportunityRecord);
    }

    //Product
    # Accesses Products SObject records based on the Product object ID.
    # + productId - Product ID
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getProductById(string productId) returns json|SalesforceConnectorError {
        return self.salesforceConnector->getProductById(productId);
    }

    # Creates new Product object record.
    # + productRecord - JSON product record
    # + return - Product ID if successful else SalesforceConnectorError occured
    public remote function createProduct(json productRecord) returns string|SalesforceConnectorError {
        return self.salesforceConnector->createProduct(productRecord);
    }

    # Deletes existing product's records.
    # + productId - Product ID
    # + return - true if successful else false or SalesforceConnectorError occured
    public remote function deleteProduct(string productId) returns boolean|SalesforceConnectorError {
        return self.salesforceConnector->deleteProduct(productId);
    }

    # Updates existing Product object record.
    # + productId - Product ID
    # + productRecord - JSON product record
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function updateProduct(string productId, json productRecord)
    returns boolean|SalesforceConnectorError {
        return self.salesforceConnector->updateProduct(productId, productRecord);
    }

    //Records
    # Retrieve field values from a standard object record for a specified SObject ID.
    # + sObjectName - SObject name value
    # + id - SObject id
    # + fields - Relevant fields
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getFieldValuesFromSObjectRecord(string sObjectName, string id, string fields)
    returns json|SalesforceConnectorError {
        return self.salesforceConnector->getFieldValuesFromSObjectRecord(sObjectName, id, fields);
    }

    # Retrieve field values from an external object record using Salesforce ID or External ID.
    # + externalObjectName - External SObject name value
    # + id - External SObject id
    # + fields - Relevant fields
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getFieldValuesFromExternalObjectRecord(string externalObjectName, string id,
    string fields) returns json|SalesforceConnectorError {
        return self.salesforceConnector->getFieldValuesFromSObjectRecord(externalObjectName, id, fields);
    }

    # Allows to create multiple records.
    # + sObjectName - SObject name value
    # + records - JSON records
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function createMultipleRecords(string sObjectName, json records)
    returns json|SalesforceConnectorError {
        return self.salesforceConnector->createMultipleRecords(sObjectName, records);
    }

    # Accesses records based on the value of a specified external ID field.
    # + sObjectName - SObject name value
    # + fieldName - Relevant field name
    # + fieldValue - Relevant field value
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getRecordByExternalId(string sObjectName, string fieldName, string fieldValue)
    returns json|SalesforceConnectorError {
        return self.salesforceConnector->getRecordByExternalId(sObjectName, fieldName, fieldValue);
    }

    # Creates new records or updates existing records (upserts records) based on the value of a specified
    # external ID field.
    # + sObjectName - SObject name value
    # + fieldId - Field id
    # + fieldValue - Relevant field value
    # + recordPayload - JSON record
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function upsertSObjectByExternalId(string sObjectName, string fieldId, string fieldValue,
    json recordPayload) returns json|SalesforceConnectorError {
        return self.salesforceConnector->upsertSObjectByExternalId(sObjectName, fieldId, fieldValue, recordPayload);
    }

    # Retrieves the list of individual records that have been deleted within the given timespan for the specified object
    # + sObjectName - SObject name value
    # + startTime - Start time relevant to records
    # + endTime - End time relevant to records
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getDeletedRecords(string sObjectName, string startTime, string endTime)
    returns json|SalesforceConnectorError {
        return self.salesforceConnector->getDeletedRecords(sObjectName, startTime, endTime);
    }

    # Retrieves the list of individual records that have been updated (added or changed) within the given timespan for
    # the specified object.
    # + sObjectName - SObject name value
    # + startTime - Start time relevant to records
    # + endTime - End time relevant to records
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getUpdatedRecords(string sObjectName, string startTime, string endTime)
    returns json|SalesforceConnectorError {
        return self.salesforceConnector->getUpdatedRecords(sObjectName, startTime, endTime);
    }

    //Describe SObjects
    # Lists the available objects and their metadata for your organization and available to the logged-in user.
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function describeAvailableObjects() returns json|SalesforceConnectorError {
        return self.salesforceConnector->describeAvailableObjects();
    }

    # Describes the individual metadata for the specified object.
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getSObjectBasicInfo(string sobjectName) returns json|SalesforceConnectorError {
        return self.salesforceConnector->getSObjectBasicInfo(sobjectName);
    }

    # Completely describes the individual metadata at all levels for the specified object. Can be used to retrieve
    # the fields, URLs, and child relationships.
    # + sObjectName - SObject name value
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function describeSObject(string sObjectName) returns json|SalesforceConnectorError {
        return self.salesforceConnector->describeSObject(sObjectName);
    }

    # Query for actions displayed in the UI, given a user, a context, device format, and a record ID.
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function sObjectPlatformAction() returns json|SalesforceConnectorError {
        return self.salesforceConnector->sObjectPlatformAction();
    }

    //Basic CURD
    # Accesses records based on the specified object ID, can be used with external objects.
    # + path - Resource path
    # + return - `json` result if successful else SalesforceConnectorError occured
    public remote function getRecord(string path) returns json|SalesforceConnectorError {
        return self.salesforceConnector->getRecord(path);
    }

    # Create records based on relevant object type sent with json record.
    # + sObjectName - SObject name value
    # + recordPayload - JSON record to be inserted
    # + return - created entity ID if successful else SalesforceConnectorError occured

    public remote function createRecord(string sObjectName, json recordPayload)
    returns string|SalesforceConnectorError {
        return self.salesforceConnector->createRecord(sObjectName, recordPayload);
    }

    # Update records based on relevant object id.
    # + sObjectName - SObject name value
    # + id - SObject id
    # + recordPayload - JSON record to be updated
    # + return - true if successful else false or SalesforceConnectorError occured
    public remote function updateRecord(string sObjectName, string id, json recordPayload)
    returns boolean|SalesforceConnectorError {
        return self.salesforceConnector->updateRecord(sObjectName, id, recordPayload);
    }

    # Delete existing records based on relevant object id.
    # + sObjectName - SObject name value
    # + id - SObject id
    # + return - true if successful else false or SalesforceConnectorError occured
    public remote function deleteRecord(string sObjectName, string id) returns boolean|SalesforceConnectorError {
        return self.salesforceConnector->deleteRecord(sObjectName, id);
    }
};
