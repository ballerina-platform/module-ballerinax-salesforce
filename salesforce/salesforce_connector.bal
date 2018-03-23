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

package salesforce;

import ballerina/net.http;
import ballerina/mime;
import ballerina/io;

@Description {value:"Salesforce Client Connector"}
public struct SalesforceConnector {
    OAuth2Client oauth2;
}

public function <SalesforceConnector sfConnector> init (string baseUrl, string accessToken, string refreshToken,
                                                        string clientId, string clientSecret, string refreshTokenEP, string refreshTokenPath) {
    sfConnector.oauth2 = {};
    sfConnector.oauth2.init(baseUrl, accessToken, refreshToken,
                            clientId, clientSecret, refreshTokenEP, refreshTokenPath);
}

@Description {value:"Lists summary details about each REST API version available"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getAvailableApiVersions () returns json {
    json response;

    string path = prepareUrl([BASE_PATH]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Lists the resources available for the specified API version"}
@Param {value:"apiVersion: relevant API version for the organisation"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getResourcesByApiVersion (string apiVersion) returns json {

    json response;
    string path = prepareUrl([BASE_PATH, apiVersion]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}


@Description {value:"Lists limits information for your organization"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getOrganizationLimits () returns json {
    json response;

    string path = prepareUrl([API_BASE_PATH, LIMITS]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

//=============================== Query =======================================//

@Description {value:"Executes the specified SOQL query"}
@Param {value:"query: The request SOQL query"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getQueryResult (string receivedQuery) returns json {
    json response;

    string path = prepareQueryUrl([API_BASE_PATH, QUERY], [Q], [receivedQuery]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"If the query results are too large, retrieve the next batch of results using nextRecordUrl"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getNextQueryResult (string nextRecordsUrl) returns json {
    json response;

    try {
        response = sfConnector.getRecord(nextRecordsUrl);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Returns records that have been deleted because of a merge or delete, archived Task
     and Event records"}
@Param {value:"queryString: The request SOQL query"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getAllQueries (string queryString) returns json {
    json response;

    string path = prepareQueryUrl([API_BASE_PATH, QUERYALL], [Q], [queryString]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Get feedback on how Salesforce will execute the query, report, or list view based on performance"}
@Param {value:"queryReportOrListview: The parameter to get feedback on"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> explainQueryOrReportOrListview (string queryReportOrListview) returns json {
    json response;

    string path = prepareQueryUrl([API_BASE_PATH, QUERY], [EXPLAIN], [queryReportOrListview]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

// ================================= Search ================================ //

@Description {value:"Executes the specified SOSL search"}
@Param {value:"searchString: The request SOSL string"}
@Return {value:"returns results in SearchResult struct"}
@Return {value:"Error occured"}
public function <SalesforceConnector sfConnector> searchSOSLString (string searchString) returns json {
    json response;

    string path = prepareQueryUrl([API_BASE_PATH, SEARCH], [Q], [searchString]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

// ============================ ACCOUNT SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Account SObject records based on the Account object ID"}
@Param {value:"accountId: The relevant account's id"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getAccountById (string accountId) returns json {
    json response;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, ACCOUNT, accountId]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Creates new Account object record"}
@Param {value:"accountRecord: json payload containing Account record data"}
@Return {value:"ID of the account"}
public function <SalesforceConnector sfConnector> createAccount (json accountRecord) returns string {
    string response;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, ACCOUNT]);
    try {
        response = sfConnector.createRecord(ACCOUNT, accountRecord);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Updates existing Account object record"}
@Param {value:"accountId: Specified account id"}
@Param {value:"accountRecord: json payload containing Account record data"}
@Return {value:"True if success, false otherwise"}
public function <SalesforceConnector sfConnector> updateAccount (string accountId, json accountRecord) returns boolean {
    return sfConnector.updateRecord(ACCOUNT, accountId, accountRecord);
}

@Description {value:"Deletes existing Account's records"}
@Param {value:"accountId: The id of the relevant Account record supposed to be deleted"}
@Return {value:"True if success, false otherwise"}
public function <SalesforceConnector sfConnector> deleteAccount (string accountId) returns boolean {
    return sfConnector.deleteRecord(ACCOUNT, accountId);
}

// ============================ LEAD SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Lead SObject records based on the Lead object ID"}
@Param {value:"leadId: The relevant lead's id"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getLeadById (string leadId) returns json {
    json response;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, LEAD, leadId]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Creates new Lead object record"}
@Param {value:"leadRecord: json payload containing Lead record data"}
@Return {value:"ID of the created Lead"}
public function <SalesforceConnector sfConnector> createLead (json leadRecord) returns string {
    string response;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, LEAD]);
    try {
        response = sfConnector.createRecord(LEAD, leadRecord);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Updates existing Lead object record"}
@Param {value:"leadId: Specified lead id"}
@Param {value:"leadRecord: json payload containing Lead record data"}
@Return {value:"True if success, false otherwise"}
public function <SalesforceConnector sfConnector> updateLead (string leadId, json leadRecord) returns boolean {
    return sfConnector.updateRecord(LEAD, leadId, leadRecord);
}

@Description {value:"Deletes existing Lead's records"}
@Param {value:"leadId: The id of the relevant Lead record supposed to be deleted"}
@Return {value:"True if success, false otherwise"}
public function <SalesforceConnector sfConnector> deleteLead (string leadId) returns boolean {
    return sfConnector.deleteRecord(LEAD, leadId);
}

// ============================ CONTACTS SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Contacts SObject records based on the Contact object ID"}
@Param {value:"contactId: The relevant contact's id"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getContactById (string contactId) returns json {
    json response;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, CONTACT, contactId]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Creates new Contact object record"}
@Param {value:"contactRecord: json payload containing Contact record data"}
@Return {value:"ID of the created Contact"}
public function <SalesforceConnector sfConnector> createContact (json contactRecord) returns string {
    string response;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, CONTACT]);
    try {
        response = sfConnector.createRecord(CONTACT, contactRecord);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Updates existing Contact object record"}
@Param {value:"contactId: Specified contact id"}
@Param {value:"contactRecord: json payload containing contact record data"}
@Return {value:"True if success, false otherwise"}
public function <SalesforceConnector sfConnector> updateContact (string contactId, json contactRecord) returns boolean {
    return sfConnector.updateRecord(CONTACT, contactId, contactRecord);
}

@Description {value:"Deletes existing Contact's records"}
@Param {value:"contactId: The id of the relevant Contact record supposed to be deleted"}
@Return {value:"True if success, false otherwise"}
public function <SalesforceConnector sfConnector> deleteContact (string contactId) returns boolean {
    return sfConnector.deleteRecord(CONTACT, contactId);
}

// ============================ OPPORTUNITIES SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Opportunities SObject records based on the Opportunity object ID"}
@Param {value:"opportunityId: The relevant opportunity's id"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getOpportunityById (string opportunityId) returns json {
    json response;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, OPPORTUNITY, opportunityId]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Creates new Opportunity object record"}
@Param {value:"opportunityRecord: json payload containing Opportunity record data"}
@Return {value:"ID of the create Opportunity"}
public function <SalesforceConnector sfConnector> createOpportunity (json opportunityRecord) returns string {
    string response;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, OPPORTUNITY]);
    try {
        response = sfConnector.createRecord(OPPORTUNITY, opportunityRecord);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Updates existing Opportunity object record"}
@Param {value:"opportunityId: Specified opportunity id"}
@Param {value:"opportunityRecord: json payload containing Opportunity record data"}
@Return {value:"True if success, false otherwise"}
public function <SalesforceConnector sfConnector> updateOpportunity (string opportunityId, json opportunityRecord) returns boolean {
    return sfConnector.updateRecord(OPPORTUNITY, opportunityId, opportunityRecord);
}

@Description {value:"Deletes existing Opportunity's records"}
@Param {value:"opportunityId: The id of the relevant Opportunity record supposed to be deleted"}
@Return {value:"True if success, false otherwise"}
public function <SalesforceConnector sfConnector> deleteOpportunity (string opportunityId) returns boolean {
    return sfConnector.deleteRecord(OPPORTUNITY, opportunityId);
}

// ============================ PRODUCTS SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Products SObject records based on the Product object ID"}
@Param {value:"productId: The relevant product's id"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getProductById (string productId) returns json {
    json response;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, PRODUCT, productId]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}
@Description {value:"Creates new Product object record"}
@Param {value:"productRecord: json payload containing Product record data"}
@Return {value:"ID of the created Product"}
public function <SalesforceConnector sfConnector> createProduct (json productRecord) returns string {
    string response;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, PRODUCT]);
    try {
        response = sfConnector.createRecord(PRODUCT, productRecord);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Updates existing Product object record"}
@Param {value:"productId: Specified product id"}
@Param {value:"productRecord: json payload containing product record data"}
@Return {value:"True if success, false otherwise"}
public function <SalesforceConnector sfConnector> updateProduct (string productId, json productRecord) returns boolean {
    return sfConnector.updateRecord(PRODUCT, productId, productRecord);
}

@Description {value:"Deletes existing product's records"}
@Param {value:"productId: The id of the relevant Product record supposed to be deleted"}
@Return {value:"True if success, false otherwise"}
public function <SalesforceConnector sfConnector> deleteProduct (string productId) returns boolean {
    return sfConnector.deleteRecord(PRODUCT, productId);
}

//===========================================================================================================//

@Description {value:"Retrieve field values from a standard object record for a specified SObject ID"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"id: The row ID of the required record"}
@Param {value:"fields: The comma separated set of required fields"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getFieldValuesFromSObjectRecord (string sObjectName, string id, string fields) returns json {
    json response;

    string path = ([API_BASE_PATH, SOBJECTS, sObjectName, id], [FIELDS], [fields]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Retrieve field values from an external object record using Salesforce ID or External ID"}
@Param {value:"externalObjectName: The relevant sobject name"}
@Param {value:"id: The row ID of the required record"}
@Param {value:"fields: The comma separated set of required fields"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getFieldValuesFromExternalObjectRecord (string externalObjectName, string id, string fields)
returns json {
    json response;

    string path = prepareQueryUrl([API_BASE_PATH, SOBJECTS, externalObjectName, id], [FIELDS], [fields]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Allows to create multiple records"}
@Param {value:"sObjectName: The relevant sobject name"}
@Param {value:"payload: json payload containing record data"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> createMultipleRecords (string sObjectName, json payload) returns json {
    error Error = {};
    json jsonResult;
    http:Request request = {};

    string path = string `{{API_BASE_PATH}}/{{MULTIPLE_RECORDS}}/{{sObjectName}}`;
    request.setJsonPayload(payload);

    var oauth2Response = sfConnector.oauth2.post(path, request);
    match oauth2Response {
        http:HttpConnectorError conError => {
            Error = {message:conError.message};
            throw Error;
        }
        http:Response result => {
            var jsonPayload = result.getJsonPayload();
            match jsonPayload {
                mime:EntityError entityError => {
                    Error = {message:entityError.message};
                    throw Error;
                }
                json jsonRes => {
                    jsonResult = jsonRes;
                }
            }
        }
    }
    return jsonResult;
}

// ============================ Create, update, delete records by External IDs ===================== //

@Description {value:"Accesses records based on the value of a specified external ID field"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"fieldName: The external field name"}
@Param {value:"fieldValue: The external field value"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getRecordByExternalId (string sObjectName, string fieldName, string fieldValue) returns json {
    json response;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, fieldName, fieldValue]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Creates new records or updates existing records (upserts records) based on the value of a
     specified external ID field"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"fieldId: The external field id"}
@Param {value:"fieldValue: The external field value"}
@Param {value:"record: json payload containing record data"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> upsertSObjectByExternalId (string sObjectName, string fieldId, string fieldValue, json record) returns json {
    error Error = {};
    json jsonResult;
    http:Request request = {};
    string path = string `{{API_BASE_PATH}}/{{SOBJECTS}}/{{sObjectName}}/{{fieldId}}/{{fieldValue}}`;
    request.setJsonPayload(record);

    var oauth2Response = sfConnector.oauth2.patch(path, request);
    match oauth2Response {
        http:HttpConnectorError conError => {
            Error = {message:conError.message};
            throw Error;
        }
        http:Response result => {
            var jsonPayload = result.getJsonPayload();
            match jsonPayload {
                mime:EntityError entityError => {
                    Error = {message:entityError.message};
                    throw Error;
                }
                json jsonRes => {
                    jsonResult = jsonRes;
                }
            }
        }
    }
    return jsonResult;
}

// ============================ Get updated and deleted records ===================== //

@Description {value:"Retrieves the list of individual records that have been deleted within the given timespan for the specified object"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"startTime: The start time of the time span"}
@Param {value:"endTime: The end time of the time span"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getDeletedRecords (string sObjectName, string startTime, string endTime) returns json {
    json response;

    string path = prepareQueryUrl([API_BASE_PATH, SOBJECTS, sObjectName, DELETED], [START, END], [startTime, endTime]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Retrieves the list of individual records that have been updated (added or changed) within the given timespan for the specified object"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"startTime: The start time of the time span"}
@Param {value:"endTime: The end time of the time span"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getUpdatedRecords (string sObjectName, string startTime, string endTime) returns json {
    json response;

    string path = prepareQueryUrl([API_BASE_PATH, SOBJECTS, sObjectName, UPDATED], [START, END], [startTime, endTime]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

// ============================ Describe SObjects available and their fields/metadata ===================== //

@Description {value:"Lists the available objects and their metadata for your organization and available to the logged-in user"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> describeAvailableObjects () returns json {
    json response;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Describes the individual metadata for the specified object"}
@Param {value:"sobjectName: The relevant sobject name"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> getSObjectBasicInfo (string sobjectName) returns json {
    json response;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Completely describes the individual metadata at all levels for the specified object.
                        Can be used to retrieve the fields, URLs, and child relationships"}
@Param {value:"sobjectName: The relevant sobject name"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> describeSObject (string sObjectName) returns json {
    json response;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DESCRIBE]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}

@Description {value:"Query for actions displayed in the UI, given a user, a context, device format, and a record ID"}
@Return {value:"Json result"}
public function <SalesforceConnector sfConnector> sObjectPlatformAction () returns json {
    json response;

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, PLATFORM_ACTION]);
    try {
        response = sfConnector.getRecord(path);
    }
    catch (error Error) {
        throw Error;
    }
    return response;
}


