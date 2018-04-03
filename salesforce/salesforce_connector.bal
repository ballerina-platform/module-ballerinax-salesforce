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
import wso2/oauth2;

@Description {value:"Salesforce Client Connector"}
public struct SalesforceConnector {
    oauth2:OAuth2Connector oauth2;
}

@Description {value:"Lists summary details about each REST API version available"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getAvailableApiVersions ()
returns json|SalesforceConnectorError {
    string path = prepareUrl([BASE_PATH]);
    return sfConnector.getRecord(path);
}

@Description {value:"Lists the resources available for the specified API version"}
@Param {value:"apiVersion: relevant API version for the organisation"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getResourcesByApiVersion (string apiVersion)
returns json|SalesforceConnectorError {
    string path = prepareUrl([BASE_PATH, apiVersion]);
    return sfConnector.getRecord(path);
}


@Description {value:"Lists limits information for your organization"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getOrganizationLimits ()
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, LIMITS]);
    return sfConnector.getRecord(path);
}

//=============================== Query =======================================//

@Description {value:"Executes the specified SOQL query"}
@Param {value:"query: The request SOQL query"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getQueryResult (string receivedQuery)
returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, QUERY], [Q], [receivedQuery]);
    return sfConnector.getRecord(path);
}

@Description {value:"If the query results are too large, retrieve the next batch of results using nextRecordUrl"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getNextQueryResult (string nextRecordsUrl)
returns json|SalesforceConnectorError {
    return sfConnector.getRecord(nextRecordsUrl);
}

@Description {value:"Returns records that have been deleted because of a merge or delete, archived Task
     and Event records"}
@Param {value:"queryString: The request SOQL query"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getAllQueries (string queryString)
returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, QUERYALL], [Q], [queryString]);
    return sfConnector.getRecord(path);
}

@Description {value:"Get feedback on how Salesforce will execute the query, report, or list view based on performance"}
@Param {value:"queryReportOrListview: The parameter to get feedback on"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> explainQueryOrReportOrListview (string queryReportOrListview)
returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, QUERY], [EXPLAIN], [queryReportOrListview]);
    return sfConnector.getRecord(path);
}

// ================================= Search ================================ //

@Description {value:"Executes the specified SOSL search"}
@Param {value:"searchString: The request SOSL string"}
@Return {value:"Json result  or Error occured."}
public function <SalesforceConnector sfConnector> searchSOSLString (string searchString)
returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, SEARCH], [Q], [searchString]);
    return sfConnector.getRecord(path);
}

// ============================ ACCOUNT SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Account SObject records based on the Account object ID"}
@Param {value:"accountId: The relevant account's id"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getAccountById (string accountId)
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, ACCOUNT, accountId]);
    return sfConnector.getRecord(path);
}

@Description {value:"Creates new Account object record"}
@Param {value:"accountRecord: json payload containing Account record data"}
@Return {value:"ID of the account or Error occured."}
public function <SalesforceConnector sfConnector> createAccount (json accountRecord)
returns string|SalesforceConnectorError {
    return sfConnector.createRecord(ACCOUNT, accountRecord);
}

@Description {value:"Updates existing Account object record"}
@Param {value:"accountId: Specified account id"}
@Param {value:"accountRecord: json payload containing Account record data"}
@Return {value:"boolean:true if success, false otherwise or Error occured."}
public function <SalesforceConnector sfConnector> updateAccount (string accountId, json accountRecord)
returns boolean|SalesforceConnectorError {
    return sfConnector.updateRecord(ACCOUNT, accountId, accountRecord);
}

@Description {value:"Deletes existing Account's records"}
@Param {value:"accountId: The id of the relevant Account record supposed to be deleted"}
@Return {value:"boolean:true if success, false otherwise or Error occured."}
public function <SalesforceConnector sfConnector> deleteAccount (string accountId)
returns boolean|SalesforceConnectorError {
    return sfConnector.deleteRecord(ACCOUNT, accountId);
}

// ============================ LEAD SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Lead SObject records based on the Lead object ID"}
@Param {value:"leadId: The relevant lead's id"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getLeadById (string leadId)
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, LEAD, leadId]);
    return sfConnector.getRecord(path);
}

