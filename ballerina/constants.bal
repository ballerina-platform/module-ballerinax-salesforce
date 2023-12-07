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

//Latest API Version
# Constant field `API_VERSION`. Holds the value for the Salesforce API version.
public const string API_VERSION = "v59.0";

// For URL encoding
# Constant field `ENCODING_CHARSET`. Holds the value for the encoding charset.
const string ENCODING_CHARSET = "utf-8";

//Salesforce endpoints
# Constant field `BASE_PATH`. Holds the value for the Salesforce base path/URL.
const string BASE_PATH = "/services/data";

# Constant field `API_BASE_PATH`. Holds the value for the Salesforce API base path/URL.
final string API_BASE_PATH = string `${BASE_PATH}/${API_VERSION}`;

# Constant field `APEX_BASE_PATH`. Holds the value for the Salesforce Apex base path/URL.
final string APEX_BASE_PATH = string `/services/apexrest`;

# Constant field `QUICK_ACTIONS`. Holds the value quickActions for quick actions resource prefix.
final string QUICK_ACTIONS = "quickActions";

# Constant field `ANALYTICS`. Holds the value analytics for analytics resource prefix.
const string ANALYTICS = "analytics";

# Constant field `ACTIONS`. Holds the value actions for actions resource prefix.
const string ACTIONS = "actions";

# Constant field `NAMED_LAYOUTS`. Holds the value namedlayouts for layout resource prefix.
const string NAMED_LAYOUTS = "namedLayouts";

# Constant field `COMPOSITE`. Holds the value composite for composite resource prefix.
const string COMPOSITE = "composite";

# Constant field `BATCH`. Holds the value batch for batch resource prefix.
const string BATCH = "batch";

# Constant field `BATCHES`. Holds the value batches for bulk resource prefix.
const string BATCHES = "batches";

# Constant field `JOBS`. Holds the value jobs for bulk resource prefix.
const string JOBS = "jobs";

# Constant field `INGEST`. Holds the value ingest for bulk resource prefix.
const string INGEST = "ingest";

# Constant field `INSTANCES`. Holds the value instances for instances resource prefix.
const string INSTANCES = "instances";

# Constant field `REPORTS`. Holds the value reports for reports resource prefix.
const string REPORTS = "reports";

# Constant field `SOBJECTS`. Holds the value sobjects for get sobject resource prefix.
const string SOBJECTS = "sobjects";

# Constant field `PASSWORD`. Holds the value sobjects for get password resource prefix.
const string PASSWORD = "password";

# Constant field `USER`. Holds the value sobjects for get USER resource prefix.
const string USER = "User";

# Constant field `DELETED` Holds the value deleted for get deleted resource prefix.
const string DELETED = "deleted";

# Constant field `UPDATED` Holds the value updated for get updated resource prefix.
const string UPDATED = "updated";

# Constant field `LIMITS`. Holds the value limits for get limits resource prefix.
const string LIMITS = "limits";

# Constant field `DESCRIBE`. Holds the value describe for describe resource prefix.
const string DESCRIBE = "describe";

# Constant field `search`. Holds the value search for SOSL search resource prefix.
const string SEARCH = "search";

# Constant field `PLATFORM_ACTION`. Holds the value PlatformAction for resource prefix.
const string PLATFORM_ACTION = "PlatformAction";

// Query param names
const string QUERY = "query";

# Constant field `FIELDS`. Holds the value fields for resource prefix.
const string FIELDS = "fields";

# Constant field `q`. Holds the value q for query resource prefix.
const string Q = "q";

# Constant field `QUESTION_MARK`. Holds the value of "?".
const string QUESTION_MARK = "?";

# Constant field `EQUAL_SIGN`. Holds the value of "=".
const string EQUAL_SIGN = "=";

# Constant field `EMPTY_STRING`. Holds the value of "".
public const string EMPTY_STRING = "";

# Constant field `AMPERSAND`. Holds the value of "&".
const string AMPERSAND = "&";

# Constant field `FORWARD_SLASH`. Holds the value of "/".
const string FORWARD_SLASH = "/";

# Next records URl
const NEXT_RECORDS_URL = "nextRecordsUrl";

const ATTRIBUTES = "attributes";

//  SObjects
# Constant field `ACCOUNT`. Holds the value Account for account object.
const string ACCOUNT = "Account";

# Constant field `LEAD`. Holds the value Lead for lead object.
const string LEAD = "Lead";

# Constant field `CONTACT`. Holds the value Contact for contact object.
const string CONTACT = "Contact";

# Constant field `OPPORTUNITY`. Holds the value Opportunity for opportunity object.
const string OPPORTUNITY = "Opportunity";

# Constant field `PRODUCT`. Holds the value Product2 for product object.
const string PRODUCT = "Product2";

# Constant field `NEW_LINE`. Holds the value of "\n".
const string NEW_LINE = "\n";