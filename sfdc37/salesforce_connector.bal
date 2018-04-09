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
import wso2/oauth2;
import log;

@Description {value:"SalesforceConnector client connector"}
public type SalesforceConnector object {
    public {
        oauth2:Client oauth2Endpoint;
    }

    public function getAvailableApiVersions () returns (json|SalesforceConnectorError);
    public function getResourcesByApiVersion (string apiVersion) returns (json|SalesforceConnectorError);
    public function getOrganizationLimits () returns (json|SalesforceConnectorError);
    // Query
    public function getQueryResult (string receivedQuery) returns (json|SalesforceConnectorError);
    public function getNextQueryResult (string nextRecordsUrl) returns (json|SalesforceConnectorError);
    public function getAllQueries (string queryString) returns (json|SalesforceConnectorError);
    public function explainQueryOrReportOrListview (string queryReportOrListview) returns (json|SalesforceConnectorError);
    //Search
    public function searchSOSLString (string searchString) returns (json|SalesforceConnectorError);
    //Account
    public function getAccountById (string accountId) returns (json|SalesforceConnectorError);
    public function createAccount (json accountRecord) returns (string|SalesforceConnectorError);
    public function deleteAccount (string accountId) returns (boolean|SalesforceConnectorError);
    public function updateAccount (string accountId, json accountRecord) returns (boolean|SalesforceConnectorError);
    //Lead
    public function getLeadById (string leadId) returns (json|SalesforceConnectorError);
    public function createLead (json leadRecord) returns (string|SalesforceConnectorError);
    public function deleteLead (string leadId) returns (boolean|SalesforceConnectorError);
    public function updateLead (string leadId, json leadRecord) returns (boolean|SalesforceConnectorError);
    //Contact
    public function getContactById (string contactId) returns (json|SalesforceConnectorError);
    public function createContact (json contactRecord) returns (string|SalesforceConnectorError);
    public function deleteContact (string contactId) returns (boolean|SalesforceConnectorError);
    public function updateContact (string contactId, json contactRecord) returns (boolean|SalesforceConnectorError);
    //Opportunity
    public function getOpportunityById (string opportunityId) returns (json|SalesforceConnectorError);
    public function createOpportunity (json opportunityRecord) returns (string|SalesforceConnectorError);
    public function deleteOpportunity (string opportunityId) returns (boolean|SalesforceConnectorError);
    public function updateOpportunity (string opportunityId, json opportunityRecord) returns (boolean|SalesforceConnectorError);
    //Product
    public function getProductById (string productId) returns (json|SalesforceConnectorError);
    public function createProduct (json productRecord) returns (string|SalesforceConnectorError);
    public function deleteProduct (string productId) returns (boolean|SalesforceConnectorError);
    public function updateProduct (string productId, json productRecord) returns (boolean|SalesforceConnectorError);

    //Records
    public function getFieldValuesFromSObjectRecord (string sObjectName, string id, string fields)
                    returns (json|SalesforceConnectorError);
    public function getFieldValuesFromExternalObjectRecord (string externalObjectName, string id,
                                                            string fields)
                    returns (json|SalesforceConnectorError);
    public function createMultipleRecords (string sObjectName, json records)
                    returns (json|SalesforceConnectorError);
    public function getRecordByExternalId (string sObjectName, string fieldName, string fieldValue)
                    returns (json|SalesforceConnectorError);
    public function upsertSObjectByExternalId (string sObjectName, string fieldId,
                                               string fieldValue, json record)
                    returns (json|SalesforceConnectorError);
    public function getDeletedRecords (string sObjectName, string startTime, string endTime)
                    returns (json|SalesforceConnectorError);
    public function getUpdatedRecords (string sObjectName, string startTime, string endTime)
                    returns (json|SalesforceConnectorError);

    //Describe SObjects
    public function describeAvailableObjects () returns (json|SalesforceConnectorError);
    public function getSObjectBasicInfo (string sobjectName) returns (json|SalesforceConnectorError);
    public function describeSObject (string sObjectName) returns (json|SalesforceConnectorError);
    public function sObjectPlatformAction () returns (json|SalesforceConnectorError);

    //Basic CURD
    public function getRecord (string path) returns (json|SalesforceConnectorError);
    public function createRecord (string sObjectName, json record) returns (string|SalesforceConnectorError);
    public function updateRecord (string sObjectName, string id, json record)
                    returns (boolean|SalesforceConnectorError);
    public function deleteRecord (string sObjectName, string id) returns (boolean|SalesforceConnectorError);
};

