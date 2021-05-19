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

# Salesforce connector error
public type Error distinct error;

// Logs and prepares the `error` as an `sfdc:Error`.
isolated function prepareError(string message, error? err = ()) returns Error {
    if (err is error) {
        return error Error(message, err);
    }
    return error Error(message);
}

// Error constants
const string JSON_ACCESSING_ERROR_MSG = "Error occurred while accessing the JSON payload of the response.";
const string XML_ACCESSING_ERROR_MSG = "Error occurred while accessing the XML payload of the response.";
const string TEXT_ACCESSING_ERROR_MSG = "Error occurred while accessing the Text payload of the response.";
const string ERR_EXTRACTING_ERROR_MSG = "Error occured while extracting errors from payload.";
const string HTTP_ERROR_MSG = "Error occurred while getting the HTTP response.";
const string UNREACHABLE_STATE = "Response type cannot be http payload";
const string INVALID_CLIENT_CONFIG = "Invalid values provided for client configuration parameters.";
