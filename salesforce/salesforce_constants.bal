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

// Ballerina config keys
@readonly public string ENDPOINT = "ENDPOINT";
@readonly public string ACCESS_TOKEN = "ACCESS_TOKEN";
@readonly public string CLIENT_ID = "CLIENT_ID";
@readonly public string CLIENT_SECRET = "CLIENT_SECRET";
@readonly public string REFRESH_TOKEN = "REFRESH_TOKEN";
@readonly public string REFRESH_TOKEN_ENDPOINT = "REFRESH_TOKEN_ENDPOINT";
@readonly public string REFRESH_TOKEN_PATH = "REFRESH_TOKEN_PATH";

//Latest API Version
@readonly public string API_VERSION = "v37.0";

// For URL encoding
@readonly public string ENCODING_CHARSET = "utf-8";

//Salesforce endpoints
@readonly public string BASE_PATH = "/services/data";
@readonly public string API_BASE_PATH = string `{{BASE_PATH}}/{{API_VERSION}}`;
@readonly public string SOBJECTS = "sobjects";
@readonly public string LIMITS = "limits";
@readonly public string DELETED = "deleted";
@readonly public string UPDATED = "updated";
@readonly public string DESCRIBE = "describe";
@readonly public string QUERY = "query";
@readonly public string SEARCH = "search";
@readonly public string QUERYALL = "queryAll";
@readonly public string PLATFORM_ACTION = "PlatformAction";
@readonly public string MULTIPLE_RECORDS = "composite/tree";

// Query param names
@readonly public string FIELDS = "fields";
@readonly public string START = "start";
@readonly public string END = "end";
@readonly public string Q = "q";
@readonly public string EXPLAIN = "explain";

//=================================  SObjects  ==========================================//
@readonly public string ACCOUNT = "Account";
@readonly public string LEAD = "Lead";
@readonly public string CONTACT = "Contact";
@readonly public string OPPORTUNITY = "Opportunity";
@readonly public string PRODUCT = "Product2";