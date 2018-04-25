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

documentation {Salesforce Connector
    F{{httpClient}} OAuth2 client endpoint
}
public type SalesforceConnector object {
    public {
        http:Client httpClient;
    }

    documentation {Lists summary details about each REST API version available
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getAvailableApiVersions() returns (json|SalesforceConnectorError);

    documentation {Lists the resources available for the specified API version
        P{{apiVersion}} API version (v37)
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getResourcesByApiVersion(string apiVersion) returns (json|SalesforceConnectorError);

    documentation {Lists limits information for your organization
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getOrganizationLimits() returns (json|SalesforceConnectorError);

    // Query
    documentation {Executes the specified SOQL query
        P{{receivedQuery}} Sent SOQL query
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getQueryResult(string receivedQuery) returns (json|SalesforceConnectorError);

    documentation {If the query results are too large, retrieve the next batch of results using nextRecordUrl
        P{{nextRecordsUrl}} URL to get next query results
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getNextQueryResult(string nextRecordsUrl) returns (json|SalesforceConnectorError);

    documentation {Returns records that have been deleted because of a merge or delete, archived Task
                    and Event records
        P{{queryString}} Sent SOQL query
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getAllQueries(string queryString) returns (json|SalesforceConnectorError);

    documentation {Get feedback on how Salesforce will execute the query, report,
                    or list view based on performance
        P{{queryReportOrListview}} sent query
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function explainQueryOrReportOrListview(string queryReportOrListview)
        returns (json|SalesforceConnectorError);

    //Search
    documentation {Executes the specified SOSL search
        P{{searchString}} Sent SOSL search query
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function searchSOSLString(string searchString) returns (json|SalesforceConnectorError);

    //Account
    documentation {Accesses Account SObject records based on the Account object ID
        P{{accountId}} Account ID
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getAccountById(string accountId) returns (json|SalesforceConnectorError);

    documentation {Creates new Account object record
        P{{accountRecord}} Account JSON record to be inserted
        R{{}} string account ID if successful else SalesforceConnectorError occured.}
    public function createAccount(json accountRecord) returns (string|SalesforceConnectorError);

    documentation {Deletes existing Account's records
        P{{accountId}} Account ID
        R{{}} true if successful false otherwise, or SalesforceConnectorError occured.}
    public function deleteAccount(string accountId) returns (boolean|SalesforceConnectorError);

    documentation {Updates existing Account object record
        P{{accountId}} Account ID
        P{{accountRecord}} Json record
        R{{}} true if successful, false otherwise or SalesforceConnectorError occured.}
    public function updateAccount(string accountId, json accountRecord) returns (boolean|SalesforceConnectorError);

    //Lead
    documentation {Accesses Lead SObject records based on the Lead object ID
        P{{leadId}} Lead ID
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getLeadById(string leadId) returns (json|SalesforceConnectorError);

    documentation {Creates new Lead object record
        P{{leadRecord}} lead JSON record to be inserted
        R{{}} string lead ID result if successful else SalesforceConnectorError occured.}
    public function createLead(json leadRecord) returns (string|SalesforceConnectorError);

    documentation {Deletes existing Lead's records
        P{{leadId}} Lead ID
        R{{}} true  if successful, flase otherwise or SalesforceConnectorError occured.}
    public function deleteLead(string leadId) returns (boolean|SalesforceConnectorError);

    documentation {Updates existing Lead object record
        P{{leadId}} Lead ID
        P{{leadRecord}} Lead JSON record
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function updateLead(string leadId, json leadRecord) returns (boolean|SalesforceConnectorError);

    //Contact
    documentation {Accesses Contacts SObject records based on the Contact object ID
        P{{contactId}} Contact ID
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getContactById(string contactId) returns (json|SalesforceConnectorError);

    documentation {Creates new Contact object record
        P{{contactRecord}} JSON contact record
        R{{}} string ID if successful else SalesforceConnectorError occured.}
    public function createContact(json contactRecord) returns (string|SalesforceConnectorError);

    documentation {Deletes existing Contact's records
        P{{contactId}} Contact ID
        R{{}} true if successful else false, or SalesforceConnectorError occured.}
    public function deleteContact(string contactId) returns (boolean|SalesforceConnectorError);

    documentation {Updates existing Contact object record
        P{{contactId}} Contact ID
        P{{contactRecord}} JSON contact record
        R{{}} true if successful else false or SalesforceConnectorError occured.}
    public function updateContact(string contactId, json contactRecord) returns (boolean|SalesforceConnectorError);

    //Opportunity
    documentation {Accesses Opportunities SObject records based on the Opportunity object ID
        P{{opportunityId}} Opportunity ID
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getOpportunityById(string opportunityId) returns (json|SalesforceConnectorError);

    documentation {Creates new Opportunity object record
        P{{opportunityRecord}} JSON opportunity record
        R{{}} Opportunity ID if successful else SalesforceConnectorError occured.}
    public function createOpportunity(json opportunityRecord) returns (string|SalesforceConnectorError);

    documentation {Deletes existing Opportunity's records
        P{{opportunityId}} Opportunity ID
        R{{}} true if successful else false or SalesforceConnectorError occured.}
    public function deleteOpportunity(string opportunityId) returns (boolean|SalesforceConnectorError);

    documentation {Updates existing Opportunity object record
        P{{opportunityId}} Opportunity ID
        R{{}} true if successful else false or SalesforceConnectorError occured.}
    public function updateOpportunity(string opportunityId, json opportunityRecord)
        returns (boolean|SalesforceConnectorError);

    //Product
    documentation {Accesses Products SObject records based on the Product object ID
        P{{productId}} Product ID
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getProductById(string productId) returns (json|SalesforceConnectorError);

    documentation {Creates new Product object record
        P{{productRecord}} JSON product record
        R{{}} Product ID if successful else SalesforceConnectorError occured.}
    public function createProduct(json productRecord) returns (string|SalesforceConnectorError);

    documentation {Deletes existing product's records
        P{{productId}} Product ID
        R{{}} true if successful else false or SalesforceConnectorError occured.}
    public function deleteProduct(string productId) returns (boolean|SalesforceConnectorError);

    documentation {Updates existing Product object record
        P{{productId}} Product ID
        P{{productRecord}} JSON product record
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function updateProduct(string productId, json productRecord) returns (boolean|SalesforceConnectorError);

    //Records
    documentation {Retrieve field values from a standard object record for a specified SObject ID
        P{{sObjectName}} SObject name value
        P{{id}} SObject id
        P{{fields}} Relevant fields
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getFieldValuesFromSObjectRecord(string sObjectName, string id, string fields)
        returns (json|SalesforceConnectorError);

    documentation {Retrieve field values from an external object record using
                    Salesforce ID or External ID
        P{{externalObjectName}} External SObject name value
        P{{id}} External SObject id
        P{{fields}} Relevant fields
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getFieldValuesFromExternalObjectRecord(string externalObjectName, string id,
    string fields)
        returns (json|SalesforceConnectorError);

    documentation {Allows to create multiple records
        P{{sObjectName}} SObject name value
        P{{records}} JSON records
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function createMultipleRecords(string sObjectName, json records)
        returns (json|SalesforceConnectorError);

    documentation {Accesses records based on the value of a specified external ID field
        P{{sObjectName}} SObject name value
        P{{fieldName}} Relevant field name
        P{{fieldValue}} Relevant field value
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getRecordByExternalId(string sObjectName, string fieldName, string fieldValue)
        returns (json|SalesforceConnectorError);

    documentation {Creates new records or updates existing records (upserts records) based on the value of a
                    specified external ID field
        P{{sObjectName}} SObject name value
        P{{fieldId}} Field id
        P{{fieldValue}} Relevant field value
        P{{record}} JSON record
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function upsertSObjectByExternalId(string sObjectName, string fieldId,
    string fieldValue, json record)
        returns (json|SalesforceConnectorError);

    documentation {Retrieves the list of individual records that have been deleted
                    within the given timespan for the specified object
        P{{sObjectName}} SObject name value
        P{{startTime}} Start time relevant to records
        P{{endTime}} End time relevant to records
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getDeletedRecords(string sObjectName, string startTime, string endTime)
        returns (json|SalesforceConnectorError);

    documentation {Retrieves the list of individual records that have been updated (added or changed)
                    within the given timespan for the specified object
        P{{sObjectName}} SObject name value
        P{{startTime}} Start time relevant to records
        P{{endTime}} End time relevant to records
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getUpdatedRecords(string sObjectName, string startTime, string endTime)
        returns (json|SalesforceConnectorError);

    //Describe SObjects
    documentation {Lists the available objects and their metadata for your organization
                    and available to the logged-in user
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function describeAvailableObjects() returns (json|SalesforceConnectorError);

    documentation {Describes the individual metadata for the specified object
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getSObjectBasicInfo(string sobjectName) returns (json|SalesforceConnectorError);

    documentation {Completely describes the individual metadata at all levels for the specified object.
                    Can be used to retrieve the fields, URLs, and child relationships
        P{{sObjectName}} SObject name value
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function describeSObject(string sObjectName) returns (json|SalesforceConnectorError);

    documentation {Query for actions displayed in the UI, given a user, a context, device format,
                    and a record ID
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function sObjectPlatformAction() returns (json|SalesforceConnectorError);

    //Basic CURD
    documentation {Accesses records based on the specified object ID, can be used with external objects
        P{{path}} Resource path
        R{{}} Json result if successful else SalesforceConnectorError occured.}
    public function getRecord(string path) returns (json|SalesforceConnectorError);

    documentation {Create records based on relevant object type sent with json record
        P{{sObjectName}} SObject name value
        P{{record}} JSON record to be inserted
        R{{}} created entity ID if successful else SalesforceConnectorError occured.}
    public function createRecord(string sObjectName, json record) returns (string|SalesforceConnectorError);

    documentation {Update records based on relevant object id
        P{{sObjectName}} SObject name value
        P{{id}} SObject id
        P{{record}} JSON record to be updated
        R{{}} true if successful else false or SalesforceConnectorError occured.}
    public function updateRecord(string sObjectName, string id, json record)
        returns (boolean|SalesforceConnectorError);

    documentation {Delete existing records based on relevant object id
        P{{sObjectName}} SObject name value
        P{{id}} SObject id
        R{{}} true if successful else false or SalesforceConnectorError occured.}
    public function deleteRecord(string sObjectName, string id) returns (boolean|SalesforceConnectorError);
};

public function SalesforceConnector::getAvailableApiVersions() returns json|SalesforceConnectorError {
    string path = prepareUrl([BASE_PATH]);
    return self.getRecord(path);
}

public function SalesforceConnector::getResourcesByApiVersion(string apiVersion)
    returns json|SalesforceConnectorError {
    string path = prepareUrl([BASE_PATH, apiVersion]);
    return self.getRecord(path);
}

public function SalesforceConnector::getOrganizationLimits()
    returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, LIMITS]);
    return self.getRecord(path);
}

//=============================== Query =======================================//

public function SalesforceConnector::getQueryResult(string receivedQuery)
    returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, QUERY], [Q], [receivedQuery]);
    return self.getRecord(path);
}

public function SalesforceConnector::getNextQueryResult(string nextRecordsUrl)
    returns json|SalesforceConnectorError {
    return self.getRecord(nextRecordsUrl);
}

public function SalesforceConnector::getAllQueries(string queryString)
    returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, QUERYALL], [Q], [queryString]);
    return self.getRecord(path);
}

public function SalesforceConnector::explainQueryOrReportOrListview(string queryReportOrListview)
    returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, QUERY], [EXPLAIN], [queryReportOrListview]);
    return self.getRecord(path);
}

// ================================= Search ================================ //

public function SalesforceConnector::searchSOSLString(string searchString)
    returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, SEARCH], [Q], [searchString]);
    return self.getRecord(path);
}

// ============================ ACCOUNT SObject: get, create, update, delete ===================== //

public function SalesforceConnector::getAccountById(string accountId)
    returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, ACCOUNT, accountId]);
    return self.getRecord(path);
}

public function SalesforceConnector::createAccount(json accountRecord)
    returns string|SalesforceConnectorError {
    return self.createRecord(ACCOUNT, accountRecord);
}

public function SalesforceConnector::updateAccount(string accountId, json accountRecord)
    returns boolean|SalesforceConnectorError {
    return self.updateRecord(ACCOUNT, accountId, accountRecord);
}

public function SalesforceConnector::deleteAccount(string accountId)
    returns boolean|SalesforceConnectorError {
    return self.deleteRecord(ACCOUNT, accountId);
}

// ============================ LEAD SObject: get, create, update, delete ===================== //

public function SalesforceConnector::getLeadById(string leadId)
    returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, LEAD, leadId]);
    return self.getRecord(path);
}

public function SalesforceConnector::createLead(json leadRecord)
    returns string|SalesforceConnectorError {
    return self.createRecord(LEAD, leadRecord);

}

public function SalesforceConnector::updateLead(string leadId, json leadRecord)
    returns boolean|SalesforceConnectorError {
    return self.updateRecord(LEAD, leadId, leadRecord);
}

public function SalesforceConnector::deleteLead(string leadId)
    returns boolean|SalesforceConnectorError {
    return self.deleteRecord(LEAD, leadId);
}

// ============================ CONTACTS SObject: get, create, update, delete ===================== //

public function SalesforceConnector::getContactById(string contactId)
    returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, CONTACT, contactId]);
    return self.getRecord(path);
}

public function SalesforceConnector::createContact(json contactRecord)
    returns string|SalesforceConnectorError {
    return self.createRecord(CONTACT, contactRecord);
}

public function SalesforceConnector::updateContact(string contactId, json contactRecord)
    returns boolean|SalesforceConnectorError {
    return self.updateRecord(CONTACT, contactId, contactRecord);
}

public function SalesforceConnector::deleteContact(string contactId)
    returns boolean|SalesforceConnectorError {
    return self.deleteRecord(CONTACT, contactId);
}

// ============================ OPPORTUNITIES SObject: get, create, update, delete ===================== //

public function SalesforceConnector::getOpportunityById(string opportunityId)
    returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, OPPORTUNITY, opportunityId]);
    return self.getRecord(path);
}

