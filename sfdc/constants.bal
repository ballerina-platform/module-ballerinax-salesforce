// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

// Ballerina config keys
# Constant field `ENDPOINT`. Holds the value for Salesforce endpoint.
final string ENDPOINT = "ENDPOINT";

# Constant field `ACCESS_TOKEN`. Holds the value for the access token generated for your app.
final string ACCESS_TOKEN = "ACCESS_TOKEN";

# Constant field `CLIENT_ID`. Holds the value for the client id generated for your app.
final string CLIENT_ID = "CLIENT_ID";

# Constant field `CLIENT_SECRET`. Holds the value for the client secret generated for your app.
final string CLIENT_SECRET = "CLIENT_SECRET";

# Constant field `REFRESH_TOKEN`. Holds the value for the refresh token generated for your app.
final string REFRESH_TOKEN = "REFRESH_TOKEN";

# Constant field `REFRESH_TOKEN_ENDPOINT`. Holds the value for Salesforce refresh token endpoint.
final string REFRESH_TOKEN_ENDPOINT = "REFRESH_URL";

//Latest API Version
# Constant field `API_VERSION`. Holds the value for the Salesforce API version.
final string API_VERSION = "v48.0";

// For URL encoding
# Constant field `ENCODING_CHARSET`. Holds the value for the encoding charset.
final string ENCODING_CHARSET = "utf-8";

//Salesforce endpoints
# Constant field `BASE_PATH`. Holds the value for the Salesforce base path/URL.
final string BASE_PATH = "/services/data";

# Constant field `API_BASE_PATH`. Holds the value for the Salesforce API base path/URL.
final string API_BASE_PATH = string `${BASE_PATH}/${API_VERSION}`;

# Constant field `SOBJECTS`. Holds the value sobjects for get sobject resource prefix.
final string SOBJECTS = "sobjects";

# Constant field `LIMITS`. Holds the value limits for get limits resource prefix.
final string LIMITS = "limits";

# Constant field `DELETED`. Holds the value deleted for deleted records resource prefix.
final string DELETED = "deleted";

# Constant field `UPDATED`. Holds the value updated for updated records resource prefix.
final string UPDATED = "updated";

# Constant field `DESCRIBE`. Holds the value describe for describe resource prefix.
final string DESCRIBE = "describe";

# Constant field `QUERY`. Holds the value query for SOQL query resource prefix and bulk API query operator.
const QUERY = "query";

# Constant field `search`. Holds the value search for SOSL search resource prefix.
final string SEARCH = "search";

# Constant field `QUERYALL`. Holds the value `queryAll` for query all resource prefix and bulk API queryAll operator.
const QUERYALL = "queryAll";

# Constant field `PLATFORM_ACTION`. Holds the value PlatformAction for resource prefix.
final string PLATFORM_ACTION = "PlatformAction";

# Constant field `MULTIPLE_RECORDS`. Holds the value composite/tree for resource prefix.
final string MULTIPLE_RECORDS = "composite/tree";

// Query param names
# Constant field `FIELDS`. Holds the value fields for resource prefix.
final string FIELDS = "fields";

# Constant field `start`. Holds the value for start.
final string START = "start";

# Constant field `end`. Holds the value for end.
final string END = "end";

# Constant field `q`. Holds the value q for query resource prefix.
final string Q = "q";

# Constant field `EXPLAIN`. Holds the value explain for resource prefix.
final string EXPLAIN = "explain";

//  SObjects
# Constant field `ACCOUNT`. Holds the value Account for account object.
final string ACCOUNT = "Account";

# Constant field `LEAD`. Holds the value Lead for lead object.
final string LEAD = "Lead";

# Constant field `CONTACT`. Holds the value Contact for contact object.
final string CONTACT = "Contact";

# Constant field `OPPORTUNITY`. Holds the value Opportunity for opportunity object.
final string OPPORTUNITY = "Opportunity";

# Constant field `PRODUCT`. Holds the value Product2 for product object.
final string PRODUCT = "Product2";

# Constant field `QUESTION_MARK`. Holds the value of "?".
final string QUESTION_MARK = "?";

# Constant field `EQUAL_SIGN`. Holds the value of "=".
final string EQUAL_SIGN = "=";

# Constant field `EMPTY_STRING`. Holds the value of "".
final string EMPTY_STRING = "";

# Constant field `AMPERSAND`. Holds the value of "&".
final string AMPERSAND = "&";

# Constant field `FORWARD_SLASH`. Holds the value of "/".
final string FORWARD_SLASH = "/";

// Error Codes
const SALESFORCE_ERROR_CODE = "{wso2/salesforce}";

// ************************************ Salesforce bulk client constants ***********************************************

