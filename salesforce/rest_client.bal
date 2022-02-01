// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;

# Ballerina Salesforce connector provides the capability to access Salesforce REST API.
# This connector lets you to perform operations for SObjects, query using SOQL, search using SOSL, and describe SObjects
# and organizational data.
@display {
    label: "Salesforce Client",
    iconPath: "icon.png"
}
public isolated client class Client {
    private final http:Client salesforceClient;
    private final http:OAuth2RefreshTokenGrantConfig|http:BearerTokenConfig clientConfig;

    # Initializes the connector. During initialization you can pass either http:BearerTokenConfig if you have a bearer
    # token or http:OAuth2RefreshTokenGrantConfig if you have Oauth tokens.
    # Create a Salesforce account and obtain tokens following 
    # [this guide](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm). 
    # 
    # + salesforceConfig - Salesforce Connector configuration
    # + return - `sfdc:Error` on failure of initialization or else `()`
    public isolated function init(ConnectionConfig salesforceConfig) returns Error? {
        self.clientConfig = salesforceConfig.clientConfig.cloneReadOnly();
        http:ClientSecureSocket? socketConfig = salesforceConfig?.secureSocketConfig;

        http:Client|http:ClientError|error httpClientResult;
        httpClientResult = trap new (salesforceConfig.baseUrl, {
            auth: salesforceConfig.clientConfig,
            secureSocket: socketConfig,
            httpVersion: salesforceConfig.httpVersion,
            http1Settings: salesforceConfig.http1Settings,
            http2Settings: salesforceConfig.http2Settings,
            timeout: salesforceConfig.timeout,
            forwarded: salesforceConfig.forwarded,
            followRedirects: salesforceConfig.followRedirects,
            poolConfig: salesforceConfig.poolConfig,
            cache: salesforceConfig.cache,
            compression: salesforceConfig.compression,
            circuitBreaker: salesforceConfig.circuitBreaker,
            retryConfig: salesforceConfig.retryConfig,
            cookieConfig: salesforceConfig.cookieConfig,
            responseLimits: salesforceConfig.responseLimits
        });

        if httpClientResult is http:Client {
            self.salesforceClient = httpClientResult;
        } else {
            return error Error(INVALID_CLIENT_CONFIG);
        }
    }

    //Describe SObjects
    # Lists the available objects and their metadata for your organization and available to the logged-in user.
    #
    # + return - `OrgMetadata` record if successful or else `sfdc:Error`
    @display {label: "Get Available Objects"}
    isolated remote function describeAvailableObjects() 
                                                      returns @tainted @display {label: "Organization Metadata"} 
                                                      OrgMetadata|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS]);
        json res = check self->getRecord(path);
        return toOrgMetadata(res);
    }

    # Describes the individual metadata for the specified object.
    #
    # + sobjectName - SObject name
    # + return - `SObjectBasicInfo` record if successful or else `sfdc:Error`
    @display {label: "Get SObject Basic Information"}
    isolated remote function getSObjectBasicInfo(@display {label: "SObject Name"} string sobjectName) 
                                                 returns @tainted @display {label: "SObject Basic Information"} 
                                                 SObjectBasicInfo|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName]);
        json res = check self->getRecord(path);
        return toSObjectBasicInfo(res);
    }

    # Completely describes the individual metadata at all levels for the specified object. Can be used to retrieve
    # the fields, URLs, and child relationships.
    #
    # + sObjectName - SObject name value
    # + return - `SObjectMetaData` record if successful or else `sfdc:Error`
    @display {label: "Get SObject Description"}
    isolated remote function describeSObject(@display {label: "SObject Name"} string sObjectName) 
                                            returns @tainted @display {label: "SObject Metadata"} SObjectMetaData|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DESCRIBE]);
        json res = check self->getRecord(path);
        return toSObjectMetaData(res);
    }

    # Query for actions displayed in the UI, given a user, a context, device format, and a record ID.
    #
    # + return - `SObjectBasicInfo` record if successful or else `sfdc:Error`
    @display {label: "Get SObject Platform Action"}
    isolated remote function sObjectPlatformAction() 
                                                  returns @tainted @display {label: "SObject Basic Information"} 
                                                  SObjectBasicInfo|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, PLATFORM_ACTION]);
        json res = check self->getRecord(path);
        return toSObjectBasicInfo(res);
    }

    # Gets an object record by ID.
    #
    # + sobject - SObject name 
    # + id - SObject ID
    # + fields - Fields to retrieve 
    # + return - JSON result if successful or else `sfdc:Error`
    @display {label: "Get Record by ID"}
    isolated remote function getRecordById(@display {label: "SObject Name"} string sobject, 
                                           @display {label: "SObject ID"} string id, 
                                           @display {label: "Fields to Retrieve"} string... fields) 
                                           returns @tainted @display {label: "Result"} json|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobject, id]);
        if fields.length() > 0 {
            path = path.concat(self.appendQueryParams(fields));
        }
        json response = check self->getRecord(path);
        return response;
    }

    # Gets an object record by external ID.
    #
    # + sobject - SObject name 
    # + extIdField - External ID field name 
    # + extId - External ID value 
    # + fields - Fields to retrieve 
    # + return - JSON result if successful or else `sfdc:Error`
    @display {label: "Get Record by External ID"}
    isolated remote function getRecordByExtId(@display {label: "SObject Name"} string sobject, @display 
                                              {label: "External ID Field Name"} string extIdField, 
                                              @display {label: "External ID"} string extId, 
                                              @display {label: "Fields to Retrieve"} string... fields) 
                                              returns @tainted @display {label: "Result"} json|Error {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sobject, extIdField, extId]);
        if fields.length() > 0 {
            path = path.concat(self.appendQueryParams(fields));
        }
        json response = check self->getRecord(path);
        return response;
    }

    //Account
    # Accesses Account SObject records based on the Account object ID.
    #
    # + accountId - Account ID
    # + fields - Fields to retireve
    # + return - JSON response if successful or else an sfdc:Error
    @display {label: "Get Account by ID"}
    isolated remote function getAccountById(@display {label: "Account ID"} string accountId, 
                                            @display {label: "Fields to Retrieve"} string... fields) 
                                            returns @tainted @display {label: "Result"} json|Error {
        json res = check self->getRecordById(ACCOUNT, accountId, ...fields);
        return res;
    }

    # Creates new Account object record.
    #
    # + accountRecord - Account JSON record to be inserted
    # + return - Account ID if successful or else an sfdc:Error
    @display {label: "Create Account"}
    isolated remote function createAccount(@display {label: "Account Record"} json accountRecord) 
                                           returns @tainted @display {label: "Account ID"} string|Error {
        return self->createRecord(ACCOUNT, accountRecord);
    }

    # Deletes existing Account's records.
    #
    # + accountId - Account ID
    # + return - `true` if successful `false` otherwise, or an sfdc:Error in case of an error
    @display {label: "Delete Account"}
    isolated remote function deleteAccount(@display {label: "Account ID"} string accountId) 
                                           returns @tainted @display {label: "Result"} Error? {
        return self->deleteRecord(ACCOUNT, accountId);
    }

    # Updates existing Account object record.
    #
    # + accountId - Account ID
    # + accountRecord - Account record JSON payload
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Update Account"}
    isolated remote function updateAccount(@display {label: "Account ID"} string accountId, 
                                           @display {label: "Account Record"} json accountRecord) 
                                           returns @tainted @display {label: "Result"} Error? {
        return self->updateRecord(ACCOUNT, accountId, accountRecord);
    }

    //Lead
    # Accesses Lead SObject records based on the Lead object ID.
    #
    # + leadId - Lead ID
    # + fields - Fields to retireve
    # + return - JSON response if successful or else an sfdc:Error
    @display {label: "Get Lead by ID"}
    isolated remote function getLeadById(@display {label: "Lead ID"} string leadId, 
                                         @display {label: "Fields to Retrieve"} string... fields) 
                                         returns @tainted @display {label: "Result"} json|Error {
        json res = check self->getRecordById(LEAD, leadId, ...fields);
        return res;
    }

    # Creates new Lead object record.
    #
    # + leadRecord - Lead JSON record to be inserted
    # + return - Lead ID if successful or else an sfdc:Error
    @display {label: "Create Lead"}
    isolated remote function createLead(@display {label: "Lead Record"} json leadRecord) 
                                        returns @tainted @display {label: "Lead ID"} string|Error {
        return self->createRecord(LEAD, leadRecord);
    }

    # Deletes existing Lead's records.
    #
    # + leadId - Lead ID
    # + return - `true`  if successful, `false` otherwise or an sfdc:Error incase of an error
    @display {label: "Delete Lead"}
    isolated remote function deleteLead(@display {label: "Lead ID"} string leadId) 
                                        returns @tainted @display {label: "Result"} Error? {
        return self->deleteRecord(LEAD, leadId);
    }

    # Updates existing Lead object record.
    #
    # + leadId - Lead ID
    # + leadRecord - Lead JSON record
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Update Lead"}
    isolated remote function updateLead(@display {label: "Lead ID"} string leadId, 
                                        @display {label: "Lead Record"} json leadRecord) 
                                        returns @tainted @display {label: "Result"} Error? {
        return self->updateRecord(LEAD, leadId, leadRecord);
    }

    //Contact
    # Accesses Contacts SObject records based on the Contact object ID.
    #
    # + contactId - Contact ID
    # + fields - Fields to retireve
    # + return - JSON result if successful or else an sfdc:Error
    @display {label: "Get Contact by ID"}
    isolated remote function getContactById(@display {label: "Contact ID"} string contactId, 
                                            @display {label: "Fields to Retrieve"}
                                            string... fields) returns @tainted @display {label: "Result"} json|Error {
        json res = check self->getRecordById(CONTACT, contactId, ...fields);
        return res;
    }

    # Creates new Contact object record.
    #
    # + contactRecord - JSON contact record
    # + return - Contact ID if successful or else an sfdc:Error
    @display {label: "Create Contact"}
    isolated remote function createContact(@display {label: "Contact Record"} json contactRecord) 
                                           returns @tainted @display {label: "Contact ID"} string|Error {
        return self->createRecord(CONTACT, contactRecord);
    }

    # Deletes existing Contact's records.
    #
    # + contactId - Contact ID
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Delete Contact"}
    isolated remote function deleteContact(@display {label: "Contact ID"} string contactId) 
                                           returns @tainted @display {label: "Result"} Error? {
        return self->deleteRecord(CONTACT, contactId);
    }

    # Updates existing Contact object record.
    #
    # + contactId - Contact ID
    # + contactRecord - JSON contact record
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Update Contact"}
    isolated remote function updateContact(@display {label: "Contact ID"} string contactId, 
                                           @display {label: "Contact Record"} json contactRecord) 
                                           returns @tainted @display {label: "Result"} Error? {
        return self->updateRecord(CONTACT, contactId, contactRecord);
    }

    //Opportunity
    # Accesses Opportunities SObject records based on the Opportunity object ID.
    #
    # + opportunityId - Opportunity ID
    # + fields - Fields to retireve
    # + return - JSON response if successful or else an sfdc:Error
    @display {label: "Get Opportunity by ID"}
    isolated remote function getOpportunityById(@display {label: "Opportunity ID"} string opportunityId, 
                                                @display {label: "Fields to Retrieve"} string... fields) 
                                                returns @tainted @display {label: "Result"} json|Error {
        json res = check self->getRecordById(OPPORTUNITY, opportunityId, ...fields);
        return res;
    }

    # Creates new Opportunity object record.
    #
    # + opportunityRecord - JSON opportunity record
    # + return - Opportunity ID if successful or else an sfdc:Error
    @display {label: "Create Opportunity"}
    isolated remote function createOpportunity(@display {label: "Opportunity Record"} json opportunityRecord) 
                                               returns @tainted @display {label: "Opportunity ID"} string|Error {
        return self->createRecord(OPPORTUNITY, opportunityRecord);
    }

    # Deletes existing Opportunity's records.
    #
    # + opportunityId - Opportunity ID
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Delete Opportunity"}
    isolated remote function deleteOpportunity(@display {label: "Opportunity ID"} string opportunityId) 
                                               returns @tainted @display {label: "Result"} Error? {
        return self->deleteRecord(OPPORTUNITY, opportunityId);
    }

    # Updates existing Opportunity object record.
    #
    # + opportunityId - Opportunity ID
    # + opportunityRecord - Opportunity JSON payload
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Update Opportunity"}
    isolated remote function updateOpportunity(@display {label: "Opportunity ID"} string opportunityId, 
                                               @display {label: "Opportunity Record"} json opportunityRecord) 
                                               returns @tainted @display {label: "Result"} Error? {
        return self->updateRecord(OPPORTUNITY, opportunityId, opportunityRecord);
    }

    //Product
    # Accesses Products SObject records based on the Product object ID.
    #
    # + productId - Product ID
    # + fields - Fields to retireve
    # + return - JSON result if successful or else an sfdc:Error
    @display {label: "Get Product by ID"}
    isolated remote function getProductById(@display {label: "Product ID"} string productId, 
                                            @display {label: "Fields to Retrieve"} string... fields) 
                                            returns @tainted @display {label: "Result"} json|Error {
        json res = check self->getRecordById(PRODUCT, productId, ...fields);
        return res;
    }

    # Creates new Product object record.
    #
    # + productRecord - JSON product record
    # + return - Product ID if successful or else an sfdc:Error
    @display {label: "Create Product"}
    isolated remote function createProduct(@display {label: "Product Record"} json productRecord) 
                                           returns @tainted @display {label: "Product ID"} string|Error {
        return self->createRecord(PRODUCT, productRecord);
    }

    # Deletes existing product's records.
    #
    # + productId - Product ID
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Delete Product"}
    isolated remote function deleteProduct(@display {label: "Product ID"} string productId) 
                                           returns @tainted @display {label: "Result"} Error? {
        return self->deleteRecord(PRODUCT, productId);
    }

    # Updates existing Product object record.
    #
    # + productId - Product ID
    # + productRecord - JSON product record
    # + return - `true` if successful, `false` otherwise or an sfdc:Error in case of an error
    @display {label: "Update Product"}
    isolated remote function updateProduct(@display {label: "Product ID"} string productId, 
                                           @display {label: "Product Record"} json productRecord) 
                                           returns @tainted @display {label: "Result"} Error? {
        return self->updateRecord(PRODUCT, productId, productRecord);
    }

    private isolated function appendQueryParams(string[] fields) returns string {
        string appended = "?fields=";
        foreach string item in fields {
            appended = appended.concat(item.trim(), ",");
        }
        appended = appended.substring(0, appended.length() - 1);
        return appended;
    }

    //Query
    # Executes the specified SOQL query.
    #
    # + receivedQuery - Sent SOQL query
    # + return - `SoqlResult` record if successful. Else, the occurred `Error`.
    @display {label: "Get Query Result"}
    isolated remote function getQueryResult(@display {label: "SOQL Query"} string receivedQuery) 
                                            returns @tainted @display {label: "SOQL Result"} SoqlResult|Error {
        string path = prepareQueryUrl([API_BASE_PATH, QUERY], [Q], [receivedQuery]);
        json res = check self->getRecord(path);
        return toSoqlResult(res);
    }

    # If the query results are too large, retrieve the next batch of results using the nextRecordUrl.
    #
    # + nextRecordsUrl - URL to get the next query results
    # + return - `SoqlResult` record if successful. Else, the occurred `Error`.
    @display {label: "Get Next Query Result"}
    isolated remote function getNextQueryResult(@display {label: "Next Records URL"} string nextRecordsUrl) 
                                                returns @tainted @display {label: "SOQL Result"} SoqlResult|Error {
        json res = check self->getRecord(nextRecordsUrl);
        return toSoqlResult(res);
    }

    //Search
    # Executes the specified SOSL search.
    #
    # + searchString - Sent SOSL search query
    # + return - `SoslResult` record if successful. Else, the occurred `Error`.
    @display {label: "SOSL Search"}
    isolated remote function searchSOSLString(@display {label: "SOSL Search Query"} string searchString) 
                                              returns @tainted @display {label: "SOSL Result"} SoslResult|Error {
        string path = prepareQueryUrl([API_BASE_PATH, SEARCH], [Q], [searchString]);
        json res = check self->getRecord(path);
        return toSoslResult(res);
    }

    # Lists summary details about each REST API version available.
    #
    # + return - List of `Version` if successful. Else, the occured Error.
    @display {label: "Get Available API Versions"}
    isolated remote function getAvailableApiVersions() returns @tainted @display {label: "Versions"} Version[]|Error {
        string path = prepareUrl([BASE_PATH]);
        json res = check self->getRecord(path);
        return toVersions(res);
    }

    # Lists the resources available for the specified API version.
    #
    # + apiVersion - API version (v37)
    # + return - `Resources` as map of strings if successful. Else, the occurred `Error`.
    @display {label: "Get Resources by API Version"}
    isolated remote function getResourcesByApiVersion(@display {label: "API Version"} string apiVersion) 
                                                      returns @tainted @display {label: "Resources"} map<string>|Error {
        string path = prepareUrl([BASE_PATH, apiVersion]);
        json res = check self->getRecord(path);
        return toMapOfStrings(res);
    }

    # Lists the Limits information for your organization.
    #
    # + return - `OrganizationLimits` as map of `Limit` if successful. Else, the occurred `Error`.
    @display {label: "Get Organization Limits"}
    isolated remote function getOrganizationLimits() 
                                                   returns @tainted @display {label: "Organization Limits"} 
                                                   map<Limit>|Error {
        string path = prepareUrl([API_BASE_PATH, LIMITS]);
        json res = check self->getRecord(path);
        return toMapOfLimits(res);
    }

    //Basic CRUD
    # Accesses records based on the specified object ID, can be used with external objects.
    #
    # + path - Resource path
    # + return - JSON result if successful else or else `sfdc:Error`
    @display {label: "Get Record"}
    isolated remote function getRecord(@display {label: "Resource Path"} string path) 
                                       returns @tainted @display {label: "Result"} json|Error {
        json|http:ClientError response = self.salesforceClient->get(path);
        if response is json {
            return response;
        } else {
            return checkAndSetErrorDetail(response);
        }
    }

    # Creates records based on relevant object type sent with json record.
    #
    # + sObjectName - SObject name value
    # + recordPayload - JSON record to be inserted
    # + return - Created entity ID if successful or else `sfdc:Error`
    @display {label: "Create Record"}
    isolated remote function createRecord(@display {label: "SObject Name"} string sObjectName, 
                                          @display {label: "Record Payload"} json recordPayload) 
                                          returns @tainted @display {label: "Created Entity ID"} string|Error {
        http:Request req = new;
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
        req.setJsonPayload(recordPayload);
        json|http:ClientError response = self.salesforceClient->post(path, req);
        if response is json {
            json|error resultId = response.id;
            if resultId is json {
                return resultId.toString();
            } else {
                return error Error(resultId.message());
            }
        } else {
            return checkAndSetErrorDetail(response);
        }
    }

    # Delete existing records based on relevant object ID.
    #
    # + sObjectName - SObject name value
    # + id - SObject ID
    # + return - true if successful else false or else `sfdc:Error`
    @display {label: "Delete Record"}
    isolated remote function deleteRecord(@display {label: "SObject Name"} string sObjectName, 
                                          @display {label: "SObject ID"} string id) 
                                          returns @tainted @display {label: "Result"} Error? {
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        http:Response|http:ClientError response = self.salesforceClient->delete(path);
        if response is http:ClientError {
            return checkAndSetErrorDetail(response);
        }
    }

    # Updates records based on relevant object ID.
    #
    # + sObjectName - SObject name value
    # + id - SObject ID
    # + recordPayload - JSON record to be updated
    # + return - true if successful else false or else `sfdc:Error`
    @display {label: "Update Record"}
    isolated remote function updateRecord(@display {label: "SObject Name"} string sObjectName, 
                                          @display {label: "SObject ID"} string id, 
                                          @display {label: "Record Payload"} json recordPayload) 
                                          returns @tainted @display {label: "Result"} Error? {
        http:Request req = new;
        string path = prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        req.setJsonPayload(recordPayload);
        http:Response|http:ClientError response = self.salesforceClient->patch(path, req);
        if response is http:ClientError {
            return checkAndSetErrorDetail(response);
        }
    }
}