public function SalesforceConnector::createOpportunity(json opportunityRecord)
    returns string|SalesforceConnectorError {
    return self.createRecord(OPPORTUNITY, opportunityRecord);
}

public function SalesforceConnector::updateOpportunity(string opportunityId, json opportunityRecord)
    returns boolean|SalesforceConnectorError {
    return self.updateRecord(OPPORTUNITY, opportunityId, opportunityRecord);
}

public function SalesforceConnector::deleteOpportunity(string opportunityId)
    returns boolean|SalesforceConnectorError {
    return self.deleteRecord(OPPORTUNITY, opportunityId);
}

// ============================ PRODUCTS SObject: get, create, update, delete ===================== //

public function SalesforceConnector::getProductById(string productId)
    returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, PRODUCT, productId]);
    return self.getRecord(path);
}

public function SalesforceConnector::createProduct(json productRecord)
    returns string|SalesforceConnectorError {
    return self.createRecord(PRODUCT, productRecord);
}

public function SalesforceConnector::updateProduct(string productId, json productRecord)
    returns boolean|SalesforceConnectorError {
    return self.updateRecord(PRODUCT, productId, productRecord);
}

public function SalesforceConnector::deleteProduct(string productId)
    returns boolean|SalesforceConnectorError {
    return self.deleteRecord(PRODUCT, productId);
}