@Description {value:"Lists summary details about each REST API version available"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getAvailableApiVersions () returns json|SalesforceConnectorError {
    string path = prepareUrl([BASE_PATH]);
    return getRecord(path);
}

@Description {value:"Lists the resources available for the specified API version"}
@Param {value:"apiVersion: relevant API version for the organisation"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getResourcesByApiVersion (string apiVersion)
returns json|SalesforceConnectorError {
    string path = prepareUrl([BASE_PATH, apiVersion]);
    return getRecord(path);
}

@Description {value:"Lists limits information for your organization"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getOrganizationLimits ()
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, LIMITS]);
    return getRecord(path);
}

//=============================== Query =======================================//

@Description {value:"Executes the specified SOQL query"}
@Param {value:"query: The request SOQL query"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getQueryResult (string receivedQuery)
returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, QUERY], [Q], [receivedQuery]);
    return getRecord(path);
}

@Description {value:"If the query results are too large, retrieve the next batch of results using nextRecordUrl"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getNextQueryResult (string nextRecordsUrl)
returns json|SalesforceConnectorError {
    return getRecord(nextRecordsUrl);
}

@Description {value:"Returns records that have been deleted because of a merge or delete, archived Task
     and Event records"}
@Param {value:"queryString: The request SOQL query"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getAllQueries (string queryString)
returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, QUERYALL], [Q], [queryString]);
    return getRecord(path);
}

@Description {value:"Get feedback on how Salesforce will execute the query, report, or list view based on performance"}
@Param {value:"queryReportOrListview: The parameter to get feedback on"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::explainQueryOrReportOrListview (string queryReportOrListview)
returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, QUERY], [EXPLAIN], [queryReportOrListview]);
    return getRecord(path);
}

// ================================= Search ================================ //

@Description {value:"Executes the specified SOSL search"}
@Param {value:"searchString: The request SOSL string"}
@Return {value:"Json result  or Error occured."}
public function SalesforceConnector::searchSOSLString (string searchString)
returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, SEARCH], [Q], [searchString]);
    return getRecord(path);
}

// ============================ ACCOUNT SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Account SObject records based on the Account object ID"}
@Param {value:"accountId: The relevant account's id"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getAccountById (string accountId)
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, ACCOUNT, accountId]);
    return getRecord(path);
}

@Description {value:"Creates new Account object record"}
@Param {value:"accountRecord: json payload containing Account record data"}
@Return {value:"ID of the account or Error occured."}
public function SalesforceConnector::createAccount (json accountRecord)
returns string|SalesforceConnectorError {
    return createRecord(ACCOUNT, accountRecord);
}

@Description {value:"Updates existing Account object record"}
@Param {value:"accountId: Specified account id"}
@Param {value:"accountRecord: json payload containing Account record data"}
@Return {value:"boolean:true if success, false otherwise or Error occured."}
public function SalesforceConnector::updateAccount (string accountId, json accountRecord)
returns boolean|SalesforceConnectorError {
    return updateRecord(ACCOUNT, accountId, accountRecord);
}

@Description {value:"Deletes existing Account's records"}
@Param {value:"accountId: The id of the relevant Account record supposed to be deleted"}
@Return {value:"boolean:true if success, false otherwise or Error occured."}
public function SalesforceConnector::deleteAccount (string accountId)
returns boolean|SalesforceConnectorError {
    return deleteRecord(ACCOUNT, accountId);
}

// ============================ LEAD SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Lead SObject records based on the Lead object ID"}
@Param {value:"leadId: The relevant lead's id"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getLeadById (string leadId)
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, LEAD, leadId]);
    return getRecord(path);
}

@Description {value:"Creates new Lead object record"}
@Param {value:"leadRecord: json payload containing Lead record data"}
@Return {value:"ID of the created Lead or Error occured."}
public function SalesforceConnector::createLead (json leadRecord)
returns string|SalesforceConnectorError {
    return createRecord(LEAD, leadRecord);

}

@Description {value:"Updates existing Lead object record"}
@Param {value:"leadId: Specified lead id"}
@Param {value:"leadRecord: json payload containing Lead record data"}
@Return {value:"boolean:true if success, false otherwise or Error occured."}
public function SalesforceConnector::updateLead (string leadId, json leadRecord)
returns boolean|SalesforceConnectorError {
    return updateRecord(LEAD, leadId, leadRecord);
}

@Description {value:"Deletes existing Lead's records"}
@Param {value:"leadId: The id of the relevant Lead record supposed to be deleted"}
@Return {value:"boolean:true if success, false otherwise or Error occured."}
public function SalesforceConnector::deleteLead (string leadId)
returns boolean|SalesforceConnectorError {
    return deleteRecord(LEAD, leadId);
}