@Description {value:"Creates new Lead object record"}
@Param {value:"leadRecord: json payload containing Lead record data"}
@Return {value:"ID of the created Lead or Error occured."}
public function <SalesforceConnector sfConnector> createLead (json leadRecord)
returns string|SalesforceConnectorError {
    return sfConnector.createRecord(LEAD, leadRecord);

}

@Description {value:"Updates existing Lead object record"}
@Param {value:"leadId: Specified lead id"}
@Param {value:"leadRecord: json payload containing Lead record data"}
@Return {value:"boolean:true if success, false otherwise or Error occured."}
public function <SalesforceConnector sfConnector> updateLead (string leadId, json leadRecord)
returns boolean|SalesforceConnectorError {
    return sfConnector.updateRecord(LEAD, leadId, leadRecord);
}

@Description {value:"Deletes existing Lead's records"}
@Param {value:"leadId: The id of the relevant Lead record supposed to be deleted"}
@Return {value:"boolean:true if success, false otherwise or Error occured."}
public function <SalesforceConnector sfConnector> deleteLead (string leadId)
returns boolean|SalesforceConnectorError {
    return sfConnector.deleteRecord(LEAD, leadId);
}

// ============================ CONTACTS SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Contacts SObject records based on the Contact object ID"}
@Param {value:"contactId: The relevant contact's id"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getContactById (string contactId)
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, CONTACT, contactId]);
    return sfConnector.getRecord(path);
}

@Description {value:"Creates new Contact object record"}
@Param {value:"contactRecord: json payload containing Contact record data"}
@Return {value:"ID of the created Contact or Error occured."}
public function <SalesforceConnector sfConnector> createContact (json contactRecord)
returns string|SalesforceConnectorError {
    return sfConnector.createRecord(CONTACT, contactRecord);
}

@Description {value:"Updates existing Contact object record"}
@Param {value:"contactId: Specified contact id"}
@Param {value:"contactRecord: json payload containing contact record data"}
@Return {value:"boolean:true if success, false otherwise or Error occured."}
public function <SalesforceConnector sfConnector> updateContact (string contactId, json contactRecord)
returns boolean|SalesforceConnectorError {
    return sfConnector.updateRecord(CONTACT, contactId, contactRecord);
}

@Description {value:"Deletes existing Contact's records"}
@Param {value:"contactId: The id of the relevant Contact record supposed to be deleted"}
@Return {value:"boolean:true if success, false otherwise or Error occured."}
public function <SalesforceConnector sfConnector> deleteContact (string contactId)
returns boolean|SalesforceConnectorError {
    return sfConnector.deleteRecord(CONTACT, contactId);
}

// ============================ OPPORTUNITIES SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Opportunities SObject records based on the Opportunity object ID"}
@Param {value:"opportunityId: The relevant opportunity's id"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getOpportunityById (string opportunityId)
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, OPPORTUNITY, opportunityId]);
    return sfConnector.getRecord(path);
}

@Description {value:"Creates new Opportunity object record"}
@Param {value:"opportunityRecord: json payload containing Opportunity record data"}
@Return {value:"ID of the create Opportunity or Error occured."}
public function <SalesforceConnector sfConnector> createOpportunity (json opportunityRecord)
returns string|SalesforceConnectorError {
    return sfConnector.createRecord(OPPORTUNITY, opportunityRecord);
}

@Description {value:"Updates existing Opportunity object record"}
@Param {value:"opportunityId: Specified opportunity id"}
@Param {value:"opportunityRecord: json payload containing Opportunity record data"}
@Return {value:"boolean:true if success, false otherwise or Error occured."}
public function <SalesforceConnector sfConnector> updateOpportunity (string opportunityId, json opportunityRecord)
returns boolean|SalesforceConnectorError {
    return sfConnector.updateRecord(OPPORTUNITY, opportunityId, opportunityRecord);
}

@Description {value:"Deletes existing Opportunity's records"}
@Param {value:"opportunityId: The id of the relevant Opportunity record supposed to be deleted"}
@Return {value:"boolean:true if success, false otherwise or Error occured."}
public function <SalesforceConnector sfConnector> deleteOpportunity (string opportunityId)
returns boolean|SalesforceConnectorError {
    return sfConnector.deleteRecord(OPPORTUNITY, opportunityId);
}

