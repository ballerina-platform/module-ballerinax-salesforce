// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

# Salesforce connector error.
public type Error error<ErrorDetails>;

# Additional details extracted from the Http error.
#
# + errorCode - Error code from Salesforce
# + message - Response body with extra information 
#  
public type ErrorDetails record {
    string? errorCode?;
    string? message?;
};

// Error constants
const string JSON_ACCESSING_ERROR_MSG = "Error occurred while accessing the JSON payload of the response.";
const string XML_ACCESSING_ERROR_MSG = "Error occurred while accessing the XML payload of the response.";
const string TEXT_ACCESSING_ERROR_MSG = "Error occurred while accessing the Text payload of the response.";
const string HTTP_CLIENT_ERROR = "Failed to establish the communication with the upstream server or a data binding failure. Refer error.cause() for more details";
public const string HTTP_ERROR_MSG = "Error occurred while getting the HTTP response.";
const STATUS_CODE = "statusCode";
const HEADERS = "headers";
const BODY = "body";

public const string CLIENT_INIT_ERROR_MSG = "Error occurred while initializing the client: ";
public const string ERR_EXTRACTING_ERROR_MSG = "Error occured while extracting errors from payload.";
