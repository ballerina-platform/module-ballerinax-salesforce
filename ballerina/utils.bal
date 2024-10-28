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

import ballerina/io;
import ballerina/log;
import ballerina/time;
import ballerina/jballerina.java;
import ballerina/lang.'string as strings;
import ballerina/http;
import ballerinax/'client.config;
import ballerina/oauth2;

isolated string csvContent = PRIVATE_EMPTY_STRING;

# Construct `http:ClientConfiguration` from Connection config record of a connector.
#
# + config - Connection config record of connector
# + return - Created `http:ClientConfiguration` record or error
public isolated function constructHTTPClientConfig(ConnectionConfig config) returns http:ClientConfiguration|error {
    http:ClientConfiguration httpClientConfig = {
        httpVersion: config.httpVersion,
        timeout: config.timeout,
        forwarded: config.forwarded,
        poolConfig: config.poolConfig,
        compression: config.compression,
        circuitBreaker: config.circuitBreaker,
        retryConfig: config.retryConfig,
        validation: config.validation
    };
    if config.auth is AuthConfig {
        httpClientConfig.auth = check initializeAuth(config.auth);
    }
    if config.http1Settings is ClientHttp1Settings {
        ClientHttp1Settings settings = check config.http1Settings.ensureType(ClientHttp1Settings);
        httpClientConfig.http1Settings = {...settings};
    }
    if config.http2Settings is http:ClientHttp2Settings {
        httpClientConfig.http2Settings = check config.http2Settings.ensureType(http:ClientHttp2Settings);
    }
    if config.cache is http:CacheConfig {
        httpClientConfig.cache = check config.cache.ensureType(http:CacheConfig);
    }
    if config.responseLimits is http:ResponseLimitConfigs {
        httpClientConfig.responseLimits = check config.responseLimits.ensureType(http:ResponseLimitConfigs);
    }
    if config.secureSocket is http:ClientSecureSocket {
        httpClientConfig.secureSocket = check config.secureSocket.ensureType(http:ClientSecureSocket);
    }
    if config.proxy is http:ProxyConfig {
        httpClientConfig.proxy = check config.proxy.ensureType(http:ProxyConfig);
    }
    return httpClientConfig;
}


isolated function initializeAuth(AuthConfig? config) returns http:ClientAuthConfig|error {
    http:ClientAuthConfig auth = {};
    if config is http:CredentialsConfig|http:BearerTokenConfig|http:JwtIssuerConfig {
        auth = config;
    } else if config is config:OAuth2ClientCredentialsGrantConfig {
        auth = {...config};
    } else if config is config:OAuth2PasswordGrantConfig {
        config:OAuth2PasswordGrantConfig tokenConfig = check config.ensureType(config:OAuth2PasswordGrantConfig);
        auth = {
            tokenUrl: tokenConfig.tokenUrl,
            username: tokenConfig.username,
            password: tokenConfig.password
        };
        if tokenConfig.clientId is string {
            auth["clientId"] = tokenConfig.clientId;
        }
        if tokenConfig.clientSecret is string {
            auth["clientSecret"] = tokenConfig.clientSecret;
        }
        if tokenConfig.scopes is string[] {
            auth["scopes"] = tokenConfig.scopes;
        }
        if tokenConfig.optionalParams is map<string> {
            auth["optionalParams"] = tokenConfig.optionalParams;
        }
        if tokenConfig.defaultTokenExpTime is decimal {
            auth["defaultTokenExpTime"] = tokenConfig.defaultTokenExpTime;
        }
        if tokenConfig.clockSkew is decimal {
            auth["clockSkew"] = tokenConfig.clockSkew;
        }
        if tokenConfig.credentialBearer is config:CredentialBearer {
            auth["credentialBearer"] = tokenConfig.credentialBearer;
        }
        if tokenConfig.refreshConfig is record {|
            string refreshUrl;
            string[] scopes?;
            map<string> optionalParams?;
            config:CredentialBearer credentialBearer?;
        |} {
            record {|
                string refreshUrl;
                string[] scopes?;
                map<string> optionalParams?;
                config:CredentialBearer credentialBearer?;
            |}? refreshConfig = tokenConfig.refreshConfig;
            record {|
                string refreshUrl;
                string[] scopes?;
                map<string> optionalParams?;
                oauth2:CredentialBearer credentialBearer;
                oauth2:ClientConfiguration clientConfig = {};
            |} httpRefreshConfig = {
                refreshUrl: <string>refreshConfig["refreshUrl"],
                credentialBearer: <oauth2:CredentialBearer>refreshConfig["credentialBearer"]
            };
            if refreshConfig["scopes"] is string[] {
                auth["scopes"] = tokenConfig.scopes;
            }
            if refreshConfig["optionalParams"] is map<string> {
                auth["optionalParams"] = tokenConfig.optionalParams;
            }
            if tokenConfig.credentialBearer is config:CredentialBearer {
                auth["credentialBearer"] = tokenConfig.credentialBearer;
            }
            auth["refreshConfig"] = httpRefreshConfig;
        }
    } else if config is config:OAuth2RefreshTokenGrantConfig {
        auth = {...config};
    } else if config is config:OAuth2JwtBearerGrantConfig {
        auth = {...config};
    }
    return auth;
}

# Remove decimal places from a civil seconds value
#
# + civilTime - a time:civil record
# + return - a time:civil record with decimal places removed
#
isolated function removeDecimalPlaces(time:Civil civilTime) returns time:Civil {
    time:Civil result = civilTime;
    time:Seconds seconds = (result.second is ()) ? 0 : <time:Seconds>result.second;
    decimal floor = decimal:floor(seconds);
    result.second = floor;
    return result;
}

# Convert ReadableByteChannel to string.
#
# + rbc - ReadableByteChannel
# + return - converted string
isolated function convertToString(io:ReadableByteChannel rbc) returns string|error {
    byte[] readContent;
    string textContent = PRIVATE_EMPTY_STRING;
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

# Convert string[][] to string.
#
# + stringCsvInput - Multi dimentional array of strings
# + return - converted string
isolated function convertStringListToString(string[][]|stream<string[], error?> stringCsvInput) returns string|error {
    lock {
        csvContent = PRIVATE_EMPTY_STRING;
    }
    if stringCsvInput is string[][] {
        foreach var row in stringCsvInput {
            lock {
                csvContent += row.reduce(isolated function(string s, string t) returns string {
                    return s.concat(",", t);
                }, PRIVATE_EMPTY_STRING).substring(1) + NEW_LINE;
            }
        }
    } else {
        check stringCsvInput.forEach(isolated function(string[] row) {
            lock {
                csvContent += row.reduce(isolated function(string s, string t) returns string {
                    return s.concat(",", t);
                }, PRIVATE_EMPTY_STRING).substring(1) + NEW_LINE;

            }
        });
    }
    lock {
        return csvContent;
    }
}

isolated function parseCsvString(string stringContent) returns string[][]|error = @java:Method {
   'class: "io.ballerinax.salesforce.CsvParserUtils",
   name: "parseCsvToStringArray"
} external;