//===========================================================================================================//

public function SalesforceConnector::getFieldValuesFromSObjectRecord(string sObjectName, string id, string fields)
    returns json|SalesforceConnectorError {
    string prefixPath = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    return self.getRecord(prefixPath + QUESTION_MARK + FIELDS + EQUAL_SIGN + fields);
}

public function SalesforceConnector::getFieldValuesFromExternalObjectRecord(string externalObjectName, string id, string fields)
    returns json|SalesforceConnectorError {
    string prefixPath = prepareUrl([API_BASE_PATH, SOBJECTS, externalObjectName, id]);
    return self.getRecord(prefixPath + QUESTION_MARK + FIELDS + EQUAL_SIGN + fields);

}

public function SalesforceConnector::createMultipleRecords(string sObjectName, json records)
    returns json|SalesforceConnectorError {
    endpoint http:Client httpClient = self.httpClient;

    json payload;
    http:Request req = new;
    string path = string `{{API_BASE_PATH}}/{{MULTIPLE_RECORDS}}/{{sObjectName}}`;
    req.setJsonPayload(records);

    http:Response|error response = httpClient -> post(path, request = req);

    return checkAndSetErrors(response, true);
}

// ============================ Create, update, delete records by External IDs ===================== //

public function SalesforceConnector::getRecordByExternalId(string sObjectName, string fieldName, string fieldValue)
    returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, fieldName, fieldValue]);
    return self.getRecord(path);
}

