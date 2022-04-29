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
import ballerinax/salesforce as sfdc;

isolated string csvContent = EMPTY_STRING;

# Check HTTP response and return XML payload if succesful, else set errors and return Error.
#
# + httpResponse - HTTP response or error occurred
# + return - XML response if successful else Error occured
isolated function checkXmlPayloadAndSetErrors(http:Response httpResponse) returns xml|error {
    if httpResponse.statusCode == http:STATUS_OK || httpResponse.statusCode == http:STATUS_CREATED || httpResponse.
    statusCode == http:STATUS_NO_CONTENT {
        return check httpResponse.getXmlPayload();
    } else {
        return handleXmlErrorResponse(httpResponse);
    }
}

# Check HTTP response and return Text payload if succesful, else set errors and return Error.
#
# + httpResponse - HTTP response or error occurred
# + return - Text response if successful else Error occured
isolated function checkTextPayloadAndSetErrors(http:Response httpResponse) returns string|error {
    if httpResponse.statusCode == http:STATUS_OK || httpResponse.statusCode == http:STATUS_CREATED || httpResponse.
    statusCode == http:STATUS_NO_CONTENT {
        return check httpResponse.getTextPayload();
    } else {
        return handleXmlErrorResponse(httpResponse);
    }
}

# Check HTTP response and return JSON payload if succesful, else set errors and return Error.
#
# + httpResponse - HTTP response or error occurred
# + return - JSON response if successful else Error occured
isolated function checkJsonPayloadAndSetErrors(http:Response httpResponse) returns json|error {
    if httpResponse.statusCode == http:STATUS_OK || httpResponse.statusCode == http:STATUS_CREATED || httpResponse.
    statusCode == http:STATUS_NO_CONTENT {
        return check httpResponse.getJsonPayload();
    } else {
        return handleJsonErrorResponse(httpResponse);
    }
}

# Check query request and return query string
#
# + httpResponse - HTTP response or error occurred  
# + jobtype - Job type
# + return - Query string response if successful or else an sfdc:Error
isolated function getQueryRequest(http:Response httpResponse, JobType jobtype) returns string|error {
    if httpResponse.statusCode == http:STATUS_OK {
        return check httpResponse.getTextPayload();
    } else {
        if JSON == jobtype {
            return handleJsonErrorResponse(httpResponse);
        } else {
            return handleXmlErrorResponse(httpResponse);
        }
    }
}