// ============================ PRODUCTS SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Products SObject records based on the Product object ID"}
@Param {value:"productId: The relevant product's id"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getProductById (string productId)
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, PRODUCT, productId]);
    return sfConnector.getRecord(path);
}

@Description {value:"Creates new Product object record"}
@Param {value:"productRecord: json payload containing Product record data"}
@Return {value:"ID of the created Product or Error occured."}
public function <SalesforceConnector sfConnector> createProduct (json productRecord)
returns string|SalesforceConnectorError {
    return sfConnector.createRecord(PRODUCT, productRecord);
}

@Description {value:"Updates existing Product object record"}
@Param {value:"productId: Specified product id"}
@Param {value:"productRecord: json payload containing product record data"}
@Return {value:"boolean: true if success, false otherwise"}
public function <SalesforceConnector sfConnector> updateProduct (string productId, json productRecord)
returns boolean|SalesforceConnectorError {
    return sfConnector.updateRecord(PRODUCT, productId, productRecord);
}

@Description {value:"Deletes existing product's records"}
@Param {value:"productId: The id of the relevant Product record supposed to be deleted"}
@Return {value:"boolen: true if success, false otherwise or Error occured."}
public function <SalesforceConnector sfConnector> deleteProduct (string productId)
returns boolean|SalesforceConnectorError {
    return sfConnector.deleteRecord(PRODUCT, productId);
}

//===========================================================================================================//

@Description {value:"Retrieve field values from a standard object record for a specified SObject ID"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"id: The row ID of the required record"}
@Param {value:"fields: The comma separated set of required fields"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getFieldValuesFromSObjectRecord (string sObjectName, string id, string fields)
returns json|SalesforceConnectorError {
    string prefixPath = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    return sfConnector.getRecord(prefixPath + "?fields=" + fields);
}

@Description {value:"Retrieve field values from an external object record using Salesforce ID or External ID"}
@Param {value:"externalObjectName: The relevant sobject name"}
@Param {value:"id: The row ID of the required record"}
@Param {value:"fields: The comma separated set of required fields"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getFieldValuesFromExternalObjectRecord (string externalObjectName, string id, string fields)
returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, SOBJECTS, externalObjectName, id], [FIELDS], [fields]);
    return sfConnector.getRecord(path);

}

@Description {value:"Allows to create multiple records"}
@Param {value:"sObjectName: The relevant sobject name"}
@Param {value:"payload: json payload containing record data"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> createMultipleRecords (string sObjectName, json payload)
returns json|SalesforceConnectorError {
    http:Request request = {};

    string path = string `{{API_BASE_PATH}}/{{MULTIPLE_RECORDS}}/{{sObjectName}}`;
    request.setJsonPayload(payload);

    http:Response|http:HttpConnectorError response = sfConnector.oauth2.post(path, request);
    json|SalesforceConnectorError result = checkAndSetErrors(response, true);
    match result {
        json jsonResult => {
            return jsonResult;
        }
        SalesforceConnectorError err => {
            return err;
        }
    }
}

// ============================ Create, update, delete records by External IDs ===================== //

@Description {value:"Accesses records based on the value of a specified external ID field"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"fieldName: The external field name"}
@Param {value:"fieldValue: The external field value"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getRecordByExternalId (string sObjectName, string fieldName, string fieldValue)
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, fieldName, fieldValue]);
    return sfConnector.getRecord(path);
}

@Description {value:"Creates new records or updates existing records (upserts records) based on the value of a
     specified external ID field"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"fieldId: The external field id"}
@Param {value:"fieldValue: The external field value"}
@Param {value:"record: json payload containing record data"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> upsertSObjectByExternalId (string sObjectName, string fieldId, string fieldValue, json record)
returns json|SalesforceConnectorError {
    http:Request request = {};

    string path = string `{{API_BASE_PATH}}/{{SOBJECTS}}/{{sObjectName}}/{{fieldId}}/{{fieldValue}}`;
    request.setJsonPayload(record);

    http:Response|http:HttpConnectorError response = sfConnector.oauth2.patch(path, request);
    json|SalesforceConnectorError result = checkAndSetErrors(response, true);
    match result {
        json jsonResult => {
            return jsonResult;
        }
        SalesforceConnectorError err => {
            return err;
        }
    }
}

// ============================ Get updated and deleted records ===================== //

@Description {value:"Retrieves the list of individual records that have been deleted within the given timespan for the specified object"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"startTime: The start time of the time span"}
@Param {value:"endTime: The end time of the time span"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getDeletedRecords (string sObjectName, string startTime, string endTime)
returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, SOBJECTS, sObjectName, DELETED], [START, END], [startTime, endTime]);
    return sfConnector.getRecord(path);
}

