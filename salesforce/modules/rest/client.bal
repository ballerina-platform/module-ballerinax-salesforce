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
import ballerina/jballerina.java;
import ballerinax/salesforce.utils;

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
    public isolated function init(ConnectionConfig salesforceConfig) returns error? {
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
            return error(INVALID_CLIENT_CONFIG);
        }
    }

    # Gets an object record by ID.
    #
    # + sobject - sObject name 
    # + id - sObject ID
    # + fields - Fields to retrieve 
    # + returnType - The payload, which is expected to be returned after data binding.
    # + return - Record if successful or else `error`
    @display {label: "Get Record by ID"}
    isolated remote function getById(@display {label: "sObject Name"} string sobject,
                                    @display {label: "sObject ID"} string id,
                                    @display {label: "Fields to Retrieve"} string[] fields = [], typedesc<record {}> returnType = <>)
                                    returns @display {label: "Result"} returnType|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "getRecordById"
    } external;

    private isolated function processGetRecordById(typedesc<record {}> returnType, string sobject, string id,
                                                    string[] fields) returns record {}|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sobject, id]);
        if fields.length() > 0 {
            path = path.concat(utils:appendQueryParams(fields));
        }
        json response = check self.salesforceClient->get(path);
        return check response.cloneWithType(returnType);
    }

    # Gets an object record by external ID.
    #
    # + sobject - sObject name 
    # + extIdField - External ID field name 
    # + extId - External ID value 
    # + fields - Fields to retrieve 
    # + returnType - The payload, which is expected to be returned after data binding.
    # + return - Record if successful or else `error`
    @display {label: "Get Record by External ID"}
    isolated remote function getByExternalId(@display {label: "sObject Name"} string sobject,
                                            @display {label: "External ID Field Name"} string extIdField,
                                            @display {label: "External ID"} string extId,
                                            @display {label: "Fields to Retrieve"} string[] fields = [], typedesc<record {}> returnType = <>)
                                            returns @display {label: "Result"} returnType|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "getRecordByExtId"
    } external;

    private isolated function processGetRecordByExtId(typedesc<record {}> returnType, string sobject, string extIdField,
                                                        string extId, string[] fields) returns record {}|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sobject, extIdField, extId]);
        if fields.length() > 0 {
            path = path.concat(utils:appendQueryParams(fields));
        }
        json response = check self.salesforceClient->get(path);
        return check response.cloneWithType(returnType);
    }

    # Creates records based on relevant object type sent with json record.
    #
    # + sObjectName - sObject name value
    # + sObjectRecord - Record to be inserted
    # + return - Creation response if successful or else `error`
    @display {label: "Create Record"}
    isolated remote function create(@display {label: "sObject Name"} string sObjectName,
                                    @display {label: "sObject Data"} record {} sObjectRecord)
                                    returns @display {label: "Created Entity ID"} CreationResponse|error {
        http:Request req = new;
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName]);
        req.setJsonPayload(sObjectRecord.toJson());
        return check self.salesforceClient->post(path, req);
    }

    # Updates records based on relevant object ID.
    #
    # + sObjectName - sObject name value
    # + id - sObject ID
    # + sObjectRecord - Record to be updated
    # + return - Empty response if successful `error`
    @display {label: "Update Record"}
    isolated remote function update(@display {label: "sObject Name"} string sObjectName,
                                    @display {label: "sObject ID"} string id,
                                    @display {label: "Record Payload"} record {} sObjectRecord)
                                    returns @display {label: "Result"} error? {
        http:Request req = new;
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        req.setJsonPayload(sObjectRecord.toJson());
        return check self.salesforceClient->patch(path, req);
    }

    # Upsert a record based on the value of a specified external ID field.
    #
    # + sObjectName - sObject name value
    # + externalIdField - External ID field of an object
    # + externalId - External ID
    # + sObjectRecord - Record to be upserted
    # + return - Empty response if successful or else `error`
    @display {label: "Upsert Record"}
    isolated remote function upsert(@display {label: "sObject Name"} string sObjectName,
                                    @display {label: "External ID Field"} string externalIdField,
                                    @display {label: "External ID"} string externalId,
                                    @display {label: "Record Payload"} record {} sObjectRecord)
                                    returns @display {label: "Result"} error? {
        http:Request req = new;
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, externalIdField, externalId]);
        req.setJsonPayload(sObjectRecord.toJson());
        return check self.salesforceClient->patch(path, req);
    }

    # Delete existing records based on relevant object ID.
    #
    # + sObjectName - SObject name value
    # + id - SObject ID
    # + return - Empty response if successful or else `error`
    @display {label: "Delete Record"}
    isolated remote function delete(@display {label: "SObject Name"} string sObjectName,
                                    @display {label: "SObject ID"} string id)
                                    returns @display {label: "Result"} error? {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, id]);
        return check self.salesforceClient->delete(path);
    }

    # Executes the specified SOQL query.
    #
    # + soql - SOQL query
    # + returnType - The payload, which is expected to be returned after data binding.
    # + return - `stream<{returnType}, error?>` if successful. Else, the occurred `error`.
    @display {label: "Get Query Result"}
    isolated remote function query(@display {label: "SOQL Query"} string soql, typedesc<record {}> returnType = <>)
                                    returns @display {label: "SOQL Result"} stream<returnType, error?>|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "getQueryResult"
    } external;

    private isolated function processGetQueryResult(typedesc<record {}> returnType, string receivedQuery)
                                                    returns stream<record {}, error?>|error {
        string path = utils:prepareQueryUrl([API_BASE_PATH, QUERY], [Q], [receivedQuery]);
        SOQLQueryResultStream objectInstance = check new (self.salesforceClient, path);
        stream<record {}, error?> finalStream = new (objectInstance);
        return finalStream;
    }

    # Executes the specified SOSL search.
    #
    # + sosl - SOSL search query
    # + returnType - The payload, which is expected to be returned after data binding.
    # + return - `stream<{returnType}, error?>` record if successful. Else, the occurred `error`.
    @display {label: "SOSL Search"}
    isolated remote function search(@display {label: "SOSL Search Query"} string sosl, typedesc<record {}> returnType = <>)
                                    returns @display {label: "SOSL Result"} stream<returnType, error?>|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "searchSOSLString"
    } external;

    private isolated function processSearchSOSLString(typedesc<record {}> returnType, string searchString)
                                                    returns stream<record {}, error?>|error {
        string path = utils:prepareQueryUrl([API_BASE_PATH, SEARCH], [Q], [searchString]);
        SOSLSearchResult objectInstance = check new (self.salesforceClient, path);
        stream<record {}, error?> finalStream = new (objectInstance);
        return finalStream;
    }

    //Describe SObjects
    # Lists the available objects and their metadata for your organization and available to the logged-in user.
    #
    # + return - `OrgMetadata` record if successful or else `sfdc:Error`
    @display {label: "Get Available Objects"}
    isolated remote function describeAvailableObjects()
                                                    returns @display {label: "Organization Metadata"}
                                                    OrgMetadata|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS]);
        return check self.salesforceClient->get(path);
    }

    # Describes the individual metadata for the specified object.
    #
    # + sobjectName - sObject name
    # + return - `SObjectBasicInfo` record if successful or else `sfdc:Error`
    @display {label: "Get sObject Basic Information"}
    isolated remote function getSObjectBasicInfo(@display {label: "sObject Name"} string sobjectName)
                                                returns @display {label: "sObject Basic Information"}
                                                SObjectBasicInfo|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sobjectName]);
        return check self.salesforceClient->get(path);
    }

    # Completely describes the individual metadata at all levels for the specified object. Can be used to retrieve
    # the fields, URLs, and child relationships.
    #
    # + sObjectName - sObject name value
    # + return - `SObjectMetaData` record if successful or else `sfdc:Error`
    @display {label: "Get sObject Description"}
    isolated remote function describeSObject(@display {label: "sObject Name"} string sObjectName)
                                            returns @display {label: "sObject Metadata"} SObjectMetaData|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, sObjectName, DESCRIBE]);
        return check self.salesforceClient->get(path);
    }

    # Query for actions displayed in the UI, given a user, a context, device format, and a record ID.
    #
    # + return - `SObjectBasicInfo` record if successful or else `sfdc:Error`
    @display {label: "Get sObject Platform Action"}
    isolated remote function sObjectPlatformAction()
                                                returns @display {label: "sObject Basic Information"}
                                                SObjectBasicInfo|error {
        string path = utils:prepareUrl([API_BASE_PATH, SOBJECTS, PLATFORM_ACTION]);
        return check self.salesforceClient->get(path);
    }

    # Lists summary details about each REST API version available.
    #
    # + return - List of `Version` if successful. Else, the occured Error.
    @display {label: "Get Available API Versions"}
    isolated remote function getAvailableApiVersions() returns @display {label: "Versions"} Version[]|error {
        string path = utils:prepareUrl([BASE_PATH]);
        return check self.salesforceClient->get(path);
    }

    # Lists the resources available for the specified API version.
    #
    # + apiVersion - API version (v37)
    # + return - `Resources` as map of strings if successful. Else, the occurred `Error`.
    @display {label: "Get Resources by API Version"}
    isolated remote function getResourcesByApiVersion(@display {label: "API Version"} string apiVersion)
                                                    returns @display {label: "Resources"} map<string>|error {
        string path = utils:prepareUrl([BASE_PATH, apiVersion]);
        json res = check self.salesforceClient->get(path);
        return toMapOfStrings(res);
    }

    # Lists the Limits information for your organization.
    #
    # + return - `OrganizationLimits` as map of `Limit` if successful. Else, the occurred `Error`.
    @display {label: "Get Organization Limits"}
    isolated remote function getOrganizationLimits()
                                                    returns @display {label: "Organization Limits"}
                                                    map<Limit>|error {
        string path = utils:prepareUrl([API_BASE_PATH, LIMITS]);
        json res = check self.salesforceClient->get(path);
        return toMapOfLimits(res);
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