# Handle HTTP error response and return error.
#
# + httpResponse - error response
# + return - error
isolated function handleXmlErrorResponse(http:Response httpResponse) returns error {
    xml|error xmlResponse = httpResponse.getXmlPayload();
    xmlns "http://www.force.com/2009/06/asyncapi/dataload" as ns;
    if xmlResponse is xml {
        return error((xmlResponse/<ns:exceptionCode>/*).toString());
    } else {
        log:printError(sfdc:ERR_EXTRACTING_ERROR_MSG, 'error = xmlResponse);
        return error(sfdc:ERR_EXTRACTING_ERROR_MSG, xmlResponse);
    }
}

# Handle HTTP error response and return Error.
#
# + httpResponse - error response
# + return - error
isolated function handleJsonErrorResponse(http:Response httpResponse) returns error {
    json|error response = httpResponse.getJsonPayload();
    if response is json {
        json|error resExceptionCode = response.exceptionCode;
        if resExceptionCode is json {
            return error(resExceptionCode.toString());
        } else {
            return error(resExceptionCode.message());
        }
    } else {
        log:printError(sfdc:ERR_EXTRACTING_ERROR_MSG, 'error = response);
        return error(sfdc:ERR_EXTRACTING_ERROR_MSG, response);
    }
}

# Convert string to integer
#
# + value - string value
# + return - converted integer
isolated function getIntValue(string value) returns int {
    int|error intValue = ints:fromString(value);
    if intValue is int {
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
    if floatValue is float {
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
    if value == "true" {
        return true;
    } else if value == "false" {
        return false;
    } else {
        log:printError("Invalid boolean value, string value='" + value + "' ", 'error = ());
        return false;
    }
}

# Convert ReadableByteChannel to string.
#
# + rbc - ReadableByteChannel
# + return - converted string
isolated function convertToString(io:ReadableByteChannel rbc) returns string|error {
    byte[] readContent;
    string textContent = EMPTY_STRING;
    while (true) {
        byte[]|io:Error result = rbc.read(1000);
        if result is io:EofError {
            break;
        } else if result is io:Error {
            string errMsg = "Error occurred while reading from Readable Byte Channel.";
            log:printError(errMsg, 'error = result);
            return error(errMsg, result);
        } else {
            readContent = result;
            string|error readContentStr = strings:fromBytes(readContent);
            if readContentStr is string {
                textContent = textContent + readContentStr;
            } else {
                string errMsg = "Error occurred while converting readContent byte array to string.";
                log:printError(errMsg, 'error = readContentStr);
                return error(errMsg, readContentStr);
            }
        }
    }
    return textContent;
}

# Convert ReadableByteChannel to json.
#
# + rbc - ReadableByteChannel
# + return - converted json
isolated function convertToJson(io:ReadableByteChannel rbc) returns json|error {
    io:ReadableCharacterChannel|io:Error rch = new (rbc, ENCODING_CHARSET);
    if rch is io:Error {
        string errMsg = "Error occurred while converting ReadableByteChannel to ReadableCharacterChannel.";
        log:printError(errMsg, 'error = rch);
        return error(errMsg, rch);
    } else {
        json|error jsonContent = rch.readJson();

        if jsonContent is json {
            return jsonContent;
        } else {
            string errMsg = "Error occurred while reading ReadableCharacterChannel as json.";
            log:printError(errMsg, 'error = jsonContent);
            return error(errMsg, jsonContent);
        }
    }
}

# Convert ReadableByteChannel to xml.
#
# + rbc - ReadableByteChannel
# + return - converted xml
isolated function convertToXml(io:ReadableByteChannel rbc) returns xml|error {
    io:ReadableCharacterChannel|io:Error rch = new (rbc, ENCODING_CHARSET);
    if rch is io:Error {
        string errMsg = "Error occurred while converting ReadableByteChannel to ReadableCharacterChannel.";
        log:printError(errMsg, 'error = rch);
        return error(errMsg, rch);
    } else {
        xml|error xmlContent = rch.readXml();

        if xmlContent is xml {
            return xmlContent;
        } else {
            string errMsg = "Error occurred while reading ReadableCharacterChannel as xml.";
            log:printError(errMsg, 'error = xmlContent);
            return error(errMsg, xmlContent);
        }
    }
}

# Convert string[][] or stream<string[], error?> to string.
#
# + stringCsvInput - Multi dimentional array of strings or a stream of strings
# + return - converted string
isolated function convertStringListToString(string[][]|stream<string[], error?> stringCsvInput) returns string|error {
    lock {
        csvContent = EMPTY_STRING;
    }
    if stringCsvInput is string[][] {
        foreach var row in stringCsvInput {
            lock {
                csvContent += row.reduce(isolated function (string s, string t) returns string { 
                    return s.concat(COMMA, t);
                }, EMPTY_STRING).substring(1) + NEW_LINE;
            }
        }
    } else {
        check stringCsvInput.forEach(isolated function(string[] row) {
            lock {
                csvContent += row.reduce(isolated function (string s, string t) returns string { 
                    return s.concat(COMMA, t);
                }, EMPTY_STRING).substring(1) + NEW_LINE;

            }
        });
    }
    lock {
        return csvContent;
    }
}

isolated function getJsonQueryResult(json resultlist, string path, http:Client httpClient, http:ClientOAuth2Handler|
                                     http:ClientBearerTokenAuthHandler clientHandler) returns json|error {
    json[] finalResults = [];
    http:ClientAuthError|map<string> headerMap = getBulkApiHeaders(clientHandler);
    if headerMap is map<string|string[]> {
        //result list is always a json[]
        if resultlist is json[] {
            foreach json item in resultlist {
                string resultId = item.toString();
                http:Response response = check httpClient->get(path + FORWARD_SLASH + resultId, headerMap);
                json result = check checkJsonPayloadAndSetErrors(response);
                //result is always a json[]
                if result is json[] {
                    finalResults = mergeJson(finalResults, result);
                }
            }
            return finalResults;
        }
        return resultlist;
    } else {
        return error(headerMap.message(), err = headerMap);
    }
}

isolated function getXmlQueryResult(xml resultlist, string path, http:Client httpClient, http:ClientOAuth2Handler|
                                    http:ClientBearerTokenAuthHandler clientHandler) returns xml|error {
    xml finalResults = xml `<queryResult xmlns="http://www.force.com/2009/06/asyncapi/dataload"/>`;
    http:ClientAuthError|map<string> headerMap = getBulkApiHeaders(clientHandler);
    if headerMap is map<string|string[]> {
        foreach var item in resultlist/<*> {
            string resultId = (item/*).toString();
            http:Response response = check httpClient->get(path + FORWARD_SLASH + resultId, headerMap);
            xml result = check checkXmlPayloadAndSetErrors(response);
            finalResults = mergeXml(finalResults, result);
        }
        return finalResults;
    } else {
        return error(headerMap.message(), err = headerMap);
    }
}

isolated function getCsvQueryResult(xml resultlist, string path, http:Client httpClient, http:ClientOAuth2Handler|
                                    http:ClientBearerTokenAuthHandler clientHandler) returns string|error {
    string finalResults = EMPTY_STRING;
    http:ClientAuthError|map<string> headerMap = getBulkApiHeaders(clientHandler);
    if headerMap is map<string|string[]> {
        int i = 0;
        foreach var item in resultlist/<*> {
            string resultId = (item/*).toString();
            http:Response response = check httpClient->get(path + FORWARD_SLASH + resultId, headerMap);
            string result = check checkTextPayloadAndSetErrors(response);
            if i == 0 {
                finalResults = result;
            } else {
                finalResults = mergeCsv(finalResults, result);
            }
            i = i + 1;
        }
        return finalResults;
    } else {
        return error(headerMap.message(), err = headerMap);
    }
}

isolated function mergeJson(json[] list1, json[] list2) returns json[] {
    foreach json item in list2 {
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
    int? inof = list2.indexOf(NEW_LINE);
    string finalList = list1;
    if inof is int {
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
    if clientHandler is http:ClientOAuth2Handler {
        authorizationHeaderMap = check clientHandler.getSecurityHeaders();
    } else if clientHandler is http:ClientBearerTokenAuthHandler {
        authorizationHeaderMap = check clientHandler.getSecurityHeaders();
    } else {
        return error("Invalid authentication handler");
    }
    token = (regex:split(<string>authorizationHeaderMap["Authorization"], " "))[1];
    finalHeaderMap[X_SFDC_SESSION] = token;
    if contentType != () {
        finalHeaderMap[CONTENT_TYPE] = <string>contentType;
    }
    return finalHeaderMap;
}