# Salesforce client configuration.
#
# + baseUrl - The Salesforce endpoint URL
# + clientConfig - OAuth2 direct token configuration
# + secureSocketConfig - HTTPS secure socket configuration
# + httpVersion - The HTTP version understood by the client
# + http1Settings - Configurations related to HTTP/1.x protocol
# + http2Settings - Configurations related to HTTP/2 protocol
# + timeout - The maximum time to wait (in seconds) for a response before closing the connection
# + forwarded - The choice of setting `forwarded`/`x-forwarded` header
# + followRedirects - Configurations associated with Redirection
# + poolConfig - Configurations associated with request pooling
# + cache - HTTP caching related configurations
# + compression - Specifies the way of handling compression (`accept-encoding`) header
# + circuitBreaker - Configurations associated with the behaviour of the Circuit Breaker
# + retryConfig - Configurations associated with retrying
# + cookieConfig - Configurations associated with cookies
# + responseLimits - Configurations associated with inbound response size limits
@display {label: "Connection Config"}
public type ConnectionConfig record {|
    @display {label: "Salesforce Domain URL"}
    string baseUrl;
    @display {label: "Auth Config"}
    http:OAuth2RefreshTokenGrantConfig|http:BearerTokenConfig clientConfig;
    @display {label: "SSL Config"}
    http:ClientSecureSocket secureSocketConfig?;
    string httpVersion = "1.1";
    http:ClientHttp1Settings http1Settings = {};
    http:ClientHttp2Settings http2Settings = {};
    decimal timeout = 60;
    string forwarded = "disable";
    http:FollowRedirects? followRedirects = ();
    http:PoolConfiguration? poolConfig = ();
    http:CacheConfig cache = {};
    http:Compression compression = http:COMPRESSION_AUTO;
    http:CircuitBreakerConfig? circuitBreaker = ();
    http:RetryConfig? retryConfig = ();
    http:CookieConfig? cookieConfig = ();
    http:ResponseLimitConfigs responseLimits = {};
|};