public function SalesforceConnector::upsertSObjectByExternalId(string sObjectName, string fieldId, string fieldValue, json record)
    returns json|SalesforceConnectorError {
    endpoint http:Client httpClient = self.httpClient;
    json payload;
    http:Request req = new;
    string path = string `{{API_BASE_PATH}}/{{SOBJECTS}}/{{sObjectName}}/{{fieldId}}/{{fieldValue}}`;
    req.setJsonPayload(record);

    http:Response|error response = httpClient -> patch(path, request = req);

    return checkAndSetErrors(response, false);
}

// ============================ Get updated and deleted records ===================== //

public function SalesforceConnector::getDeletedRecords(string sObjectName, string startTime, string endTime)
    returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, SOBJECTS, sObjectName, DELETED], [START, END], [startTime, endTime]);
    return self.getRecord(path);
}

public function SalesforceConnector::getUpdatedRecords(string sObjectName, string startTime, string endTime)
    returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, SOBJECTS, sObjectName, UPDATED], [START, END], [startTime, endTime]);
    return self.getRecord(path);
}

// ============================ Describe SObjects available and their fields/metadata ===================== //

public function SalesforceConnector::describeAvailableObjects() returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS]);
    return self.getRecord(path);
}

public function SalesforceConnector::getSObjectBasicInfo(string sobjectName)
    returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName]);
    return self.getRecord(path);
}

