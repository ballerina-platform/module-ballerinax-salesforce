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
import ballerina.mime;
import oauth2;
import ballerina.io;

@Description {value:"Salesforce Client Connector"}
public struct SalesforceConnector {
    oauth2:OAuth2Client oauth2;
}

public function <SalesforceConnector sfConnector> init (string baseUrl, string accessToken, string refreshToken,
                                                        string clientId, string clientSecret, string refreshTokenEP, string refreshTokenPath) {
    sfConnector.oauth2 = {};
    sfConnector.oauth2.init(baseUrl, accessToken, refreshToken,
                            clientId, clientSecret, refreshTokenEP, refreshTokenPath);
}

@Description {value:"Lists summary details about each REST API version available"}
@Return {value:"Array of available API versions"}
@Return {value:"Error occured"}
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
@Return {value:"response message"}
@Return {value:"Error occured "}
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

@Description {value:"Retrieve field values from a standard object record for a specified SObject ID"}
@Param {value:"sobjectName: The relevant sobject name"}
@Param {value:"rowId: The row ID of the required record"}
@Param {value:"fields: The comma separated set of required fields"}
@Return {value:"response message"}
@Return {value:"Error occured"}
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

// ============================ ACCOUNT SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Account SObject records based on the Account object ID"}
@Param {value:"accountId: The relevant account's id"}
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
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
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}

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
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
public function <SalesforceConnector sfConnector> updateAccount (string accountId, json accountRecord) returns boolean {
    return sfConnector.updateRecord(ACCOUNT, accountId, accountRecord);
}

@Description {value:"Deletes existing Account's records"}
@Param {value:"accountId: The id of the relevant Account record supposed to be deleted"}
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
public function <SalesforceConnector sfConnector> deleteAccount (string accountId) returns boolean {
    return sfConnector.deleteRecord(ACCOUNT, accountId);
}

// ============================ LEAD SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Lead SObject records based on the Lead object ID"}
@Param {value:"leadId: The relevant lead's id"}
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
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
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
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
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
public function <SalesforceConnector sfConnector> updateLead (string leadId, json leadRecord) returns boolean {
    return sfConnector.updateRecord(LEAD, leadId, leadRecord);
}

@Description {value:"Deletes existing Lead's records"}
@Param {value:"leadId: The id of the relevant Lead record supposed to be deleted"}
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
public function <SalesforceConnector sfConnector> deleteLead (string leadId) returns boolean {
    return sfConnector.deleteRecord(LEAD, leadId);
}

// ============================ CONTACTS SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Contacts SObject records based on the Contact object ID"}
@Param {value:"contactId: The relevant contact's id"}
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
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
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
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
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
public function <SalesforceConnector sfConnector> updateContact (string contactId, json contactRecord) returns boolean {
    return sfConnector.updateRecord(CONTACT, contactId, contactRecord);
}

@Description {value:"Deletes existing Contact's records"}
@Param {value:"contactId: The id of the relevant Contact record supposed to be deleted"}
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
public function <SalesforceConnector sfConnector> deleteContact (string contactId) returns boolean {
    return sfConnector.deleteRecord(CONTACT, contactId);
}

// ============================ OPPORTUNITIES SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Opportunities SObject records based on the Opportunity object ID"}
@Param {value:"opportunityId: The relevant opportunity's id"}
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
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
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
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
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
public function <SalesforceConnector sfConnector> updateOpportunity (string opportunityId, json opportunityRecord) returns boolean {
    return sfConnector.updateRecord(OPPORTUNITY, opportunityId, opportunityRecord);
}

@Description {value:"Deletes existing Opportunity's records"}
@Param {value:"opportunityId: The id of the relevant Opportunity record supposed to be deleted"}
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
public function <SalesforceConnector sfConnector> deleteOpportunity (string opportunityId) returns boolean {
    return sfConnector.deleteRecord(OPPORTUNITY, opportunityId);
}
// ============================ PRODUCTS SObject: get, create, update, delete ===================== //

