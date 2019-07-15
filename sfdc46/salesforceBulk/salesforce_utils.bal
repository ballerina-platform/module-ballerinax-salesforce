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

# Returns the prepared URL.
# + paths - An array of paths prefixes
# + return - The prepared URL
function prepareUrl(string[] paths) returns string {
    string url = EMPTY_STRING;

    if (paths.length() > 0) {
        foreach var path in paths {
            if (!path.hasPrefix(FORWARD_SLASH)) {
                url = url + FORWARD_SLASH;
            }
            url = url + path;
        }
    }
    return url;
}

# Returns the prepared URL with encoded query.
# + paths - An array of paths prefixes
# + queryParamNames - An array of query param names
# + queryParamValues - An array of query param values
# + return - The prepared URL with encoded query
function prepareQueryUrl(string[] paths, string[] queryParamNames, string[] queryParamValues) returns string {

    string url = prepareUrl(paths);

    url = url + QUESTION_MARK;
    boolean first = true;
    int i = 0;
    foreach var name in queryParamNames {
        string value = queryParamValues[i];

        var encoded = http:encode(value, ENCODING_CHARSET_UTF_8);

        if (encoded is string) {
            if (first) {
                url = url + name + EQUAL_SIGN + encoded;
                first = false;
            } else {
                url = url + AMPERSAND + name + EQUAL_SIGN + encoded;
            }
        } else {
            log:printError("Unable to encode value: " + value, err = encoded);
            break;
        }
        i = i + 1;
    }

    return url;
}

# Check and set errors of HTTP response with XML payload.
# + httpResponse - HTTP response or error occurred
# + return - XML response if successful else SalesforceError occured
function checkAndSetErrorsXml(http:Response | error httpResponse) returns xml | SalesforceError {
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
                    message: string.convert(xmlResponse.exceptionMessage.getTextValue()),
                    errorCode: string.convert(httpResponse.statusCode)
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
function checkAndSetErrorsCsv(http:Response | error httpResponse) returns string | SalesforceError {
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
                    message: 
                    string.convert(xmlResponse[getElementNameWithNamespace("exceptionMessage")].getTextValue()),
                    errorCode: string.convert(httpResponse.statusCode)
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
function checkAndSetErrorsJson(http:Response | error httpResponse) returns json | SalesforceError {
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
                    message: <string>string.convert(response["exceptionMessage"]),
                    errorCode: string.convert(httpResponse.statusCode)
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
    log:printError(baseErrorMsg + " Error: " + <string> responseErr.detail().message);
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
    int | error intValue = int.convert(value);
    if (intValue is int) {
        return intValue;
    } else {
        log:printError("String to int conversion failed, string value: " + value, err = intValue);
        panic intValue;
    }
}

# Convert string to float
# + value - string value
# + return - converted float
function getFloatValue(string value) returns float {
    float | error floatValue = float.convert(value);
    if (floatValue is float) {
        return floatValue;
    } else {
        log:printError("String to float conversion failed, string value: " + value, err = floatValue);
        panic floatValue;
    }
}

# Convert string to boolean
# + value - string value
# + return - converted boolean
function getBooleanValue(string value) returns boolean {
    boolean | error boolValue = boolean.convert(value);
    if (boolValue is boolean) {
        return boolValue;
    } else {
        log:printError("String to boolean conversion failed, string value: " + value, err = boolValue);
        panic boolValue;
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
    json jobDeatils = {
        operation: operation,
        ^"object": objectName,
        contentType: JSON
    };
    if (extIdFieldName != EMPTY_STRING) {
        jobDeatils["externalIdFieldName"] = extIdFieldName;
    } 
    return jobDeatils;
}

# Set session ID.
# + req - HTTP request which needs to set session ID // SalesforceConfiguration sfConfig
function setSessionId(http:Request req) {
    req.setHeader(X_SFDC_SESSION, SESSION_ID);
}

// function getAccessTokenFromSfConfig(SalesforceConfiguration sfConfig) returns string {
//     return sfConfig["clientConfig"]["auth"]["config"]["config"]["accessToken"];
// }
