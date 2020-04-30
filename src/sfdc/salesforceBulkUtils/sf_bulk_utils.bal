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
import ballerina/'lang\.int as ints;
import ballerina/'lang\.float as floats;
import ballerina/lang.'string as strings;

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
    xmlns "http://www.force.com/2009/06/asyncapi/dataload" as ns;

    if (xmlResponse is xml) {
        HttpResponseHandlingError httpResponseHandlingError = error(HTTP_RESPONSE_HANDLING_ERROR,
            message = (xmlResponse/<ns:exceptionMessage>/*).toString(), 
            errorCode = (xmlResponse/<ns:exceptionCode>/*).toString());
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
function convertToString(io:ReadableByteChannel rbc) returns @tainted string|ConnectorError {
    byte[] readContent;
    string textContent = "";
    while (true) {
        byte[]|io:Error result = rbc.read(1000);
        if (result is io:EofError) {
            break;
        } else if (result is io:Error) {
            string errMsg = "Error occurred while reading from Readable Byte Channel.";
            log:printError(errMsg, err = result);
            IOError ioError = error(IO_ERROR, message = errMsg, errorCode = IO_ERROR, cause = result);
            return ioError;
        } else {
            readContent = result;
            string|error readContentStr = strings:fromBytes(readContent);
            if (readContentStr is string) {
                textContent = textContent + readContentStr; 
            } else {
                string errMsg = "Error occurred while converting readContent byte array to string.";
                log:printError(errMsg, err = readContentStr);
                TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg, 
                    errorCode = TYPE_CONVERSION_ERROR, cause = readContentStr);
                return typeError;
            }                 
        }
    }
    return textContent;
}

# Convert ReadableByteChannel to json.
# 
# + rbc - ReadableByteChannel
# + return - converted json
function convertToJson(io:ReadableByteChannel rbc) returns @tainted json|ConnectorError {
    io:ReadableCharacterChannel|io:Error rch = new(rbc, ENCODING_CHARSET);

    if (rch is io:Error) {
        string errMsg = "Error occurred while converting ReadableByteChannel to ReadableCharacterChannel.";
        log:printError(errMsg, err = rch);
        IOError ioError = error(IO_ERROR, message = errMsg, errorCode = IO_ERROR, cause = rch);
        return ioError;
    } else {
        json|error jsonContent = rch.readJson();

        if (jsonContent is json) {
            return jsonContent;
        } else {
            string errMsg = "Error occurred while reading ReadableCharacterChannel as json.";
            log:printError(errMsg, err = jsonContent);
            IOError ioError = error(IO_ERROR, message = errMsg, errorCode = IO_ERROR, cause = jsonContent);
            return ioError;
        }
    }
}

# Convert ReadableByteChannel to xml.
# 
# + rbc - ReadableByteChannel
# + return - converted xml
function convertToXml(io:ReadableByteChannel rbc) returns @tainted xml|ConnectorError {
    io:ReadableCharacterChannel|io:Error rch = new(rbc, ENCODING_CHARSET);

    if (rch is io:Error) {
        string errMsg = "Error occurred while converting ReadableByteChannel to ReadableCharacterChannel.";
        log:printError(errMsg, err = rch);
        IOError ioError = error(IO_ERROR, message = errMsg, errorCode = IO_ERROR, cause = rch);
        return ioError;
    } else {
        xml|error xmlContent = rch.readXml();

        if (xmlContent is xml) {
            return xmlContent;
        } else {
            string errMsg = "Error occurred while reading ReadableCharacterChannel as xml.";
            log:printError(errMsg, err = xmlContent);
            IOError ioError = error(IO_ERROR, message = errMsg, errorCode = IO_ERROR, cause = xmlContent);
            return ioError;
        }
    }
}