@Description {value:"Accesses Products SObject records based on the Product object ID"}
@Param {value:"productId: The relevant product's id"}
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
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
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
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
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
public function <SalesforceConnector sfConnector> updateProduct (string productId, json productRecord) returns boolean {
    return sfConnector.updateRecord(PRODUCT, productId, productRecord);
}

@Description {value:"Deletes existing product's records"}
@Param {value:"productId: The id of the relevant Product record supposed to be deleted"}
@Return {value:"response message"}
@Return {value:"Error occured during oauth2 client invocation."}
public function <SalesforceConnector sfConnector> deleteProduct (string productId) returns boolean {
    return sfConnector.deleteRecord(PRODUCT, productId);
}

//=============================== Query =======================================//

@Description {value:"Executes the specified SOQL query"}
@Param {value:"query: The request SOQL query"}
@Return {value:"returns QueryResult struct"}
@Return {value:"Error occured"}
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
@Return {value:"returns QueryResult struct"}
@Return {value:"Error occured"}
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

//==============================================================================//
//============================ utility functions================================//

public function <SalesforceConnector sfConnector> getRecord (string path) returns json {
    error Error = {};
    json jsonResult;
    http:Request request = {};
    var response = sfConnector.oauth2.get(path, request);
    match response {
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

public function <SalesforceConnector sfConnector> createRecord (string sObjectName, json record) returns string {
    http:Request request = {};
    string id = "";
    error sfError = {};
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
    request.setJsonPayload(record);
    var response = sfConnector.oauth2.post(path, request);
    match response {
        http:HttpConnectorError conError => {
            sfError = {message:conError.message};
            throw sfError;
        }
        http:Response result => {
            if (result.statusCode == 200 || result.statusCode == 201 || result.statusCode == 204) {
                var jsonPayload = result.getJsonPayload();
                match jsonPayload {
                    mime:EntityError entityError => {
                        sfError = {message:entityError.message};
                        throw sfError;
                    }
                    json jsonRes => {
                        id = jsonRes.id.toString();
                    }
                }

            } else {
                sfError = {message:"Was not updated"};
                throw sfError;
            }
        }
    }
    return id;
}

public function <SalesforceConnector sfConnector> updateRecord (string sObjectName, string id, json record) returns boolean {
    http:Request request = {};
    error sfError = {};
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    request.setJsonPayload(record);
    var response = sfConnector.oauth2.patch(path, request);
    match response {
        http:HttpConnectorError conError => {
            sfError = {message:conError.message};
            throw sfError;
        }
        http:Response result => {
            if (result.statusCode == 200 || result.statusCode == 201 || result.statusCode == 204) {
                return true;
            } else {
                sfError = {message:"Was not updated"};
                throw sfError;
            }
        }
    }
    return false;
}

public function <SalesforceConnector sfConnector> deleteRecord (string sObjectName, string id) returns boolean {
    http:Request request = {};
    error sfError = {};
    string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
    var response = sfConnector.oauth2.delete(path, request);
    match response {
        http:HttpConnectorError conError => {
            sfError = {message:conError.message};
            throw sfError;
        }
        http:Response result => {
            if (result.statusCode == 200 || result.statusCode == 201 || result.statusCode == 204) {
                return true;
            } else {
                sfError = {message:"Was not deleted"};
                throw sfError;
            }
        }
    }
    return false;
}

function prepareUrl (string[] paths) returns string {
    string url = "";

    if (paths != null) {
        foreach path in paths {
            if (!path.hasPrefix("/")) {
                url = url + "/";
            }

            url = url + path;
        }
    }
    return url;
}

function prepareQueryUrl (string[] paths, string[] queryParamNames, string[] queryParamValues) returns string {

    string url = prepareUrl(paths);

    url = url + "?";
    boolean first = true;
    foreach i, name in queryParamNames {
        string value = queryParamValues[i];

        var response = uri:encode(value, ENCODING_CHARSET);
        match response {
            string encoded => {
                if (first) {
                    url = url + name + "=" + encoded;
                    first = false;
                } else {
                    url = url + "&" + name + "=" + encoded;
                }
            }
            error e => {
                log:printErrorCause("Unable to encode value: " + value, e);
                break;
            }
        }
    }

    return url;
}


