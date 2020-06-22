//
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
//

import ballerina/lang.'error as errs;

# Holds the details of an Salesforce error
# + errorCode - Error code for the error
type ErrorDetail record {
    *errs:Detail;
    string errorCode;
};

// Ballerina Salesforce Client Error Types
const HTTP_RESPONSE_HANDLING_ERROR = "[ballerinax/sfdc]HttpResponseHandlingError";
public type HttpResponseHandlingError error<HTTP_RESPONSE_HANDLING_ERROR, ErrorDetail>;

const TYPE_CONVERSION_ERROR = "[ballerinax/sfdc]TypeConversionError";
public type TypeConversionError error<TYPE_CONVERSION_ERROR, ErrorDetail>;

const HTTP_ERROR = "[ballerinax/sfdc]HTTPError";
public type HttpError error<HTTP_ERROR, ErrorDetail>;

const SERVER_ERROR = "[ballerinax/sfdc]ServerError";
public type ServerError error<SERVER_ERROR, ErrorDetail>;

const IO_ERROR = "[ballerinax/sfdc]IOError";
public type IOError error<IO_ERROR, ErrorDetail>;

// Ballerina Salesforce Union Errors
public type ConnectorError ServerError|ClientError;

public type ClientError HttpResponseHandlingError|HttpError|TypeConversionError|IOError;

// Error messages
const string JSON_ACCESSING_ERROR_MSG = "Error occurred while accessing the JSON payload of the response.";
const string XML_ACCESSING_ERROR_MSG = "Error occurred while accessing the XML payload of the response.";
const string TEXT_ACCESSING_ERROR_MSG = "Error occurred while accessing the Text payload of the response.";
const string ERR_EXTRACTING_ERROR_MSG = "Error occured while extracting errors from payload.";
const string HTTP_ERROR_MSG = "Error occurred while getting the HTTP response.";
