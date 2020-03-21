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
import ballerina/http;
import ballerina/io;
import ballerina/runtime;
import ballerina/'lang\.int as ints;
import ballerina/'lang\.float as floats;

# Check HTTP response and return XML payload if succesful, else set errors and return ConnectorError.
# + httpResponse - HTTP response or error occurred
# + return - XML response if successful else ConnectorError occured
function checkXmlPayloadAndSetErrors(http:Response|error httpResponse) returns @tainted xml|ConnectorError {
    if (httpResponse is http:Response) {

        if (httpResponse.statusCode == http:STATUS_OK || httpResponse.statusCode == http:STATUS_CREATED 
            || httpResponse.statusCode == http:STATUS_NO_CONTENT) {
            xml|error xmlResponse = httpResponse.getXmlPayload();

            if (xmlResponse is xml) {
                return xmlResponse;
            } else {
                log:printError(XML_ACCESSING_ERROR_MSG, err = xmlResponse);
                HttpResponseHandlingError httpResHandlingError = error(HTTP_RESPONSE_HANDLING_ERROR,
                    message = XML_ACCESSING_ERROR_MSG, errorCode = HTTP_RESPONSE_HANDLING_ERROR,
                    cause = xmlResponse);
                return httpResHandlingError;
            }

        } else {
            return handleXmlErrorResponse(httpResponse);
        }

    } else {
        return handleHttpError(httpResponse);
    }
}

# Check HTTP response and return Text payload if succesful, else set errors and return ConnectorError.
# + httpResponse - HTTP response or error occurred
# + return - Text response if successful else ConnectorError occured
function checkTextPayloadAndSetErrors(http:Response|error httpResponse) returns @tainted string|ConnectorError {
    if (httpResponse is http:Response) {

        if (httpResponse.statusCode == http:STATUS_OK || httpResponse.statusCode == http:STATUS_CREATED 
            || httpResponse.statusCode == http:STATUS_NO_CONTENT) {
            string|error textResponse = httpResponse.getTextPayload();

            if (textResponse is string) {
                return textResponse;
            } else {
                log:printError(TEXT_ACCESSING_ERROR_MSG, err = textResponse);
                HttpResponseHandlingError httpResponseHandlingError = error(HTTP_RESPONSE_HANDLING_ERROR,
                    message = TEXT_ACCESSING_ERROR_MSG, errorCode = HTTP_RESPONSE_HANDLING_ERROR,
                    cause = textResponse);
                return httpResponseHandlingError;
            }

        } else {
            return handleXmlErrorResponse(httpResponse);
        }
    } else {
        return handleHttpError(httpResponse);
    }
}

# Check HTTP response and return JSON payload if succesful, else set errors and return ConnectorError.
# + httpResponse - HTTP response or error occurred
# + return - JSON response if successful else ConnectorError occured
function checkJsonPayloadAndSetErrors(http:Response|error httpResponse) returns @tainted json|ConnectorError {
    if (httpResponse is http:Response) {

        if (httpResponse.statusCode == http:STATUS_OK || httpResponse.statusCode == http:STATUS_CREATED 
            || httpResponse.statusCode == http:STATUS_NO_CONTENT) {
            json|error response = httpResponse.getJsonPayload();

            if (response is json) {
                return response;
            } else {
                log:printError(JSON_ACCESSING_ERROR_MSG, err = response);
                HttpResponseHandlingError httpResponseHandlingError = error(HTTP_RESPONSE_HANDLING_ERROR,
                    message = JSON_ACCESSING_ERROR_MSG, errorCode = HTTP_RESPONSE_HANDLING_ERROR,
                    cause = response);
                return httpResponseHandlingError;
            }

        } else {
            json|error response = httpResponse.getJsonPayload();
            if (response is json) {
                HttpResponseHandlingError httpResponseHandlingError = error(HTTP_RESPONSE_HANDLING_ERROR,
                    message = response.exceptionMessage.toString(), errorCode = response.exceptionCode.toString());
                return httpResponseHandlingError;
            } else {
                log:printError(ERR_EXTRACTING_ERROR_MSG, err = response);
                HttpResponseHandlingError httpResponseHandlingError = error(HTTP_RESPONSE_HANDLING_ERROR,
                    message = ERR_EXTRACTING_ERROR_MSG, errorCode = HTTP_RESPONSE_HANDLING_ERROR, cause = response);
                return httpResponseHandlingError;
            }
        }
    } else {
        return handleHttpError(httpResponse);
    }
}