// ============================ CONTACTS SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Contacts SObject records based on the Contact object ID"}
@Param {value:"contactId: The relevant contact's id"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getContactById (string contactId)
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, CONTACT, contactId]);
    return getRecord(path);
}

@Description {value:"Creates new Contact object record"}
@Param {value:"contactRecord: json payload containing Contact record data"}
@Return {value:"ID of the created Contact or Error occured."}
public function SalesforceConnector::createContact (json contactRecord)
returns string|SalesforceConnectorError {
    return createRecord(CONTACT, contactRecord);
}

@Description {value:"Updates existing Contact object record"}
@Param {value:"contactId: Specified contact id"}
@Param {value:"contactRecord: json payload containing contact record data"}
@Return {value:"boolean:true if success, false otherwise or Error occured."}
public function SalesforceConnector::updateContact (string contactId, json contactRecord)
returns boolean|SalesforceConnectorError {
    return updateRecord(CONTACT, contactId, contactRecord);
}

@Description {value:"Deletes existing Contact's records"}
@Param {value:"contactId: The id of the relevant Contact record supposed to be deleted"}
@Return {value:"boolean:true if success, false otherwise or Error occured."}
public function SalesforceConnector::deleteContact (string contactId)
returns boolean|SalesforceConnectorError {
    return deleteRecord(CONTACT, contactId);
}

// ============================ OPPORTUNITIES SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Opportunities SObject records based on the Opportunity object ID"}
@Param {value:"opportunityId: The relevant opportunity's id"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getOpportunityById (string opportunityId)
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, OPPORTUNITY, opportunityId]);
    return getRecord(path);
}

@Description {value:"Creates new Opportunity object record"}
@Param {value:"opportunityRecord: json payload containing Opportunity record data"}
@Return {value:"ID of the create Opportunity or Error occured."}
public function SalesforceConnector::createOpportunity (json opportunityRecord)
returns string|SalesforceConnectorError {
    return createRecord(OPPORTUNITY, opportunityRecord);
}

@Description {value:"Updates existing Opportunity object record"}
@Param {value:"opportunityId: Specified opportunity id"}
@Param {value:"opportunityRecord: json payload containing Opportunity record data"}
@Return {value:"boolean:true if success, false otherwise or Error occured."}
public function SalesforceConnector::updateOpportunity (string opportunityId, json opportunityRecord)
returns boolean|SalesforceConnectorError {
    return updateRecord(OPPORTUNITY, opportunityId, opportunityRecord);
}

@Description {value:"Deletes existing Opportunity's records"}
@Param {value:"opportunityId: The id of the relevant Opportunity record supposed to be deleted"}
@Return {value:"boolean:true if success, false otherwise or Error occured."}
public function SalesforceConnector::deleteOpportunity (string opportunityId)
returns boolean|SalesforceConnectorError {
    return deleteRecord(OPPORTUNITY, opportunityId);
}

// ============================ PRODUCTS SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Products SObject records based on the Product object ID"}
@Param {value:"productId: The relevant product's id"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getProductById (string productId)
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, PRODUCT, productId]);
    return getRecord(path);
}

@Description {value:"Creates new Product object record"}
@Param {value:"productRecord: json payload containing Product record data"}
@Return {value:"ID of the created Product or Error occured."}
public function SalesforceConnector::createProduct (json productRecord)
returns string|SalesforceConnectorError {
    return createRecord(PRODUCT, productRecord);
}

@Description {value:"Updates existing Product object record"}
@Param {value:"productId: Specified product id"}
@Param {value:"productRecord: json payload containing product record data"}
@Return {value:"boolean: true if success, false otherwise"}
public function SalesforceConnector::updateProduct (string productId, json productRecord)
returns boolean|SalesforceConnectorError {
    return updateRecord(PRODUCT, productId, productRecord);
}

@Description {value:"Deletes existing product's records"}
@Param {value:"productId: The id of the relevant Product record supposed to be deleted"}
@Return {value:"boolen: true if success, false otherwise or Error occured."}
public function SalesforceConnector::deleteProduct (string productId)
returns boolean|SalesforceConnectorError {
    return deleteRecord(PRODUCT, productId);
}

//===========================================================================================================//

