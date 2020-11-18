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
import ballerina/lang.'int as ints;
import ballerina/lang.'float as floats;
import ballerina/lang.'string as strings;
import ballerina/lang.'xml as xmllib;

# Check HTTP response and return XML payload if succesful, else set errors and return Error.
# + httpResponse - HTTP response or error occurred
# + return - XML response if successful else Error occured
isolated function checkXmlPayloadAndSetErrors(http:Response|http:Payload|error httpResponse) returns @tainted xml|Error {
    if (httpResponse is http:Response) {

        if (httpResponse.statusCode == http:STATUS_OK || httpResponse.statusCode == http:STATUS_CREATED 
            || httpResponse.statusCode == http:STATUS_NO_CONTENT) {
            xml|error xmlResponse = httpResponse.getXmlPayload();

            if (xmlResponse is xml) {
                return xmlResponse;
            } else {
                log:printError(XML_ACCESSING_ERROR_MSG, err = xmlResponse);
                return Error(XML_ACCESSING_ERROR_MSG, xmlResponse);
            }

        } else {
            return handleXmlErrorResponse(httpResponse);
        }
    } else if (httpResponse is http:Payload) {        
        return Error(UNREACHABLE_STATE);
    } else {
        return handleHttpError(httpResponse);
    }
}

# Check HTTP response and return Text payload if succesful, else set errors and return Error.
# + httpResponse - HTTP response or error occurred
# + return - Text response if successful else Error occured
isolated function checkTextPayloadAndSetErrors(http:Response|http:Payload|error httpResponse) returns @tainted string|Error {
    if (httpResponse is http:Response) {

        if (httpResponse.statusCode == http:STATUS_OK || httpResponse.statusCode == http:STATUS_CREATED 
            || httpResponse.statusCode == http:STATUS_NO_CONTENT) {
            string|error textResponse = httpResponse.getTextPayload();

            if (textResponse is string) {
                return textResponse;
            } else {
                log:printError(TEXT_ACCESSING_ERROR_MSG, err = textResponse);
                return Error(TEXT_ACCESSING_ERROR_MSG, textResponse);
            }

        } else {
            return handleXmlErrorResponse(httpResponse);
        }
    } else if (httpResponse is http:Payload) {
        return Error(UNREACHABLE_STATE);
    } else {
        return handleHttpError(httpResponse);
    }
}

# Check HTTP response and return JSON payload if succesful, else set errors and return Error.
# + httpResponse - HTTP response or error occurred
# + return - JSON response if successful else Error occured
isolated function checkJsonPayloadAndSetErrors(http:Response|http:Payload|error httpResponse) returns @tainted json|Error {
    if (httpResponse is http:Response) {

        if (httpResponse.statusCode == http:STATUS_OK || httpResponse.statusCode == http:STATUS_CREATED 
            || httpResponse.statusCode == http:STATUS_NO_CONTENT) {
            json|error response = httpResponse.getJsonPayload();
            if (response is json) {
                return response;
            } else {
                log:printError(JSON_ACCESSING_ERROR_MSG, err = response);
                return Error(JSON_ACCESSING_ERROR_MSG, response);
            }
        } else {
            return handleJsonErrorResponse(httpResponse);
        }
    } else if (httpResponse is http:Payload) {
        return Error(UNREACHABLE_STATE);
    } else {
        return handleHttpError(httpResponse);
    }
}

# Check query request and return query string
#
# + httpResponse - HTTP response or error occurred
# + return - Query string response if successful or else an sfdc:Error
isolated function getQueryRequest(http:Response|http:Payload|error httpResponse, JOBTYPE jobtype) returns @tainted string|Error {
    if (httpResponse is http:Response) {
        if (httpResponse.statusCode == http:STATUS_OK) {
            string|error textResponse = httpResponse.getTextPayload();
            if (textResponse is string) {
                return textResponse;
            } else {
                log:printError(TEXT_ACCESSING_ERROR_MSG, err = textResponse);
                return Error(TEXT_ACCESSING_ERROR_MSG, textResponse);
            }
        } else {
            if (JSON == jobtype) {
                return handleJsonErrorResponse(httpResponse);
            } else {
                return handleXmlErrorResponse(httpResponse);
            }
        }
    } else if (httpResponse is http:Payload) {
        return Error(UNREACHABLE_STATE);
    } else {
        return handleHttpError(httpResponse);
    }
}

