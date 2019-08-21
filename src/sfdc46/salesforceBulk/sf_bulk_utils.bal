//
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
//

import ballerina/log;
import ballerina/mime;
import ballerina/http;
import ballerina/io;
import ballerina/'lang\.int as ints;
import ballerina/'lang\.float as floats;

# Check and set errors of HTTP response with XML payload.
# + httpResponse - HTTP response or error occurred
# + return - XML response if successful else SalesforceError occured
function checkAndSetErrorsXml(http:Response | error httpResponse) returns @tainted xml | SalesforceError {
    if (httpResponse is http:Response) {
        // If success.
        if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201 || httpResponse.statusCode == 204) {
            var xmlResponse = httpResponse.getXmlPayload();
            if (xmlResponse is xml) {
                return xmlResponse;
            } else {
                return logAndGetSalesforceError(xmlResponse, "HTTP response to XML conversion error.");
            }
        // If failure.
        } else {
            var xmlResponse = httpResponse.getXmlPayload();
            if (xmlResponse is xml) {
                SalesforceError sfError = {
                    message: xmlResponse.exceptionMessage.getTextValue(),
                    errorCode: httpResponse.statusCode.toString()
                };
                return sfError;
            } else {
                return logAndGetSalesforceError(xmlResponse,
                "Could not retirieve the error, HTTP response to XML conversion error.");
            }
        }
    } else {
        return logAndGetSalesforceError(httpResponse, "HTTP error.");
    }
}

# Check and set errors of HTTP response with CSV payload.
# + httpResponse - HTTP response or error occurred
# + return - Text response if successful else SalesforceError occured
function checkAndSetErrorsCsv(http:Response | error httpResponse) returns @tainted string | SalesforceError {
    if (httpResponse is http:Response) {
        // If success.
        if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201 || httpResponse.statusCode == 204) {
            string | error textResponse = httpResponse.getTextPayload();
            if (textResponse is string) {
                return textResponse;
            } else {
                return logAndGetSalesforceError(textResponse, "HTTP response to XML conversion error.");
            }
        // If failure.
        } else {
            var xmlResponse = httpResponse.getXmlPayload();
            if (xmlResponse is xml) {
                SalesforceError sfError = {
                    message: xmlResponse[getElementNameWithNamespace("exceptionMessage")].getTextValue(),
                    errorCode: httpResponse.statusCode.toString()
                };
                return sfError;
            } else {
                return logAndGetSalesforceError(xmlResponse,
                "Could not retrieve the error, HTTP response to XML conversion error.");
            }
        }
    } else {
        return logAndGetSalesforceError(httpResponse, "HTTP error.");
    }
}

# Check and set errors of HTTP response with JSON payload.
# + httpResponse - HTTP response or error occurred
# + return - JSON response if successful else SalesforceError occured
function checkAndSetErrorsJson(http:Response | error httpResponse) returns @tainted json | SalesforceError {
    if (httpResponse is http:Response) {
        // If success.
        if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201 || httpResponse.statusCode == 204) {
            json | error response = httpResponse.getJsonPayload();
            if (response is json) {
                return response;
            } else {
                return logAndGetSalesforceError(response, "HTTP response to XML conversion error.");
            }
        // If failure.
        } else {
            json | error response = httpResponse.getJsonPayload();
            if (response is json) {
                SalesforceError sfError = {
                    message: response.exceptionMessage.toString(),
                    errorCode: httpResponse.statusCode.toString()
                };
                return sfError;
            } else {
                return logAndGetSalesforceError(response,
                "Could not retirieve the error, HTTP response to XML conversion error.");
            }
        }
    } else {
        return logAndGetSalesforceError(httpResponse, "HTTP error.");
    }
}

# Log and get salesforce error.
# + responseErr - error occurred
# + baseErrorMsg - base error message
# + return - SalesforceError
function logAndGetSalesforceError(error responseErr, string baseErrorMsg) returns SalesforceError {
    log:printError(baseErrorMsg + " Error: " + responseErr.detail()["message"].toString());
    return getSalesforceError(baseErrorMsg, "500");
}

# Get salesforce error.
# + errMsg - error message
# + errCode - error code
# + return - SalesforceError
function getSalesforceError(string errMsg, string errCode) returns SalesforceError {
    SalesforceError sfError = {
        message: errMsg,
        errorCode: errCode
    };
    return sfError;
}

# Concatinate namespace with elemant name to access the element from XML.
# + elementName - element name 
# + return - Concatinated string of namespace and element name
function getElementNameWithNamespace(string elementName) returns string {
    return OPEN_CURLY_BRACKET + XML_NAMESPACE + CLOSE_CURLY_BRACKET + elementName;
}

# Convert string to integer
# + value - string value
# + return - converted integer
function getIntValue(string value) returns int {
    int | error intValue = ints:fromString(value);
    if (intValue is int) {
        return intValue;
    } else {
        log:printError("String to int conversion failed, string value='" + value + "' ", err = intValue);
        panic intValue;
    }
}

# Convert string to float
# + value - string value
# + return - converted float
function getFloatValue(string value) returns float {
    float | error floatValue = floats:fromString(value);
    if (floatValue is float) {
        return floatValue;
    } else {
        log:printError("String to float conversion failed, string value='" + value + "' ", err = floatValue);
        panic floatValue;
    }
}

# Convert string to boolean
# + value - string value
# + return - converted boolean
function getBooleanValue(string value) returns boolean {
    if (value == "true") {
        return true;
    } else if (value == "false") {
        return false;
    } else {
        log:printError("Invalid boolean value, string value='" + value + "' ", err = ());
        return false;
    }
}

