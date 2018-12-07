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
final string API_VERSION = "v37.0";

// For URL encoding
# Constant field `ENCODING_CHARSET`. Holds the value for the encoding charset.
final string ENCODING_CHARSET = "utf-8";

//Salesforce endpoints
# Constant field `BASE_PATH`. Holds the value for the Salesforce base path/URL.
final string BASE_PATH = "/services/data";

# Constant field `API_BASE_PATH`. Holds the value for the Salesforce API base path/URL.
final string API_BASE_PATH = string `{{BASE_PATH}}/{{API_VERSION}}`;

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

# Constant field `QUERY`. Holds the value query for SOQL query resource prefix.
final string QUERY = "query";

# Constant field `search`. Holds the value search for SOSL search resource prefix.
final string SEARCH = "search";

# Constant field `QUERYALL`. Holds the value queryAll for query all resource prefix.
final string QUERYALL = "queryAll";

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

//========================================================================================//
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
final string SALESFORCE_ERROR_CODE = "(wso2/sfdc37)SalesforceConnectorError";