# Handle HTTP error response and return HttpResponseHandlingError error.
# + httpResponse - error response
# + return - HttpResponseHandlingError error
function handleXmlErrorResponse(http:Response httpResponse) returns @tainted HttpResponseHandlingError {
    xml|error xmlResponse = httpResponse.getXmlPayload();

    if (xmlResponse is xml) {
        HttpResponseHandlingError httpResponseHandlingError = error(HTTP_RESPONSE_HANDLING_ERROR,
            message = xmlResponse.exceptionMessage.toString(), 
            errorCode = xmlResponse.exceptionCode.toString());
        return httpResponseHandlingError;
    } else {
        log:printError(ERR_EXTRACTING_ERROR_MSG, err = xmlResponse);
        HttpResponseHandlingError httpResponseHandlingError = error(HTTP_RESPONSE_HANDLING_ERROR,
            message = ERR_EXTRACTING_ERROR_MSG, errorCode = HTTP_RESPONSE_HANDLING_ERROR, cause = xmlResponse);
        return httpResponseHandlingError;
    }
}

# Handle HTTP error and return HttpError.
# + return - HttpError error
function handleHttpError( error httpResponse) returns HttpError {
    log:printError(HTTP_ERROR_MSG, err = httpResponse);
    HttpError httpError = error(HTTP_ERROR, message = HTTP_ERROR_MSG, errorCode = HTTP_ERROR, cause = httpResponse);
    return httpError;
}

// # Log and get salesforce error.
// # + responseErr - error occurred
// # + baseErrorMsg - base error message
// # + return - ConnectorError
// function logAndGetConnectorError(error responseErr, string baseErrorMsg) returns ConnectorError {
//     log:printError(baseErrorMsg + " Error: " + responseErr.detail()["message"].toString());
//     return getConnectorError(baseErrorMsg, "500");
// }