# Get XML job details to create a job.
# + operation - operation want to perform using this job
# + objectName - which object this job applies to
# + contentType - content type of the job 
# + extIdFieldName - external ID field name
# + return - job info in XML format
function getXmlJobDetails(string operation, string objectName, string contentType, string extIdFieldName = "")
returns xml {
    if(extIdFieldName == EMPTY_STRING) {
        return xml `<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">
    <operation>${operation}</operation>
    <object>${objectName}</object>
    <contentType>${contentType}</contentType>
</jobInfo>`;
    } else {
        return xml `<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">
    <operation>${operation}</operation>
    <object>${objectName}</object>
    <externalIdFieldName>${extIdFieldName}</externalIdFieldName>
    <contentType>${contentType}</contentType>
</jobInfo>`;
    }
}
# Get JSON job details to create a job.
# + operation - operation want to perform using this job
# + objectName - which object this job applies to
# + extIdFieldName - external ID field name
# + return - job info in JSON format
function getJsonJobDetails(string operation, string objectName, string extIdFieldName = "") 
returns json {
    map<json> jobDeatils = {
        operation: operation,
        'object: objectName,
        contentType: JSON
    };
    if (extIdFieldName != EMPTY_STRING) {
        jobDeatils["externalIdFieldName"] = extIdFieldName;
    } 
    return jobDeatils;
}

# Logs, prepares, and returns the `AuthenticationError`.
#
# + message -The error message.
# + err - The `error` instance.
# + return - Returns the prepared `AuthenticationError` instance.
function prepareAuthenticationError(string message, error? err = ()) returns http:AuthenticationError {
    log:printDebug(function () returns string { return message; });
    if (err is error) {
        http:AuthenticationError preparedError = error(http:AUTHN_FAILED, message = message, cause = err);
        return preparedError;
    }
    http:AuthenticationError preparedError = error(http:AUTHN_FAILED, message = message);
    return preparedError;
}

# Logs, prepares, and returns the `AuthorizationError`.
#
# + message -The error message.
# + err - The `error` instance.
# + return - Returns the prepared `AuthorizationError` instance.
function prepareAuthorizationError(string message, error? err = ()) returns http:AuthorizationError {
    log:printDebug(function () returns string { return message; });
    if (err is error) {
        http:AuthorizationError preparedError = error(http:AUTHZ_FAILED, message = message, cause = err);
        return preparedError;
    }
    http:AuthorizationError preparedError = error(http:AUTHZ_FAILED, message = message);
    return preparedError;
}

# Creates a map out of the headers of the HTTP response.
#
# + resp - The `Response` instance.
# + return - Returns the map of the response headers.
function createResponseHeaderMap(http:Response resp) returns @tainted map<anydata> {
    map<anydata> headerMap = {};

    // If session ID is invalid, set staus code as 401.
    if (resp.statusCode == http:STATUS_BAD_REQUEST) {
        string contentType = resp.getHeader(CONTENT_TYPE);
        if (contentType == APP_JSON) {
            json | error payload = resp.getJsonPayload();
            if (payload is json){
                if (payload.exceptionCode == INVALID_SESSION_ID) {
                    headerMap[http:STATUS_CODE] = http:STATUS_UNAUTHORIZED;
                }
            } else {
                log:printError("Invalid payload", err = payload);
            }
        } else if (contentType == APP_XML) {
            xml | error payload = resp.getXmlPayload();
            if (payload is xml){
                if (payload.exceptionCode.getTextValue() == INVALID_SESSION_ID) {
                    headerMap[http:STATUS_CODE] = http:STATUS_UNAUTHORIZED;
                }
            } else {
                log:printError("Invalid payload", err = payload);
            }
        } else {
            log:printError("Invalid contentType, contentType='" + contentType + "' ", err = ());
        }
    } else {
        headerMap[http:STATUS_CODE] = resp.statusCode;
    }

    string[] headerNames = resp.getHeaderNames();
    foreach string header in headerNames {
        string[] headerValues = resp.getHeaders(<@untainted> header);
        headerMap[header] = headerValues;
    }
    return headerMap;
}

# Close ReadableCharacterChannel.
#
# + ch - ReadableCharacterChannel
function closeRc(io:ReadableCharacterChannel ch) {
    var cr = ch.close();
    if (cr is error) {
        log:printError("Error occured while closing the channel: ", err = cr);
    }
}

# Close ReadableByteChannel.
#
# + ch - ReadableByteChannel
function closeRb(io:ReadableByteChannel ch) {
    var cr = ch.close();
    if (cr is error) {
        log:printError("Error occured while closing the channel: ", err = cr);
    }
}

# Get SalesforceError for failed batch.
#
# + batch - Failed Batch
# + return - Returns SalesforceError for failed batch.
function getFailedBatchError(Batch batch) returns SalesforceError {
    return getSalesforceError("Batch has failed, batch=" + batch.toString(), 
        http:STATUS_INTERNAL_SERVER_ERROR.toString());
}

# Get SalesforceError for getting results timed out.
#
# + batchId - ID of the batch which getting results timed out
# + numberOfTries - No of times tried
# + waitTime - Wait time between 2 tries
# + return - SalesforceError for getting results timed out
function getResultTimeoutError(string batchId, int numberOfTries, int waitTime) returns SalesforceError {
    int totalTime = numberOfTries * waitTime;
    return getSalesforceError("Getting result timed out after " + totalTime.toString() + " (ms), batchId=" + batchId, 
        http:STATUS_REQUEST_TIMEOUT.toString());
}

# Log waiting message while getting batch results.
#
# + batch - Batch which trying to get results.
function printWaitingMessage(Batch batch) {
    log:printInfo("Waiting to complete the batch, batch=" + batch.toString());
}