public function SalesforceConnector::describeSObject(string sObjectName)
    returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DESCRIBE]);
    return self.getRecord(path);
}

public function SalesforceConnector::sObjectPlatformAction() returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, PLATFORM_ACTION]);
    return self.getRecord(path);
}

//============================ utility functions================================//

public function SalesforceConnector::getRecord(string path)
    returns json|SalesforceConnectorError {
    endpoint http:Client httpClient = self.httpClient;

    http:Response|error response = httpClient -> get(path);

    return checkAndSetErrors(response, true);
}

public function SalesforceConnector::createRecord(string sObjectName, json record)
    returns string|SalesforceConnectorError {
    endpoint http:Client httpClient = self.httpClient;

    http:Request req = new;
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
    req.setJsonPayload(record);

    http:Response|error response = httpClient -> post(path, request = req);

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

public function SalesforceConnector::updateRecord(string sObjectName, string id, json record)
    returns boolean|SalesforceConnectorError {
    endpoint http:Client httpClient = self.httpClient;
    http:Request req = new;
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    req.setJsonPayload(record);

    http:Response|error response = httpClient -> patch(path, request = req);

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

public function SalesforceConnector::deleteRecord(string sObjectName, string id)
    returns boolean|SalesforceConnectorError {
    endpoint http:Client httpClient = self.httpClient;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);

    http:Response|error response = httpClient -> delete(path);

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