# Constant field `BULK_API_VERSION`. Holds the value for the Salesforce Bulk API version.
const BULK_API_VERSION = "48.0";

# Constant field `SERVICES`. Holds the value of "services".
const SERVICES = "services";

# Constant field `ASYNC`. Holds the value of "async".
const ASYNC = "async";

// Bulk API Operators

# Constant field `INSERT`. Holds the value of "insert" for insert operator.
const INSERT = "insert";

# Constant field `UPSERT`. Holds the value of "upsert" for upsert operator.
const UPSERT = "upsert";

# Constant field `UPDATE`. Holds the value of "update" for update operator.
const UPDATE = "update";

# Constant field `DELETE`. Holds the value of "delete" for delete operator.
const DELETE = "delete";

// Content types allowed by Bulk API

# Constant field `CSV`. Holds the value of "CSV".
const CSV = "CSV";

# Constant field `XML`. Holds the value of "XML".
const XML = "XML";

# Constant field `JSON`. Holds the value of "JSON".
const JSON = "JSON";

// Salesforce bulk API terms

# Constant field `JOB`. Holds the value of "job".
const JOB = "job";

# Constant field `BATCH`. Holds the value of "batch".
const BATCH = "batch";

# Constant field `REQUEST`. Holds the value of "request".
const REQUEST = "request";

# Constant field `RESULT`. Holds the value of "result".
const RESULT = "result";

# Constant field `STATUS_CODE`. Header name for bulk API response .
const STATUS_CODE = "STATUS_CODE";

// XML namespace used by salesforce responses

# Constant field `XML_NAMESPACE`. Holds the value of XML namespace used by salesforce bulk API.
const XML_NAMESPACE = "http://www.force.com/2009/06/asyncapi/dataload";

// Content types

# Constant field `APP_XML`. Holds the value of "application/xml".
const APP_XML = "application/xml";

# Constant field `APP_JSON`. Holds the value of "application/xml".
const APP_JSON = "application/json";

# Constant field `TEXT_CSV`. Holds the value of "text/csv".
const TEXT_CSV = "text/csv";

# Constant field `APP_OCT_STREAM`. Holds the value of "application/octet-stream".
const APP_OCT_STREAM = "application/octet-stream";

// characters and words

# Constant field `OPEN_CURLY_BRACKET`. Holds the value of "{".
const OPEN_CURLY_BRACKET = "{";

# Constant field `CLOSE_CURLY_BRACKET`. Holds the value of "}".
const CLOSE_CURLY_BRACKET = "}";

# Constant field `TRUE`. Holds the value of "true".
const TRUE = "true";

# Constant field `CONTENT_TYPE`. Holds the value of "Content-Type".
const CONTENT_TYPE = "Content-Type";

# Constant field `X_SFDC_SESSION`. 
# Holds the value of "X-SFDC-Session" which used as Authorization header name of bulk API.
const X_SFDC_SESSION = "X-SFDC-Session";

# Constant field `AUTHORIZATION`. 
# Holds the value of "Authorization" which used as Authorization header name of REST API.
const AUTHORIZATION = "Authorization";

# Constant field `BEARER`. Holds the value of "Bearer".
const BEARER = "Bearer ";

# Constant field `ENABLE_PK_CHUNKING`. 
# Holds the value of "Sforce-Enable-PKChunking" which used to handle large data set extracts.
const ENABLE_PK_CHUNKING = "Sforce-Enable-PKChunking";

# Constant field `INVALID_SESSION_ID`. 
# Holds the value of "InvalidSessionId" which used to identify Unauthorized 401 response.
const INVALID_SESSION_ID = "InvalidSessionId";

// Payloads

# Constant field `JSON_STATE_CLOSED_PAYLOAD`. Holds the value of JSON body which needs to close the job.
final json JSON_STATE_CLOSED_PAYLOAD = {state: "Closed"};

# Constant field `JSON_STATE_ABORTED_PAYLOAD`. Holds the value of JSON body which needs to abort the job.
final json JSON_STATE_ABORTED_PAYLOAD = {state: "Aborted"};

# Constant field `XML_STATE_CLOSED_PAYLOAD`. Holds the value of XML body which needs to close the job.
final xml XML_STATE_CLOSED_PAYLOAD = xml `<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">
    <state>Closed</state>
</jobInfo>`;

# Constant field `XML_STATE_ABORTED_PAYLOAD`. Holds the value of XML body which needs to abort the job.
final xml XML_STATE_ABORTED_PAYLOAD = xml `<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">
    <state>Aborted</state>
</jobInfo>`;

// Salesforce bulk API batch states

# Constant field `COMPLETED`. Holds the value of completed batch state.
const COMPLETED = "Completed";

# Constant field `Failed`. Holds the value of failed batch state.
const FAILED = "Failed";