@Description {value:"Retrieves the list of individual records that have been updated (added or changed) within the given timespan for the specified object"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"startTime: The start time of the time span"}
@Param {value:"endTime: The end time of the time span"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getUpdatedRecords (string sObjectName, string startTime, string endTime)
returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, SOBJECTS, sObjectName, UPDATED], [START, END], [startTime, endTime]);
    return sfConnector.getRecord(path);
}

// ============================ Describe SObjects available and their fields/metadata ===================== //

@Description {value:"Lists the available objects and their metadata for your organization and available to the logged-in user"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> describeAvailableObjects () returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS]);
    return sfConnector.getRecord(path);
}

@Description {value:"Describes the individual metadata for the specified object"}
@Param {value:"sobjectName: The relevant sobject name"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> getSObjectBasicInfo (string sobjectName)
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName]);
    return sfConnector.getRecord(path);
}

@Description {value:"Completely describes the individual metadata at all levels for the specified object.
                        Can be used to retrieve the fields, URLs, and child relationships"}
@Param {value:"sobjectName: The relevant sobject name"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> describeSObject (string sObjectName)
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DESCRIBE]);
    return sfConnector.getRecord(path);
}

@Description {value:"Query for actions displayed in the UI, given a user, a context, device format, and a record ID"}
@Return {value:"Json result or Error occured."}
public function <SalesforceConnector sfConnector> sObjectPlatformAction () returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, PLATFORM_ACTION]);
    return sfConnector.getRecord(path);
}

//==============================================================================//
//============================ utility functions================================//

@Description {value:"Accesses records based on the specified object ID, can be used with external objects "}
@Param {value:"path: relevant resource URl"}
@Return {value:"Response or Error occured."}
public function <SalesforceConnector sfConnector> getRecord (string path)
returns json|SalesforceConnectorError {
    http:Request request = {};

    http:Response|http:HttpConnectorError response = sfConnector.oauth2.get(path, request);
    return checkAndSetErrors(response, true);
}

@Description {value:"Create records based on relevant object type sent with json record"}
@Param {value:"sObjectName: relevant salesforce object name"}
@Param {value:"record: json record used to create object record"}
@Return {value:"Response or Error occured."}
public function <SalesforceConnector sfConnector> createRecord (string sObjectName, json record)
returns string|SalesforceConnectorError {
    http:Request request = {};

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
    request.setJsonPayload(record);

    http:Response|http:HttpConnectorError response = sfConnector.oauth2.post(path, request);
    json|SalesforceConnectorError result = checkAndSetErrors(response, true);
    match result {
        json jsonResponse => {
            return jsonResponse.id.toString();
        }
        SalesforceConnectorError err => {
            return err;
        }
    }
}

@Description {value:"Update records based on relevant object id"}
@Param {value:"sObjectName: relevant salesforce object name"}
@Param {value:"id: relevant salesforce object id"}
@Param {value:"record: json record used to create object record"}
@Return {value:"boolean: true if success,else false or Error occured."}
public function <SalesforceConnector sfConnector> updateRecord (string sObjectName, string id, json record)
returns boolean|SalesforceConnectorError {
    http:Request request = {};

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    request.setJsonPayload(record);

    http:Response|http:HttpConnectorError response = sfConnector.oauth2.patch(path, request);
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

@Description {value:"Delete existing records based on relevant object id"}
@Param {value:"sObjectName: relevant salesforce object name"}
@Param {value:"id: relevant salesforce object id"}
@Return {value:"boolean: true if success,else false or Error occured."}
public function <SalesforceConnector sfConnector> deleteRecord (string sObjectName, string id)
returns boolean|SalesforceConnectorError {
    http:Request request = {};

    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    http:Response|http:HttpConnectorError response = sfConnector.oauth2.delete(path, request);
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