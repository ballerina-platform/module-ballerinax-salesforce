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

    documentation {Test Connector action getAvailableApiVersions
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getAvailableApiVersions() returns (json|SalesforceConnectorError);

    documentation {Test Connector action getResourcesByApiVersion
        P{{apiVersion}} API version (v37)
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getResourcesByApiVersion(string apiVersion) returns (json|SalesforceConnectorError);

    documentation {Test Connector action getOrganizationLimits
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getOrganizationLimits() returns (json|SalesforceConnectorError);

    // Query
    documentation {Test Connector action getQueryResult
        P{{receivedQuery}} sent SOQL query
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getQueryResult(string receivedQuery) returns (json|SalesforceConnectorError);

    documentation {Test Connector action getNextQueryResult
        P{{nextRecordsUrl}} url to get next query results
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getNextQueryResult(string nextRecordsUrl) returns (json|SalesforceConnectorError);

    documentation {Test Connector action getAllQueries
        P{{queryString}} sent SOQL query
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getAllQueries(string queryString) returns (json|SalesforceConnectorError);

    documentation {Test Connector action explainQueryOrReportOrListview
        P{{queryReportOrListview}} sent query
        returns Json result if successful else SalesforceConnectorError occured.}
    public function explainQueryOrReportOrListview(string queryReportOrListview)
        returns (json|SalesforceConnectorError);

    //Search
    documentation {Test Connector action searchSOSLString
        P{{searchString}} sent SOSL search query
        returns Json result if successful else SalesforceConnectorError occured.}
    public function searchSOSLString(string searchString) returns (json|SalesforceConnectorError);

    //Account
    documentation {Test Connector action getAccountById
        P{{accountId}} account ID
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getAccountById(string accountId) returns (json|SalesforceConnectorError);

    documentation {Test Connector action createAccount
        P{{accountRecord}} account JSON record to be inserted
        returns string account ID if successful else SalesforceConnectorError occured.}
    public function createAccount(json accountRecord) returns (string|SalesforceConnectorError);

    documentation {Test Connector action deleteAccount
        P{{accountId}} account ID
        returns true if successful false otherwise, or SalesforceConnectorError occured.}
    public function deleteAccount(string accountId) returns (boolean|SalesforceConnectorError);

    documentation {Test Connector action updateAccount
        P{{accountId}} account ID
        P{{accountRecord}} Json record
        returns true if successful, false otherwise or SalesforceConnectorError occured.}
    public function updateAccount(string accountId, json accountRecord) returns (boolean|SalesforceConnectorError);

    //Lead
    documentation {Test Connector action getLeadById
        P{{leadId}} lead ID
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getLeadById(string leadId) returns (json|SalesforceConnectorError);

    documentation {Test Connector action createLead
        P{{leadRecord}} lead JSON record to be inserted
        returns string lead ID result if successful else SalesforceConnectorError occured.}
    public function createLead(json leadRecord) returns (string|SalesforceConnectorError);

    documentation {Test Connector action deleteLead
        P{{leadId}} lead ID
        returns true  if successful, flase otherwise or SalesforceConnectorError occured.}
    public function deleteLead(string leadId) returns (boolean|SalesforceConnectorError);

    documentation {Test Connector action updateLead
        P{{leadId}} lead ID
        P{{leadRecord}} lead JSON record
        returns Json result if successful else SalesforceConnectorError occured.}
    public function updateLead(string leadId, json leadRecord) returns (boolean|SalesforceConnectorError);

    //Contact
    documentation {Test Connector action getContactById
        P{{contactId}} contact ID
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getContactById(string contactId) returns (json|SalesforceConnectorError);

    documentation {Test Connector action createContact
        P{{contactRecord}} JSON contact record
        returns string ID if successful else SalesforceConnectorError occured.}
    public function createContact(json contactRecord) returns (string|SalesforceConnectorError);

    documentation {Test Connector action deleteContact
        P{{contactId}} contact ID
        returns true if successful else false, or SalesforceConnectorError occured.}
    public function deleteContact(string contactId) returns (boolean|SalesforceConnectorError);

    documentation {Test Connector action updateContact
        P{{contactId}} contact ID
        P{{contactRecord}} JSON contact record
        returns true if successful else false or SalesforceConnectorError occured.}
    public function updateContact(string contactId, json contactRecord) returns (boolean|SalesforceConnectorError);

    //Opportunity
    documentation {Test Connector action getOpportunityById
        P{{opportunityId}} opportunity ID
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getOpportunityById(string opportunityId) returns (json|SalesforceConnectorError);

    documentation {Test Connector action createOpportunity
        P{{opportunityRecord}} JSON opportunity record
        returns opportunity ID if successful else SalesforceConnectorError occured.}
    public function createOpportunity(json opportunityRecord) returns (string|SalesforceConnectorError);

    documentation {Test Connector action deleteOpportunity
        P{{opportunityId}} opportunity ID
        returns true if successful else false or SalesforceConnectorError occured.}
    public function deleteOpportunity(string opportunityId) returns (boolean|SalesforceConnectorError);

    documentation {Test Connector action updateOpportunity
        P{{opportunityId}} opportunity ID
        returns true if successful else false or SalesforceConnectorError occured.}
    public function updateOpportunity(string opportunityId, json opportunityRecord)
        returns (boolean|SalesforceConnectorError);

    //Product
    documentation {Test Connector action getProductById
        P{{productId}} product ID
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getProductById(string productId) returns (json|SalesforceConnectorError);

    documentation {Test Connector action createProduct
        P{{productRecord}} JSON product record
        returns product ID if successful else SalesforceConnectorError occured.}
    public function createProduct(json productRecord) returns (string|SalesforceConnectorError);

    documentation {Test Connector action deleteProduct
        P{{productId}} product ID
        returns true if successful else false or SalesforceConnectorError occured.}
    public function deleteProduct(string productId) returns (boolean|SalesforceConnectorError);

    documentation {Test Connector action updateProduct
        P{{productId}} product ID
        P{{productRecord}} JSON product record
        returns Json result if successful else SalesforceConnectorError occured.}
    public function updateProduct(string productId, json productRecord) returns (boolean|SalesforceConnectorError);

    //Records
    documentation {Test Connector action getFieldValuesFromSObjectRecord
        P{{sObjectName}} SObject name value
        P{{id}} SObject id
        P{{fields}} relevant fields
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getFieldValuesFromSObjectRecord(string sObjectName, string id, string fields)
        returns (json|SalesforceConnectorError);

    documentation {Test Connector action getFieldValuesFromExternalObjectRecord
        P{{externalObjectName}} external SObject name value
        P{{id}} external SObject id
        P{{fields}} relevant fields
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getFieldValuesFromExternalObjectRecord(string externalObjectName, string id,
    string fields)
        returns (json|SalesforceConnectorError);

    documentation {Test Connector action createMultipleRecords
        P{{sObjectName}} SObject name value
        P{{records}} JSON records
        returns Json result if successful else SalesforceConnectorError occured.}
    public function createMultipleRecords(string sObjectName, json records)
        returns (json|SalesforceConnectorError);

    documentation {Test Connector action getRecordByExternalId
        P{{sObjectName}} SObject name value
        P{{fieldName}} relevant field name
        P{{fieldValue}} relevant field value
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getRecordByExternalId(string sObjectName, string fieldName, string fieldValue)
        returns (json|SalesforceConnectorError);

    documentation {Test Connector action upsertSObjectByExternalId
        P{{sObjectName}} SObject name value
        P{{fieldId}} field id
        P{{fieldValue}} relevant field value
        P{{record}} JSON record
        returns Json result if successful else SalesforceConnectorError occured.}
    public function upsertSObjectByExternalId(string sObjectName, string fieldId,
    string fieldValue, json record)
        returns (json|SalesforceConnectorError);

    documentation {Test Connector action getDeletedRecords
        P{{sObjectName}} SObject name value
        P{{startTime}} start time relevant to records
        P{{endTime}} end time relevant to records
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getDeletedRecords(string sObjectName, string startTime, string endTime)
        returns (json|SalesforceConnectorError);

    documentation {Test Connector action getUpdatedRecords
        P{{sObjectName}} SObject name value
        P{{startTime}} start time relevant to records
        P{{endTime}} end time relevant to records
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getUpdatedRecords(string sObjectName, string startTime, string endTime)
        returns (json|SalesforceConnectorError);

    //Describe SObjects
    documentation {Test Connector action describeAvailableObjects
        returns Json result if successful else SalesforceConnectorError occured.}
    public function describeAvailableObjects() returns (json|SalesforceConnectorError);

    documentation {Test Connector action getSObjectBasicInfo
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getSObjectBasicInfo(string sobjectName) returns (json|SalesforceConnectorError);

    documentation {Test Connector action describeSObject
        P{{sObjectName}} SObject name value
        returns Json result if successful else SalesforceConnectorError occured.}
    public function describeSObject(string sObjectName) returns (json|SalesforceConnectorError);

    documentation {Test Connector action sObjectPlatformAction
        returns Json result if successful else SalesforceConnectorError occured.}
    public function sObjectPlatformAction() returns (json|SalesforceConnectorError);

    //Basic CURD
    documentation {Test Connector action getRecord
        P{{path}} resource path
        returns Json result if successful else SalesforceConnectorError occured.}
    public function getRecord(string path) returns (json|SalesforceConnectorError);

    documentation {Test Connector action createRecord
        P{{sObjectName}} SObject name value
        P{{record}} JSON record to be inserted
        returns created entity ID if successful else SalesforceConnectorError occured.}
    public function createRecord(string sObjectName, json record) returns (string|SalesforceConnectorError);

    documentation {Test Connector action updateRecord
        P{{sObjectName}} SObject name value
        P{{id}} SObject id
        P{{record}} JSON record to be updated
        returns true if successful else false or SalesforceConnectorError occured.}
    public function updateRecord(string sObjectName, string id, json record)
        returns (boolean|SalesforceConnectorError);

    documentation {Test Connector action deleteRecord
        P{{sObjectName}} SObject name value
        P{{id}} SObject id
        returns true if successful else false or SalesforceConnectorError occured.}
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
    http:Request request = new;
    string path = string `{{API_BASE_PATH}}/{{MULTIPLE_RECORDS}}/{{sObjectName}}`;
    request.setJsonPayload(records);

    http:Response|http:HttpConnectorError response = httpClient -> post(path, request);

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
    http:Request request = new;
    string path = string `{{API_BASE_PATH}}/{{SOBJECTS}}/{{sObjectName}}/{{fieldId}}/{{fieldValue}}`;
    request.setJsonPayload(record);

    http:Response|http:HttpConnectorError response = httpClient -> patch(path, request);

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

    http:Request request = new;
    http:Response|http:HttpConnectorError response = httpClient -> get(path, request);

    return checkAndSetErrors(response, true);
}

public function SalesforceConnector::createRecord(string sObjectName, json record)
    returns string|SalesforceConnectorError {
    endpoint http:Client httpClient = self.httpClient;

    string id;
    http:Request request = new;
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
    request.setJsonPayload(record);

    http:Response|http:HttpConnectorError response = httpClient -> post(path, request);

    json|SalesforceConnectorError result = checkAndSetErrors(response, true);
    match result {
        json jsonResult => {
            var responseId = jsonResult.id.toString();
            match responseId {
                string stringId => {
                    id = stringId;
                }
                () => {
                    id = "";
                }
            }
        }
        SalesforceConnectorError err => {
            return err;
        }
    }
    return id;
}

public function SalesforceConnector::updateRecord(string sObjectName, string id, json record)
    returns boolean|SalesforceConnectorError {
    endpoint http:Client httpClient = self.httpClient;
    http:Request request = new;
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    request.setJsonPayload(record);

    http:Response|http:HttpConnectorError response = httpClient -> patch(path, request);

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

    http:Request request = new;
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);

    http:Response|http:HttpConnectorError response = httpClient -> delete(path, request);

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