@Description {value:"Retrieve field values from a standard object record for a specified SObject ID"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"id: The row ID of the required record"}
@Param {value:"fields: The comma separated set of required fields"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getFieldValuesFromSObjectRecord (string sObjectName, string id, string fields)
returns json|SalesforceConnectorError {
    string prefixPath = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    return getRecord(prefixPath + "?fields=" + fields);
}

@Description {value:"Retrieve field values from an external object record using Salesforce ID or External ID"}
@Param {value:"externalObjectName: The relevant sobject name"}
@Param {value:"id: The row ID of the required record"}
@Param {value:"fields: The comma separated set of required fields"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getFieldValuesFromExternalObjectRecord (string externalObjectName, string id, string fields)
returns json|SalesforceConnectorError {
    string prefixPath = prepareUrl([API_BASE_PATH, SOBJECTS, externalObjectName, id]);
    return getRecord(prefixPath + "?fields=" + fields);

}

@Description {value:"Allows to create multiple records"}
@Param {value:"sObjectName: The relevant sobject name"}
@Param {value:"payload: json payload containing record data"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::createMultipleRecords (string sObjectName, json records)
returns json|SalesforceConnectorError {
    endpoint oauth2:Client oauth2EP = self.oauth2Endpoint;

    json payload;
    http:Request request = new;
    string path = string `{{API_BASE_PATH}}/{{MULTIPLE_RECORDS}}/{{sObjectName}}`;
    request.setJsonPayload(records);
    try {
        var res = oauth2EP -> post(path, request);
        http:Response response = check res;

        json|SalesforceConnectorError result = checkAndSetErrors(response, true);
        match result {
            json jsonResult => {
                payload = jsonResult;
            }
            SalesforceConnectorError err => {
                return err;
            }
        }
    } catch (http:HttpConnectorError httpError) {
        SalesforceConnectorError connectorError =
        {
            messages:["Http error -> status code: " + <string>httpError.statusCode + "; message: " + httpError.message],
            errors:httpError.cause
        };
        return connectorError;
    }

    return payload;
}

// ============================ Create, update, delete records by External IDs ===================== //

@Description {value:"Accesses records based on the value of a specified external ID field"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"fieldName: The external field name"}
@Param {value:"fieldValue: The external field value"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getRecordByExternalId (string sObjectName, string fieldName, string fieldValue)
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, fieldName, fieldValue]);
    return getRecord(path);
}

@Description {value:"Creates new records or updates existing records (upserts records) based on the value of a
     specified external ID field"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"fieldId: The external field id"}
@Param {value:"fieldValue: The external field value"}
@Param {value:"record: json payload containing record data"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::upsertSObjectByExternalId (string sObjectName, string fieldId, string fieldValue, json record)
returns json|SalesforceConnectorError {
    endpoint oauth2:Client oauth2EP = self.oauth2Endpoint;
    json payload;
    http:Request request = new;
    string path = string `{{API_BASE_PATH}}/{{SOBJECTS}}/{{sObjectName}}/{{fieldId}}/{{fieldValue}}`;
    request.setJsonPayload(record);
    try {
        var res = oauth2EP -> patch(path, request);
        http:Response response = check res;
        json|SalesforceConnectorError result = checkAndSetErrors(response, false);
        match result {
            json jsonResult => {
                payload = jsonResult;
            }
            SalesforceConnectorError err => {
                return err;
            }
        }
    } catch (http:HttpConnectorError httpError) {
        SalesforceConnectorError connectorError =
        {
            messages:["Http error -> status code: " + <string>httpError.statusCode + "; message: " + httpError.message],
            errors:httpError.cause
        };
        return connectorError;
    }

    return payload;
}

// ============================ Get updated and deleted records ===================== //

@Description {value:"Retrieves the list of individual records that have been deleted within the given timespan for the specified object"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"startTime: The start time of the time span"}
@Param {value:"endTime: The end time of the time span"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getDeletedRecords (string sObjectName, string startTime, string endTime)
returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, SOBJECTS, sObjectName, DELETED], [START, END], [startTime, endTime]);
    return getRecord(path);
}

@Description {value:"Retrieves the list of individual records that have been updated (added or changed) within the given timespan for the specified object"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"startTime: The start time of the time span"}
@Param {value:"endTime: The end time of the time span"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getUpdatedRecords (string sObjectName, string startTime, string endTime)
returns json|SalesforceConnectorError {
    string path = prepareQueryUrl([API_BASE_PATH, SOBJECTS, sObjectName, UPDATED], [START, END], [startTime, endTime]);
    return getRecord(path);
}

// ============================ Describe SObjects available and their fields/metadata ===================== //

@Description {value:"Lists the available objects and their metadata for your organization and available to the logged-in user"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::describeAvailableObjects () returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS]);
    return getRecord(path);
}

@Description {value:"Describes the individual metadata for the specified object"}
@Param {value:"sobjectName: The relevant sobject name"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::getSObjectBasicInfo (string sobjectName)
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName]);
    return getRecord(path);
}

