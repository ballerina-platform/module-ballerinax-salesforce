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

package src.salesforce;

import ballerina.net.http;
import oauth2;
//import org.wso2.ballerina.connectors.oauth2;

oauth2:ClientConnector oauth2ConnectorInstance;
boolean isOAuth2Initialized = false;

@Description {value:"Salesforce Client connector"}
@Param {value:"baseUrl: The endpoint base url"}
@Param {value:"accessToken: The access token of the salesforce account"}
@Param {value:"clientId: The client Id of the salesforce account"}
@Param {value:"clientSecret: The client secret of the salesforce account"}
@Param {value:"refreshToken: The refresh token of the salesforce account"}
@Param {value:"refreshTokenEndpoint: The refresh token endpoint url"}
@Param {value:"refreshTokenPath: The path for obtaining a refresh token"}
public connector SalesforceConnector (string baseUrl, string accessToken, string clientId, string clientSecret, string refreshToken,
                                      string refreshTokenEndpoint, string refreshTokenPath) {

    endpoint<oauth2:ClientConnector> oauth2Connector {
        oauth2ConnectorInstance;
    }

    @Description {value:"Initialize OAuth2 Client Connector"}
    @Return {value:"Returns true if success or already exists"}
    action init () {
        if (!isOAuth2Initialized) {
            oauth2ConnectorInstance = create oauth2:ClientConnector(baseUrl, accessToken, clientId, clientSecret, refreshToken,
                                                                    refreshTokenEndpoint, refreshTokenPath);
            isOAuth2Initialized = true;
        }
    }

    @Description {value:"Lists summary details about each REST API version available"}
    @Return {value:"Array of available API versions"}
    @Return {value:"Error occured"}
   action getAvailableApiVersions () (json[], SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;
        json[] apiVersions;

        response, connectorError = sendGetRequest(prepareUrl([BASE_PATH], null, null));

        if (connectorError != null) {
            return apiVersions, connectorError;
        }

        apiVersions, _ = (json[])response;

        return apiVersions, connectorError;
    }

    @Description {value:"Lists the resources available for the specified API version"}
    @Return {value:"response message"}
    @Return {value:"Error occurred"}
    action getResourcesByApiVersion (string apiVersion) (json, SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;

        string path = prepareUrl([BASE_PATH, apiVersion], null, null);
        response, connectorError = sendGetRequest(path);

        return response, connectorError;
    }

    @Description {value:"Lists limits information for your organization"}
    @Return {value:"response message"}
    @Return {value:"Error occured "}
    action getOrganizationLimits () (json, SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;

        string path = prepareUrl([API_BASE_PATH, LIMITS], null, null);
        response, connectorError = sendGetRequest(path);

        return response, connectorError;
    }

    // ============================ Describe SObjects available and their fields/metadata ===================== //

    @Description {value:"Lists the available objects and their metadata for your organization and available to the logged-in user"}
    @Return {value:"Array of available objects"}
    @Return {value:"Error occured "}
    action describeAvailableObjects () (json, SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;

        string path = prepareUrl([API_BASE_PATH, SOBJECTS], null, null);
        response, connectorError = sendGetRequest(path);

        return response, connectorError;
    }

    @Description {value:"Describes the individual metadata for the specified object"}
    @Param {value:"sobjectName: The relevant sobject name"}
    @Return {value:"response message"}
    @Return {value:"Error occured "}
    action getSObjectBasicInfo (string sobjectName) (json, SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;

        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName], null, null);
        response, connectorError = sendGetRequest(path);

        return response, connectorError;
    }

    @Description {value:"Completely describes the individual metadata at all levels for the specified object.
                        Can be used to retrieve the fields, URLs, and child relationships"}
    @Param {value:"sobjectName: The relevant sobject name"}
    @Return {value:"response message"}
    @Return {value:"Error occured."}
    action describeSObject (string sObjectName) (json, SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;

        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DESCRIBE], null, null);
        response, connectorError = sendGetRequest(path);

        return response, connectorError;
    }

    @Description {value:"Query for actions displayed in the UI, given a user, a context, device format, and a record ID"}
    @Return {value:"response message"}
    @Return {value:"Error occured"}
    action sObjectPlatformAction () (json, SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;

        string path = prepareUrl([API_BASE_PATH, SOBJECTS, PLATFORM_ACTION], null, null);
        response, connectorError = sendGetRequest(path);

        return response, connectorError;
    }

    // ============================ Get, create, update, delete records ===================== //

    @Description {value:"Accesses records based on the specified object ID, can be used with external objects "}
    @Param {value:"sobjectName: The relevant sobject name"}
    @Return {value:"response message"}
    @Return {value:"Error occured."}
    action getRecord (string sObjectName, string id) (json, SalesforceConnectorError) {
        return getRecord(sObjectName, id);
    }

    @Description {value:"Retrieve field values from a standard object record for a specified SObject ID"}
    @Param {value:"sobjectName: The relevant sobject name"}
    @Param {value:"rowId: The row ID of the required record"}
    @Param {value:"fields: The comma separated set of required fields"}
    @Return {value:"response message"}
    @Return {value:"Error occured"}
    action getFieldValuesFromSObjectRecord (string sObjectName, string id, string fields) (json, SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;

        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id], [FIELDS], [fields]);
        response, connectorError = sendGetRequest(path);

        return response, connectorError;
    }

    @Description {value:"Retrieve field values from an external object record using Salesforce ID or External ID"}
    @Param {value:"sobjectName: The relevant sobject name"}
    @Param {value:"rowId: The row ID of the required record"}
    @Param {value:"fields: The comma separated set of required fields"}
    @Return {value:"response message"}
    @Return {value:"Error occured"}
    action getFieldValuesFromExternalObjectRecord (string externalObjectName, string id, string fields)
    (json, SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;

        string path = prepareUrl([API_BASE_PATH, SOBJECTS, externalObjectName, id], [FIELDS], [fields]);
        response, connectorError = sendGetRequest(path);
        return response, connectorError;
    }

    @Description {value:"Creates new records"}
    @Param {value:"sobjectName: The relevant sobject name"}
    @Param {value:"record: json payload containing record data"}
    @Return {value:"response message"}
    @Return {value:"Error occured."}
    action createRecord (string sObjectName, json record) (string, SalesforceConnectorError) {
        return createRecord(sObjectName, record);
    }

    @Description {value:"Updates existing records"}
    @Param {value:"sobjectName: The relevant sobject name"}
    @Param {value:"record: json payload containing record data"}
    @Return {value:"response message"}
    @Return {value:"Error occured."}
    action updateRecord (string sObjectName, string id, json record) (boolean, SalesforceConnectorError) {
        return updateRecord(sObjectName, id, record);
    }

    @Description {value:"Deletes existing records"}
    @Param {value:"sobjectName: The relevant sobject name"}
    @Param {value:"id: The id of the relevant record supposed to be deleted"}
    @Return {value:"response message"}
    @Return {value:"Error occured."}
    action deleteRecord (string sObjectName, string id) (boolean, SalesforceConnectorError) {
        return deleteRecord(sObjectName, id);
    }

    @Description {value:"Allows to create multiple records"}
    @Param {value:"sObjectName: The relevant sobject name"}
    @Param {value:"payload: json payload containing record data"}
    @Return {value:"response message"}
    @Return {value:"Error occured"}
    action createMultipleRecords (string sObjectName, json payload) (json, SalesforceConnectorError) {
        http:OutRequest request = {};
        http:InResponse response = {};
        http:HttpConnectorError err;
        SalesforceConnectorError connectorError;

        string requestURI = string `{{API_BASE_PATH}}/{{MULTIPLE_RECORDS}}/{{sObjectName}}`;
        request.setJsonPayload(payload);
        response, err = oauth2Connector.get(requestURI, request);
        connectorError = checkAndSetErrors(response, err);

        return response.getJsonPayload(), connectorError;
    }

    // ============================ Create, update, delete records by External IDs ===================== //

    @Description {value:"Accesses records based on the value of a specified external ID field"}
    @Param {value:"sobjectName: The relevant sobject name"}
    @Param {value:"fieldName: The external field name"}
    @Param {value:"fieldValue: The external field value"}
    @Return {value:"response message"}
    @Return {value:"Error occured"}
    action getRecordByExternalId (string sObjectName, string fieldName, string fieldValue) (json, SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;

        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, fieldName, fieldValue], null, null);
        response, connectorError = sendGetRequest(path);

        return response, connectorError;
    }

    @Description {value:"Creates new records or updates existing records (upserts records) based on the value of a
     specified external ID field"}
    @Param {value:"sobjectName: The relevant sobject name"}
    @Param {value:"fieldId: The external field id"}
    @Param {value:"fieldValue: The external field value"}
    @Param {value:"record: json payload containing record data"}
    @Return {value:"response message"}
    @Return {value:"Error occured."}
    action upsertSObjectByExternalId (string sObjectName, string fieldId, string fieldValue, json record) (json, SalesforceConnectorError) {
        http:OutRequest request = {};
        http:InResponse response = {};
        http:HttpConnectorError err;
        SalesforceConnectorError connectorError;

        string requestURI = string `{{API_BASE_PATH}}/{{SOBJECTS}}/{{sObjectName}}/{{fieldId}}/{{fieldValue}}`;
        request.setJsonPayload(record);
        response, err = oauth2Connector.patch(requestURI, request);
        connectorError = checkAndSetErrors(response, err);

        return response.getJsonPayload(), connectorError;
    }

    // ============================ Get updated and deleted records ===================== //

    @Description {value:"Retrieves the list of individual records that have been deleted within the given timespan for the specified object"}
    @Param {value:"sobjectName: The relevant sobject name"}
    @Param {value:"startTime: The start time of the time span"}
    @Param {value:"endTime: The end time of the time span"}
    @Return {value:"response message"}
    @Return {value:"Error occured."}
    action getDeletedRecords (string sObjectName, string startTime, string endTime) (json, SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;

        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DELETED], [START, END], [startTime, endTime]);
        response, connectorError = sendGetRequest(path);

        return response, connectorError;
    }

    @Description {value:"Retrieves the list of individual records that have been updated (added or changed) within the given timespan for the specified object"}
    @Param {value:"sobjectName: The relevant sobject name"}
    @Param {value:"startTime: The start time of the time span"}
    @Param {value:"endTime: The end time of the time span"}
    @Return {value:"response message"}
    @Return {value:"Error occured"}
    action getUpdatedRecords (string sObjectName, string startTime, string endTime) (json, SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;

        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, UPDATED], [START, END], [startTime, endTime]);
        response, connectorError = sendGetRequest(path);

        return response, connectorError;
    }

    // ================================= Query ================================ //

    @Description {value:"Executes the specified SOQL query"}
    @Param {value:"query: The request SOQL query"}
    @Return {value:"returns QueryResult struct"}
    @Return {value:"Error occured"}
    action query (string query) (QueryResult, SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;

        string path = prepareUrl([API_BASE_PATH, QUERY], [Q], [query]);
        response, connectorError = sendGetRequest(path);

        QueryResult result = {};

        if (connectorError != null) {
            return result, connectorError;
        }

        result.done, _ = (boolean)response.done;
        result.totalSize, _ = (int)response.totalSize;
        result.records, _ = (json[])response.records;
        if (response.nextRecordsUrl != null) {
            result.nextRecordsUrl = response.nextRecordsUrl.toString();
        } else {
            result.nextRecordsUrl = null;
        }

        // todo Use struct bound functions for this
        return result, connectorError;
    }

    @Description {value:"If the queryAll results are too large, retrieve the next batch of results using nextRecordUrl"}
    @Param {value:"nextRecordsUrl: The url sent with first batch of queryAll results to get the next batch"}
    @Return {value:"returns QueryResult struct"}
    @Return {value:"Error occured"}
    action nextQueryResult (string nextRecordsUrl) (QueryResult, SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;

        response, connectorError = sendGetRequest(nextRecordsUrl);

        QueryResult result = {};

        if (connectorError != null) {
            return result, connectorError;
        }

        result.done, _ = (boolean)response.done;
        result.totalSize, _ = (int)response.totalSize;
        result.records, _ = (json[])response.records;
        if (response.nextRecordsUrl != null) {
            result.nextRecordsUrl = response.nextRecordsUrl.toString();
        } else {
            result.nextRecordsUrl = null;
        }

        return result, connectorError;
    }

    @Description {value:"Returns records that have been deleted because of a merge or delete, archived Task
     and Event records"}
    @Param {value:"apiVersion: The api version to send request to"}
    @Param {value:"queryString: The request SOQL query"}
    @Return {value:"response message"}
    @Return {value:"Error occured."}
    action getAllQueries (string query) (QueryResult, SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;

        string path = prepareUrl([API_BASE_PATH, QUERYALL], [Q], [query]);
        response, connectorError = sendGetRequest(path);

        QueryResult result = {};

        if (connectorError != null) {
            return result, connectorError;
        }

        result.done, _ = (boolean)response.done;
        result.totalSize, _ = (int)response.totalSize;
        result.records, _ = (json[])response.records;
        if (response.nextRecordsUrl != null) {
            result.nextRecordsUrl = response.nextRecordsUrl.toString();
        } else {
            result.nextRecordsUrl = null;
        }

        return result, connectorError;
    }

    @Description {value:"Get feedback on how Salesforce will execute the query, report, or list view based on performance"}
    @Param {value:"queryReportOrListview: The parameter to get feedback on"}
    @Return {value:"response message"}
    @Return {value:"Error occured"}
    action explainQueryOrReportOrListview (string queryReportOrListview) (QueryPlan[], SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;

        string path = prepareUrl([API_BASE_PATH, QUERY], [EXPLAIN], [queryReportOrListview]);
        response, connectorError = sendGetRequest(path);

        QueryPlan[] queryPlans = [];
        if (connectorError != null) {
            return queryPlans, connectorError;
        }

        json[] plans;
        plans, _ = (json[])response.plans;

        foreach i, plan in plans {
            queryPlans[i], _ = <QueryPlan>plan;
        }

        return queryPlans, connectorError;
    }

    // ================================= Search ================================ //

    @Description {value:"Executes the specified SOSL search"}
    @Param {value:"searchString: The request SOSL string"}
    @Return {value:"returns results in SearchResult struct"}
    @Return {value:"Error occured"}
    action searchSOSLString (string searchString) (SearchResult[], SalesforceConnectorError) {
        SalesforceConnectorError connectorError;
        json response;

        string path = prepareUrl([API_BASE_PATH, SEARCH], [Q], [searchString]);
        response, connectorError = sendGetRequest(path);

        SearchResult[] searchResults = [];
        if (connectorError != null) {
            return searchResults, connectorError;
        }

        json jsonResponse = response.searchRecords;
        json[] jsonSearchResults;
        jsonSearchResults, _ = (json[])jsonResponse;

        foreach i, result in jsonSearchResults {
            searchResults[i], _ = <SearchResult>result;
        }
        return searchResults, connectorError;
    }

    // ============================ ACCOUNT SObject: get, create, update, delete ===================== //

    @Description {value:"Accesses Account SObject records based on the Account object ID"}
    @Param {value:"accountId: The relevant account's id"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action getAccountById (string accountId) (json, SalesforceConnectorError) {
        return getRecord(ACCOUNT, accountId);
    }

    @Description {value:"Creates new Account object record"}
    @Param {value:"accountRecord: json payload containing Account record data"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action createAccount (json accountRecord) (string, SalesforceConnectorError) {
        return createRecord(ACCOUNT, accountRecord);
    }

    @Description {value:"Updates existing Account object record"}
    @Param {value:"accountId: Specified account id"}
    @Param {value:"accountRecord: json payload containing Account record data"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action updateAccount (string accountId, json accountRecord) (boolean, SalesforceConnectorError) {
        return updateRecord(ACCOUNT, accountId, accountRecord);

    }

    @Description {value:"Deletes existing Account's records"}
    @Param {value:"accountId: The id of the relevant Account record supposed to be deleted"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action deleteAccount (string accountId) (boolean, SalesforceConnectorError) {
        return deleteRecord(ACCOUNT, accountId);
    }

    // ============================ LEAD SObject: get, create, update, delete ===================== //

    @Description {value:"Accesses Lead SObject records based on the Lead object ID"}
    @Param {value:"leadId: The relevant lead's id"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action getLeadById (string leadId) (json, SalesforceConnectorError) {
        return getRecord(LEAD, leadId);
    }

    @Description {value:"Creates new Lead object record"}
    @Param {value:"leadRecord: json payload containing Lead record data"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action createLead (json leadRecord) (string, SalesforceConnectorError) {
        return createRecord(LEAD, leadRecord);
    }

    @Description {value:"Updates existing Lead object record"}
    @Param {value:"leadId: Specified lead id"}
    @Param {value:"leadRecord: json payload containing Lead record data"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action updateLead (string leadId, json leadRecord) (boolean, SalesforceConnectorError) {
        return updateRecord(LEAD, leadId, leadRecord);
    }

    @Description {value:"Deletes existing Lead's records"}
    @Param {value:"leadId: The id of the relevant Lead record supposed to be deleted"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action deleteLead (string leadId) (boolean, SalesforceConnectorError) {
        return deleteRecord(LEAD, leadId);
    }

    // ============================ CONTACTS SObject: get, create, update, delete ===================== //

    @Description {value:"Accesses Contacts SObject records based on the Contact object ID"}
    @Param {value:"contactId: The relevant contact's id"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action getContactById (string contactId) (json, SalesforceConnectorError) {
        return getRecord(CONTACT, contactId);
    }

    @Description {value:"Creates new Contact object record"}
    @Param {value:"contactRecord: json payload containing Contact record data"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action createContact (json contactRecord) (string, SalesforceConnectorError) {
        return createRecord(CONTACT, contactRecord);
    }

    @Description {value:"Updates existing Contact object record"}
    @Param {value:"contactId: Specified contact id"}
    @Param {value:"contactRecord: json payload containing contact record data"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action updateContact (string contactId, json contactRecord) (boolean, SalesforceConnectorError) {
        return updateRecord(CONTACT, contactId, contactRecord);
    }

    @Description {value:"Deletes existing Contact's records"}
    @Param {value:"contactId: The id of the relevant Contact record supposed to be deleted"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action deleteContact (string contactId) (boolean, SalesforceConnectorError) {
        return deleteRecord(CONTACT, contactId);
    }

    // ============================ OPPORTUNITIES SObject: get, create, update, delete ===================== //

    @Description {value:"Accesses Opportunities SObject records based on the Opportunity object ID"}
    @Param {value:"opportunityId: The relevant opportunity's id"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action getOpportunityById (string opportunityId) (json, SalesforceConnectorError) {
        return getRecord(OPPORTUNITY, opportunityId);

    }

    @Description {value:"Creates new Opportunity object record"}
    @Param {value:"opportunityRecord: json payload containing Opportunity record data"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action createOpportunity (json opportunityRecord) (string, SalesforceConnectorError) {
        return createRecord(OPPORTUNITY, opportunityRecord);

    }

    @Description {value:"Updates existing Opportunity object record"}
    @Param {value:"opportunityId: Specified opportunity id"}
    @Param {value:"opportunityRecord: json payload containing Opportunity record data"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action updateOpportunity (string opportunityId, json opportunityRecord) (boolean, SalesforceConnectorError) {
        return updateRecord(OPPORTUNITY, opportunityId, opportunityRecord);

    }

    @Description {value:"Deletes existing Opportunity records"}
    @Param {value:"opportunityId: The id of the relevant Opportunity record supposed to be deleted"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action deleteOpportunity (string opportunityId) (boolean, SalesforceConnectorError) {
        return deleteRecord(OPPORTUNITY, opportunityId);

    }

    // ============================ PRODUCTS SObject: get, create, update, delete ===================== //

    @Description {value:"Accesses Products SObject records based on the Product object ID"}
    @Param {value:"productId: The relevant product's id"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action getProductById (string productId) (json, SalesforceConnectorError) {
        return getRecord(PRODUCT, productId);
    }

    @Description {value:"Creates new Product object record"}
    @Param {value:"productRecord: json payload containing Product record data"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action createProduct (json productRecord) (string, SalesforceConnectorError) {
        return createRecord(PRODUCT, productRecord);
    }

    @Description {value:"Updates existing Product object record"}
    @Param {value:"productId: Specified product id"}
    @Param {value:"productRecord: json payload containing product record data"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action updateProduct (string productId, json productRecord) (boolean, SalesforceConnectorError) {
        return updateRecord(PRODUCT, productId, productRecord);
    }

    @Description {value:"Deletes existing product's records"}
    @Param {value:"productId: The id of the relevant Product record supposed to be deleted"}
    @Return {value:"response message"}
    @Return {value:"Error occured during oauth2 client invocation."}
    action deleteProduct (string productId) (boolean, SalesforceConnectorError) {
        return deleteRecord(PRODUCT, productId);
    }
}