# Handle HTTP error response and return error.
# + httpResponse - error response
# + return - error
isolated function handleXmlErrorResponse(http:Response httpResponse) returns @tainted Error {
    xml|error xmlResponse = httpResponse.getXmlPayload();
    xmlns "http://www.force.com/2009/06/asyncapi/dataload" as ns;

    if (xmlResponse is xml) {
        Error httpResponseHandlingError = Error((xmlResponse/<ns:exceptionCode>/*).toString());
        return httpResponseHandlingError;
    } else {
        log:printError(ERR_EXTRACTING_ERROR_MSG, err = xmlResponse);
        return Error(ERR_EXTRACTING_ERROR_MSG, xmlResponse);
    }
}

# Handle HTTP error response and return Error.
# + httpResponse - error response
# + return - error
isolated function handleJsonErrorResponse(http:Response httpResponse) returns @tainted Error {
    json|error response = httpResponse.getJsonPayload();
    if (response is json) {
        Error httpResponseHandlingError = Error(response.exceptionCode.toString());
        return httpResponseHandlingError;
    } else {
        log:printError(ERR_EXTRACTING_ERROR_MSG, err = response);
        return Error(ERR_EXTRACTING_ERROR_MSG, response);
    }
} 

# Handle HTTP error and return Error.
# + return - Constructed error
isolated function handleHttpError( error httpResponse) returns Error {
    log:printError(HTTP_ERROR_MSG, err = httpResponse);
    Error httpError = Error(HTTP_ERROR_MSG, httpResponse);
    return httpError;
}

# Convert string to integer
# + value - string value
# + return - converted integer
isolated function getIntValue(string value) returns int {
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
isolated function getFloatValue(string value) returns float {
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
isolated function getBooleanValue(string value) returns boolean {
    if (value == "true") {
        return true;
    } else if (value == "false") {
        return false;
    } else {
        log:printError("Invalid boolean value, string value='" + value + "' ", err = ());
        return false;
    }
}

# Logs, prepares, and returns the `AuthenticationError`.
#
# + message -The error message.
# + err - The `error` instance.
# + return - Returns the prepared `AuthenticationError` instance.
isolated function prepareAuthenticationError(string message, error? err = ()) returns http:AuthenticationError {
    log:printDebug(function () returns string { return message; });
    if (err is error) {
        http:AuthenticationError preparedError = http:AuthenticationError(message, cause = err);
        return preparedError;
    }
    http:AuthenticationError preparedError = http:AuthenticationError(message);
    return preparedError;
}

# Creates a map out of the headers of the HTTP response.
#
# + resp - The `Response` instance.
# + return - Returns the map of the response headers.
isolated function createResponseHeaderMap(http:Response resp) returns @tainted map<anydata> {
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
                if ((payload/<exceptionCode>/*).toString() == INVALID_SESSION_ID) {
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

# Convert ReadableByteChannel to string.
# 
# + rbc - ReadableByteChannel
# + return - converted string
function convertToString(io:ReadableByteChannel rbc) returns @tainted string|Error {
    byte[] readContent;
    string textContent = "";
    while (true) {
        byte[]|io:Error result = rbc.read(1000);
        if (result is io:EofError) {
            break;
        } else if (result is io:Error) {
            string errMsg = "Error occurred while reading from Readable Byte Channel.";
            log:printError(errMsg, err = result);
            return Error(errMsg, result);
        } else {
            readContent = result;
            string|error readContentStr = strings:fromBytes(readContent);
            if (readContentStr is string) {
                textContent = textContent + readContentStr; 
            } else {
                string errMsg = "Error occurred while converting readContent byte array to string.";
                log:printError(errMsg, err = readContentStr);
                return Error(errMsg, readContentStr);
            }                 
        }
    }
    return textContent;
}

# Convert ReadableByteChannel to json.
# 
# + rbc - ReadableByteChannel
# + return - converted json
function convertToJson(io:ReadableByteChannel rbc) returns @tainted json|Error {
    io:ReadableCharacterChannel|io:Error rch = new(rbc, ENCODING_CHARSET);

    if (rch is io:Error) {
        string errMsg = "Error occurred while converting ReadableByteChannel to ReadableCharacterChannel.";
        log:printError(errMsg, err = rch);
        return Error(errMsg, rch);
    } else {
        json|error jsonContent = rch.readJson();

        if (jsonContent is json) {
            return jsonContent;
        } else {
            string errMsg = "Error occurred while reading ReadableCharacterChannel as json.";
            log:printError(errMsg, err = jsonContent);
            return Error(errMsg, jsonContent);
        }
    }
}

# Convert ReadableByteChannel to xml.
# 
# + rbc - ReadableByteChannel
# + return - converted xml
function convertToXml(io:ReadableByteChannel rbc) returns @tainted xml|Error {
    io:ReadableCharacterChannel|io:Error rch = new(rbc, ENCODING_CHARSET);

    if (rch is io:Error) {
        string errMsg = "Error occurred while converting ReadableByteChannel to ReadableCharacterChannel.";
        log:printError(errMsg, err = rch);
        return Error(errMsg, rch);
    } else {
        xml|error xmlContent = rch.readXml();

        if (xmlContent is xml) {
            return xmlContent;
        } else {
            string errMsg = "Error occurred while reading ReadableCharacterChannel as xml.";
            log:printError(errMsg, err = xmlContent);
            return Error(errMsg, xmlContent);
        }
    }
}

function getJsonQueryResult(json resultlist, string path, http:Client httpClient) returns @tainted json|Error {
    json[] finalResults = [];
    http:Request req = new;
    //result list is always a json[]
    if (resultlist is json[]) {
        foreach var item in resultlist {
            string resultId = item.toString();
            var response = httpClient->get(path + "/"+ resultId, req);
            json result = check checkJsonPayloadAndSetErrors(response);
            //result is always a json[]
            if (result is json[]) {
                finalResults = mergeJson(finalResults, result);
            }
        }
        return finalResults;
    }
    return resultlist;    
}

function getXmlQueryResult(xml resultlist, string path, http:Client httpClient) returns @tainted xml|Error {
    xml finalResults = xml `<queryResult xmlns="http://www.force.com/2009/06/asyncapi/dataload"/>`;
    http:Request req = new;
    foreach var item in resultlist/<*> {
        if (item is xml) {
            string resultId = (item/*).toString();
            var response = httpClient->get(path + "/"+ resultId, req);
            xml result = check checkXmlPayloadAndSetErrors(response);
            finalResults = mergeXml(finalResults, result);
        }        
    }    
    return finalResults;
}

function getCsvQueryResult(xml resultlist, string path, http:Client httpClient) returns @tainted string|Error {
    string finalResults = "";
    http:Request req = new;
    int i = 0;
    foreach var item in resultlist/<*> {
        if (item is xml) {
            string resultId = (item/*).toString();
            var response = httpClient->get(path + "/"+ resultId, req);
            string result = check checkTextPayloadAndSetErrors(response);
            if (i == 0) {
                finalResults = result;
            } else {
                finalResults = mergeCsv(finalResults, result);
            }
        } 
        i = i + 1;      
    } 
    return finalResults;  
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
    list1ele.setChildren(list1ele.getChildren().elements()+list2ele.getChildren().elements());
    return list1ele;
}

isolated function mergeCsv(string list1, string list2) returns string{
    int? inof = list2.indexOf("\n");
    string finalList = list1;
    if (inof is int) {
        string list2new = list2.substring(inof);            
        finalList = finalList.concat(list2new);   
    }
    return finalList;
}