// # Get salesforce error.
// # + errMsg - error message
// # + errCode - error code
// # + return - ConnectorError
// function getConnectorError(string errMsg, string errCode) returns ConnectorError {
//     ConnectorError sfError = {
//         message: errMsg,
//         errorCode: errCode
//     };
//     return sfError;
// }

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
                if (payload.exceptionCode.toString() == INVALID_SESSION_ID) {
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

# Get ConnectorError for failed batch.
#
# + batch - Failed Batch
# + return - Returns ConnectorError for failed batch.
function getFailedBatchError(BatchInfo batch) returns ConnectorError {
    ServerError serverError = error(SERVER_ERROR, message = "Failed batch=" + batch.toString(), 
        errorCode = SERVER_ERROR);
    return serverError;
}

# Get ConnectorError for getting results timed out.
#
# + batchId - ID of the batch which getting results timed out
# + numberOfTries - No of times tried
# + waitTime - Wait time between 2 tries
# + return - ConnectorError for getting results timed out
function getResultTimeoutError(string batchId, int numberOfTries, int waitTime) returns ConnectorError {
    int totalTime = numberOfTries * waitTime;
    ServerError serverError = error(SERVER_ERROR, message = "Getting result timed out after " + totalTime.toString() 
        + " (ms), batchId=" + batchId, errorCode = SERVER_ERROR);
    return serverError;
}

# Log waiting message while getting batch results.
#
# + batch - Batch which trying to get results.
function printWaitingMessage(BatchInfo batch) {
    log:printInfo("Waiting to complete the batch, batch=" + batch.toString());
}

# Check batch state and get results for the given no of tries and waiting time.
# 
# + getBatchPointer - pointer function to get batch info
# + getResultsPointer - pointer function to get batch results
# + op - bulk operator object
# + batchId - batch ID
# + numberOfTries - number of times checking the batch state
# + waitTime - time between two tries in ms
# + return - Results array if successful else ConnectorError occured
function checkBatchStateAndGetResults(function(BulkOperator, string) returns (BatchInfo|ConnectorError) getBatchPointer,
    function(BulkOperator, string) returns (Result[]|ConnectorError) getResultsPointer,
    @tainted BulkOperator op, string batchId, int numberOfTries, int waitTime) 
    returns @tainted Result[]|ConnectorError {
    
    int counter = 0;
    while (counter < numberOfTries) {
        BatchInfo|ConnectorError batch = getBatchPointer(op, batchId);
        
        if (batch is BatchInfo) {

            if (batch.state == COMPLETED) {
                return getResultsPointer(op, batchId);
            } else if (batch.state == FAILED) {
                return getFailedBatchError(batch);
            } else {
                printWaitingMessage(batch);
            }

        } else {
            return batch;
        }
        runtime:sleep(waitTime);
        counter = counter + 1;
    }
    return getResultTimeoutError(batchId, numberOfTries, waitTime);
}

# Check batch state and get resultList for the given no of tries and waiting time.
# 
# + getBatchPointer - pointer function to get batch info
# + getResultListPointer - pointer function to get resultList
# + op - bulk operator object
# + batchId - batch ID
# + numberOfTries - number of times checking the batch state
# + waitTime - time between two tries in ms
# + return - string array if successful else ConnectorError occured
function checkBatchStateAndGetResultList(
    function(BulkOperator, string) returns (BatchInfo|ConnectorError) getBatchPointer,
    function(BulkOperator, string) returns (string[]|ConnectorError) getResultListPointer,
    @tainted BulkOperator op, string batchId, int numberOfTries, int waitTime) 
    returns @tainted string[]|ConnectorError {
    
    int counter = 0;
    while (counter < numberOfTries) {
        BatchInfo|ConnectorError batch = getBatchPointer(op, batchId);
        
        if (batch is BatchInfo) {

            if (batch.state == COMPLETED) {
                return getResultListPointer(op, batchId);
            } else if (batch.state == FAILED) {
                return getFailedBatchError(batch);
            } else {
                printWaitingMessage(batch);
            }

        } else {
            return batch;
        }
        runtime:sleep(waitTime);
        counter = counter + 1;
    }
    return getResultTimeoutError(batchId, numberOfTries, waitTime);
}

# Get batch info
# 
# + op - bulk operator client object
# + batchId - batchId
# + return - Batch record if successful else ConnectorError occured
function getBatchPointer(@tainted BulkOperator op, string batchId) returns @tainted BatchInfo|ConnectorError {
    return op->getBatchInfo(batchId);
}

# Get batch results
# 
# + op - bulk operator client object
# + batchId - batchId
# + return - Array of Result records if successful else ConnectorError occured
function getResultsPointer(@tainted BulkOperator op, string batchId) returns @tainted Result[]|ConnectorError {
    SalesforceBaseClient httpBaseClient = op.httpBaseClient;
    string[] paths = [JOB, op.job.id, BATCH, batchId, RESULT];

    if (op is CsvInsertOperator|CsvUpsertOperator|CsvUpdateOperator|CsvDeleteOperator) {
        string|ConnectorError result = httpBaseClient->getCsvRecord(paths);
        if (result is string) {
            return getBatchResults(result);
        } else {
            return result;
        }
    } else if (op is JsonInsertOperator|JsonUpsertOperator|JsonUpdateOperator|JsonDeleteOperator) {
        json|ConnectorError result = httpBaseClient->getJsonRecord(paths);
        if (result is json) {
            return getBatchResults(result);
        } else {
            return result;
        }
    } else {
        xml|ConnectorError result = httpBaseClient->getXmlRecord(paths);
        if (result is xml) {
            return getBatchResults(result);
        } else {
            return result;
        }
    }
}

# Get resultList
# 
# + op - bulk operator client object
# + batchId - batchId
# + return - string array if successful else ConnectorError occured
function getResultListPointer(@tainted BulkOperator op, string batchId) returns @tainted string[]|ConnectorError {
    SalesforceBaseClient httpBaseClient = op.httpBaseClient;
    string[] paths = [JOB, op.job.id, BATCH, batchId, RESULT];

    if (op is CsvQueryOperator|XmlQueryOperator) {
        xml|ConnectorError response = httpBaseClient->getXmlRecord(paths);
        if (response is xml) {
            return getResultList(response);
        } else {
            return response;
        }
    } else {
        json|ConnectorError response = httpBaseClient->getJsonRecord(paths);
        if (response is json) {
            return getResultList(response);
        } else {
            return response;
        }
    }
}
