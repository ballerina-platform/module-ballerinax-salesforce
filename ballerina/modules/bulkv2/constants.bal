// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

public const string INVALID_CLIENT_CONFIG = "Invalid values provided for client configuration parameters.";

//Salesforce endpoints
# Constant field `BASE_PATH`. Holds the value for the Salesforce base path/URL.
const string BASE_PATH = "/services/data";

# Constant field `API_BASE_PATH`. Holds the value for the Salesforce API base path/URL.
final string API_BASE_PATH = string `${BASE_PATH}/${API_VERSION}`;

# Constant field `BATCHES`. Holds the value batches for bulk resource prefix.
const string BATCHES = "batches";

# Constant field `JOBS`. Holds the value jobs for bulk resource prefix.
const string JOBS = "jobs";

# Constant field `INGEST`. Holds the value ingest for bulk resource prefix.
const string INGEST = "ingest";

// Query param names
const string QUERY = "query";

// Result param names
const string RESULT = "results";

# Constant field `FIELDS`. Holds the value fields for resource prefix.
const string FIELDS = "fields";

# Constant field `q`. Holds the value q for query resource prefix.
const string Q = "q";

# Constant field `EMPTY_STRING`. Holds the value of "".
public const string EMPTY_STRING = "";

# Constant field `NEW_LINE`. Holds the value of "\n".
const string NEW_LINE = "\n";
