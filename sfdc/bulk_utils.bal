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

import ballerina/log;
import ballerina/http;
import ballerina/io;
import ballerina/lang.'int as ints;
import ballerina/lang.'float as floats;
import ballerina/lang.'string as strings;
import ballerina/lang.'xml as xmllib;
import ballerina/regex;

# Check HTTP response and return XML payload if succesful, else set errors and return Error.
# 
# + httpResponse - HTTP response or error occurred
# + return - XML response if successful else Error occured
isolated function checkXmlPayloadAndSetErrors(http:Response|http:PayloadType|error httpResponse) returns 
                                              @tainted xml|Error {
    if (httpResponse is http:Response) {
        if (httpResponse.statusCode == http:STATUS_OK || httpResponse.statusCode == http:STATUS_CREATED || httpResponse.
        statusCode == http:STATUS_NO_CONTENT) {
            xml|error xmlResponse = httpResponse.getXmlPayload();

            if (xmlResponse is xml) {
                return xmlResponse;
            } else {
                log:printError(XML_ACCESSING_ERROR_MSG, 'error = xmlResponse);
                return error Error(XML_ACCESSING_ERROR_MSG, xmlResponse);
            }
        } else {
            return handleXmlErrorResponse(httpResponse);
        }
    } else if (httpResponse is http:PayloadType) {
        return error Error(UNREACHABLE_STATE);
    } else {
        return handleHttpError(httpResponse);
    }
}

# Check HTTP response and return Text payload if succesful, else set errors and return Error.
# 
# + httpResponse - HTTP response or error occurred
# + return - Text response if successful else Error occured
isolated function checkTextPayloadAndSetErrors(http:Response|http:PayloadType|error httpResponse) returns 
                                               @tainted string|Error {
    if (httpResponse is http:Response) {
        if (httpResponse.statusCode == http:STATUS_OK || httpResponse.statusCode == http:STATUS_CREATED || httpResponse.
        statusCode == http:STATUS_NO_CONTENT) {
            string|error textResponse = httpResponse.getTextPayload();

            if (textResponse is string) {
                return textResponse;
            } else {
                log:printError(TEXT_ACCESSING_ERROR_MSG, 'error = textResponse);
                return error Error(TEXT_ACCESSING_ERROR_MSG, textResponse);
            }
        } else {
            return handleXmlErrorResponse(httpResponse);
        }
    } else if (httpResponse is http:PayloadType) {
        return error Error(UNREACHABLE_STATE);
    } else {
        return handleHttpError(httpResponse);
    }
}

# Check HTTP response and return JSON payload if succesful, else set errors and return Error.
# 
# + httpResponse - HTTP response or error occurred
# + return - JSON response if successful else Error occured
isolated function checkJsonPayloadAndSetErrors(http:Response|http:PayloadType|error httpResponse) returns 
                                               @tainted json|Error {
    if (httpResponse is http:Response) {
        if (httpResponse.statusCode == http:STATUS_OK || httpResponse.statusCode == http:STATUS_CREATED || httpResponse.
        statusCode == http:STATUS_NO_CONTENT) {
            json|error response = httpResponse.getJsonPayload();
            if (response is json) {
                return response;
            } else {
                log:printError(JSON_ACCESSING_ERROR_MSG, 'error = response);
                return error Error(JSON_ACCESSING_ERROR_MSG, response);
            }
        } else {
            return handleJsonErrorResponse(httpResponse);
        }
    } else if (httpResponse is http:PayloadType) {
        return error Error(UNREACHABLE_STATE);
    } else {
        return handleHttpError(httpResponse);
    }
}

# Check query request and return query string
#
# + httpResponse - HTTP response or error occurred  
# + jobtype - Job type
# + return - Query string response if successful or else an sfdc:Error
isolated function getQueryRequest(http:Response|http:PayloadType|error httpResponse, JOBTYPE jobtype) returns 
                                  @tainted string|Error {
    if (httpResponse is http:Response) {
        if (httpResponse.statusCode == http:STATUS_OK) {
            string|error textResponse = httpResponse.getTextPayload();
            if (textResponse is string) {
                return textResponse;
            } else {
                log:printError(TEXT_ACCESSING_ERROR_MSG, 'error = textResponse);
                return error Error(TEXT_ACCESSING_ERROR_MSG, textResponse);
            }
        } else {
            if (JSON == jobtype) {
                return handleJsonErrorResponse(httpResponse);
            } else {
                return handleXmlErrorResponse(httpResponse);
            }
        }
    } else if (httpResponse is http:PayloadType) {
        return error Error(UNREACHABLE_STATE);
    } else {
        return handleHttpError(httpResponse);
    }
}

# Handle HTTP error response and return error.
# 
# + httpResponse - error response
# + return - error
isolated function handleXmlErrorResponse(http:Response httpResponse) returns @tainted Error {
    xml|error xmlResponse = httpResponse.getXmlPayload();
    xmlns "http://www.force.com/2009/06/asyncapi/dataload" as ns;
    if (xmlResponse is xml) {
        Error httpResponseHandlingError = error Error((xmlResponse/<ns:exceptionCode>/*).toString());
        return httpResponseHandlingError;
    } else {
        log:printError(ERR_EXTRACTING_ERROR_MSG, 'error = xmlResponse);
        return error Error(ERR_EXTRACTING_ERROR_MSG, xmlResponse);
    }
}

# Handle HTTP error response and return Error.
# 
# + httpResponse - error response
# + return - error
isolated function handleJsonErrorResponse(http:Response httpResponse) returns @tainted Error {
    json|error response = httpResponse.getJsonPayload();
    if (response is json) {
        json|error resExceptionCode = response.exceptionCode;
        if (resExceptionCode is json) {
            Error httpResponseHandlingError = error Error(resExceptionCode.toString());
            return httpResponseHandlingError;
        } else {
            return error Error(resExceptionCode.message());
        }
    } else {
        log:printError(ERR_EXTRACTING_ERROR_MSG, 'error = response);
        return error Error(ERR_EXTRACTING_ERROR_MSG, response);
    }
}

# Handle HTTP error and return Error.
#
# + httpResponse - Http response
# + return - Constructed error
isolated function handleHttpError(error httpResponse) returns Error {
    log:printError(HTTP_ERROR_MSG, 'error = httpResponse);
    Error httpError = error Error(HTTP_ERROR_MSG, httpResponse);
    return httpError;
}

# Convert string to integer
# 
# + value - string value
# + return - converted integer
isolated function getIntValue(string value) returns int {
    int|error intValue = ints:fromString(value);
    if (intValue is int) {
        return intValue;
    } else {
        log:printError("String to int conversion failed, string value='" + value + "' ", 'error = intValue);
        panic intValue;
    }
}

# Convert string to float
# 
# + value - string value
# + return - converted float
isolated function getFloatValue(string value) returns float {
    float|error floatValue = floats:fromString(value);
    if (floatValue is float) {
        return floatValue;
    } else {
        log:printError("String to float conversion failed, string value='" + value + "' ", 'error = floatValue);
        panic floatValue;
    }
}

# Convert string to boolean
# 
# + value - string value
# + return - converted boolean
isolated function getBooleanValue(string value) returns boolean {
    if (value == "true") {
        return true;
    } else if (value == "false") {
        return false;
    } else {
        log:printError("Invalid boolean value, string value='" + value + "' ", 'error = ());
        return false;
    }
}

# Logs, prepares, and returns the `ClientAuthError`.
#
# + message - The error message.
# + err - The `error` instance.
# + return - Returns the prepared `ClientAuthError` instance.
isolated function prepareClientAuthError(string message, error? err = ()) returns http:ClientAuthError {
    log:printError(message, 'error = err);
    if (err is error) {
        return error http:ClientAuthError(message, err);
    }
    return error http:ClientAuthError(message);
}

# Creates a map out of the headers of the HTTP response.
#
# + resp - The `Response` instance.
# + return - Returns the map of the response headers.
isolated function createResponseHeaderMap(http:Response resp) returns @tainted map<anydata> {
    map<anydata> headerMap = {};
    // If session ID is invalid, set staus code as 401.
    if (resp.statusCode == http:STATUS_BAD_REQUEST) {
        string|http:HeaderNotFoundError contentType = resp.getHeader(CONTENT_TYPE);
        if (contentType is string) {
            if (contentType == APP_JSON) {
                json|error payload = resp.getJsonPayload();
                if (payload is json) {
                    json|error receivedExceptionCode = payload.exceptionCode;
                    if (receivedExceptionCode is json) {
                        if (receivedExceptionCode.toString() == INVALID_SESSION_ID) {
                            headerMap[STATUS_CODE] = http:STATUS_UNAUTHORIZED;
                        }
                    } else {
                        log:printError("Invalid Exception Code", 'error = receivedExceptionCode);
                    }
                } else {
                    log:printError("Invalid payload", 'error = payload);
                }
            } else if (contentType == APP_XML) {
                xml|error payload = resp.getXmlPayload();
                if (payload is xml) {
                    if ((payload/<exceptionCode>/*).toString() == INVALID_SESSION_ID) {
                        headerMap[STATUS_CODE] = http:STATUS_UNAUTHORIZED;
                    }
                } else {
                    log:printError("Invalid payload", 'error = payload);
                }
            } else {
                log:printError("Invalid contentType, contentType='" + contentType + "' ", 'error = ());
            }
        } else {
            log:printError("CONTENT_TYPE Header not found ", 'error = contentType);
        }
    } else {
        headerMap[STATUS_CODE] = resp.statusCode;
    }

    string[] headerNames = resp.getHeaderNames();
    foreach string header in headerNames {
        string[]|http:HeaderNotFoundError headerValues = resp.getHeaders(<@untainted>header);
        if (headerValues is string[]) {
            headerMap[header] = headerValues;
        }
    }
    return headerMap;
}

# Convert ReadableByteChannel to string.
#
# + rbc - ReadableByteChannel
# + return - converted string
isolated function convertToString(io:ReadableByteChannel rbc) returns @tainted string|Error {
    byte[] readContent;
    string textContent = "";
    while (true) {
        byte[]|io:Error result = rbc.read(1000);
        if (result is io:EofError) {
            break;
        } else if (result is io:Error) {
            string errMsg = "Error occurred while reading from Readable Byte Channel.";
            log:printError(errMsg, 'error = result);
            return error Error(errMsg, result);
        } else {
            readContent = result;
            string|error readContentStr = strings:fromBytes(readContent);
            if (readContentStr is string) {
                textContent = textContent + readContentStr;
            } else {
                string errMsg = "Error occurred while converting readContent byte array to string.";
                log:printError(errMsg, 'error = readContentStr);
                return error Error(errMsg, readContentStr);
            }
        }
    }
    return textContent;
}

# Convert ReadableByteChannel to json.
#
# + rbc - ReadableByteChannel
# + return - converted json
isolated function convertToJson(io:ReadableByteChannel rbc) returns @tainted json|Error {
    io:ReadableCharacterChannel|io:Error rch = new (rbc, ENCODING_CHARSET);
    if (rch is io:Error) {
        string errMsg = "Error occurred while converting ReadableByteChannel to ReadableCharacterChannel.";
        log:printError(errMsg, 'error = rch);
        return error Error(errMsg, rch);
    } else {
        json|error jsonContent = rch.readJson();

        if (jsonContent is json) {
            return jsonContent;
        } else {
            string errMsg = "Error occurred while reading ReadableCharacterChannel as json.";
            log:printError(errMsg, 'error = jsonContent);
            return error Error(errMsg, jsonContent);
        }
    }
}

# Convert ReadableByteChannel to xml.
#
# + rbc - ReadableByteChannel
# + return - converted xml
isolated function convertToXml(io:ReadableByteChannel rbc) returns @tainted xml|Error {
    io:ReadableCharacterChannel|io:Error rch = new (rbc, ENCODING_CHARSET);
    if (rch is io:Error) {
        string errMsg = "Error occurred while converting ReadableByteChannel to ReadableCharacterChannel.";
        log:printError(errMsg, 'error = rch);
        return error Error(errMsg, rch);
    } else {
        xml|error xmlContent = rch.readXml();

        if (xmlContent is xml) {
            return xmlContent;
        } else {
            string errMsg = "Error occurred while reading ReadableCharacterChannel as xml.";
            log:printError(errMsg, 'error = xmlContent);
            return error Error(errMsg, xmlContent);
        }
    }
}

isolated function getJsonQueryResult(json resultlist, string path, http:Client httpClient, 
                                     http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler clientHandler) returns 
                                     @tainted json|Error {
    json[] finalResults = [];
    http:ClientAuthError|map<string> headerMap = getBulkApiHeaders(clientHandler);
    if (headerMap is map<string|string[]>) {
        //result list is always a json[]
        if (resultlist is json[]) {
            foreach var item in resultlist {
                string resultId = item.toString();
                http:Response|error response = httpClient->get(path + "/" + resultId, headerMap);
                json result = check checkJsonPayloadAndSetErrors(response);
                //result is always a json[]
                if (result is json[]) {
                    finalResults = mergeJson(finalResults, result);
                }
            }
            return finalResults;
        }
        return resultlist;
    } else {
        return error Error(headerMap.message(), err = headerMap);
    }
}

isolated function getXmlQueryResult(xml resultlist, string path, http:Client httpClient, 
                                    http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler clientHandler) returns 
                                    @tainted xml|Error {
    xml finalResults = xml `<queryResult xmlns="http://www.force.com/2009/06/asyncapi/dataload"/>`;
    http:ClientAuthError|map<string> headerMap = getBulkApiHeaders(clientHandler);
    if (headerMap is map<string|string[]>) {
        foreach var item in resultlist/<*> {
            string resultId = (item/*).toString();
            http:Response|error response = httpClient->get(path + "/" + resultId, headerMap);
            xml result = check checkXmlPayloadAndSetErrors(response);
            finalResults = mergeXml(finalResults, result);
        }
        return finalResults;
    } else {
        return error Error(headerMap.message(), err = headerMap);
    }
}

isolated function getCsvQueryResult(xml resultlist, string path, http:Client httpClient, 
                                    http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler clientHandler) returns 
                                    @tainted string|Error {
    string finalResults = "";
    http:ClientAuthError|map<string> headerMap = getBulkApiHeaders(clientHandler);
    if (headerMap is map<string|string[]>) {
        int i = 0;
        foreach var item in resultlist/<*> {
            string resultId = (item/*).toString();
            http:Response|error response = httpClient->get(path + "/" + resultId, headerMap);
            string result = check checkTextPayloadAndSetErrors(response);
            if (i == 0) {
                finalResults = result;
            } else {
                finalResults = mergeCsv(finalResults, result);
            }
            i = i + 1;
        }
        return finalResults;
    } else {
        return error Error(headerMap.message(), err = headerMap);
    }
}

isolated function mergeJson(json[] list1, json[] list2) returns json[] {
    foreach var item in list2 {
        list1[list1.length()] = item;
    }
    return list1;
}

isolated function mergeXml(xml list1, xml list2) returns xml {
    xmllib:Element list1ele = <xmllib:Element>list1;
    xmllib:Element list2ele = <xmllib:Element>list2;
    list1ele.setChildren(list1ele.getChildren().elements() + list2ele.getChildren().elements());
    return list1ele;
}

isolated function mergeCsv(string list1, string list2) returns string {
    int? inof = list2.indexOf("\n");
    string finalList = list1;
    if (inof is int) {
        string list2new = list2.substring(inof);
        finalList = finalList.concat(list2new);
    }
    return finalList;
}

isolated function getBulkApiHeaders(http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler clientHandler, 
                                    string? contentType = ()) returns map<string>|http:ClientAuthError {
    string token;
    map<string> finalHeaderMap = {};
    map<string|string[]> authorizationHeaderMap;
    if (clientHandler is http:ClientOAuth2Handler) {
        authorizationHeaderMap = check clientHandler.getSecurityHeaders();
    } else {
        authorizationHeaderMap = check clientHandler.getSecurityHeaders();
    }
    token = (regex:split(<string>authorizationHeaderMap["Authorization"], " "))[1];
    finalHeaderMap[X_SFDC_SESSION] = token;
    if (contentType != ()) {
        finalHeaderMap[CONTENT_TYPE] = <string>contentType;
    }
    return finalHeaderMap;
}