@Description {value:"Completely describes the individual metadata at all levels for the specified object.
                        Can be used to retrieve the fields, URLs, and child relationships"}
@Param {value:"sobjectName: The relevant sobject name"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::describeSObject (string sObjectName)
returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DESCRIBE]);
    return getRecord(path);
}

@Description {value:"Query for actions displayed in the UI, given a user, a context, device format, and a record ID"}
@Return {value:"Json result or Error occured."}
public function SalesforceConnector::sObjectPlatformAction () returns json|SalesforceConnectorError {
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, PLATFORM_ACTION]);
    return getRecord(path);
}

//============================ utility functions================================//

@Description {value:"Accesses records based on the specified object ID, can be used with external objects "}
@Param {value:"path: relevant resource URl"}
@Return {value:"Response or Error occured."}
public function SalesforceConnector::getRecord (string path)
returns json|SalesforceConnectorError {
    endpoint oauth2:Client oauth2EP = self.oauth2Endpoint;

    json payload;
    http:Request request = new;
    try {
        var res = oauth2EP -> get(path, request);
        http:Response response = check res;

        json|SalesforceConnectorError result = checkAndSetErrors(response, true);
        match result {
            json jsonResult => {
                payload = jsonResult;
            }
            SalesforceConnectorError err => {
                return err;
            }
        }
    } catch (http:HttpConnectorError httpError) {
        SalesforceConnectorError connectorError =
        {
            messages:["Http error -> status code: " + <string>httpError.statusCode + "; message: " + httpError.message],
            errors:httpError.cause
        };
        return connectorError;
    }

    return payload;
}

@Description {value:"Create records based on relevant object type sent with json record"}
@Param {value:"sObjectName: relevant salesforce object name"}
@Param {value:"record: json record used to create object record"}
@Return {value:"Response or Error occured."}
public function SalesforceConnector::createRecord (string sObjectName, json record)
returns string|SalesforceConnectorError {
    endpoint oauth2:Client oauth2EP = self.oauth2Endpoint;

    string id;
    http:Request request = new;
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
    request.setJsonPayload(record);
    try {
        var res = oauth2EP -> post(path, request);
        http:Response response = check res;

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
} catch (http:HttpConnectorError httpError) {
SalesforceConnectorError connectorError =
{
    messages:["Http error -> status code: " + <string>httpError.statusCode + "; message: " + httpError.message],
    errors:httpError.cause
};
return connectorError;
       }
       return id;
}

@Description {value:"Update records based on relevant object id"}
@Param {value:"sObjectName: relevant salesforce object name"}
@Param {value:"id: relevant salesforce object id"}
@Param {value:"record: json record used to create object record"}
@Return {value:"boolean: true if success,else false or Error occured."}
public function SalesforceConnector::updateRecord (string sObjectName, string id, json record)
returns boolean|SalesforceConnectorError {
    endpoint oauth2:Client oauth2EP = self.oauth2Endpoint;
    http:Request request = new;
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    request.setJsonPayload(record);
    try {
        var res = oauth2EP -> patch(path, request);
        http:Response response = check res;

        json|SalesforceConnectorError result = checkAndSetErrors(response, false);
        match result {
            json => {
                return true;
            }
            SalesforceConnectorError err => {
                return err;
            }
        }
    } catch (http:HttpConnectorError httpError) {
        SalesforceConnectorError connectorError =
        {
            messages:["Http error -> status code: " + <string>httpError.statusCode + "; message: " + httpError.message],
            errors:httpError.cause
        };
        return connectorError;
    }

    return false;
}

@Description {value:"Delete existing records based on relevant object id"}
@Param {value:"sObjectName: relevant salesforce object name"}
@Param {value:"id: relevant salesforce object id"}
@Return {value:"boolean: true if success,else false or Error occured."}
public function SalesforceConnector::deleteRecord (string sObjectName, string id)
returns boolean|SalesforceConnectorError {
    endpoint oauth2:Client oauth2EP = self.oauth2Endpoint;

    http:Request request = new;
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    try {
        var res = oauth2EP -> delete(path, request);
        http:Response response = check res;

        json|SalesforceConnectorError result = checkAndSetErrors(response, false);
        match result {
            json => {
                return true;
            }
            SalesforceConnectorError err => {
                return err;
            }
        }
    } catch (http:HttpConnectorError httpError) {
        SalesforceConnectorError connectorError =
        {
            messages:["Http error -> status code: " + <string>httpError.statusCode + "; message: " + httpError.message],
            errors:httpError.cause
        };
        return connectorError;
    }

    return false;
}