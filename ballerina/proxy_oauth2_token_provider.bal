// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/crypto;
import ballerina/http;
import ballerina/oauth2;
import ballerina/url;

type ProxyOAuth2GrantConfig oauth2:ClientCredentialsGrantConfig|oauth2:PasswordGrantConfig;

# Obtains OAuth2 tokens for grant types that are not handled by `TokenManager`,
# while routing the token request through the listener's configured proxy.
isolated class ProxyOAuth2TokenProvider {
    private final ProxyOAuth2GrantConfig & readonly grantConfig;
    private final http:Client tokenClient;

    isolated function init(ProxyOAuth2GrantConfig grantConfig, ProxyConfig proxyConfig,
            decimal connectionTimeout = 15, decimal requestTimeout = 30) returns error? {
        if proxyConfig.scheme != HTTP {
            return error(string `Unsupported proxy scheme '${proxyConfig.scheme}'. ` +
                    "OAuth2 token requests support only HTTP proxies.");
        }
        self.grantConfig = grantConfig.cloneReadOnly();

        oauth2:ClientConfiguration oauthClientConfig = grantConfig.clientConfig;
        http:ProxyConfig httpProxy = {
            host: proxyConfig.host,
            port: proxyConfig.port,
            userName: proxyConfig.auth?.username ?: "",
            password: proxyConfig.auth?.password ?: ""
        };
        http:ClientConfiguration httpClientConfig = {
            httpVersion: oauthClientConfig.httpVersion == oauth2:HTTP_2 ? http:HTTP_2_0 : http:HTTP_1_1,
            timeout: requestTimeout,
            proxy: httpProxy,
            socketConfig: {
                connectTimeOut: connectionTimeout
            }
        };

        oauth2:SecureSocket? oauthSecureSocket = oauthClientConfig?.secureSocket;
        if oauthSecureSocket is oauth2:SecureSocket {
            http:ClientSecureSocket httpSecureSocket = {
                enable: !oauthSecureSocket.disable
            };
            crypto:TrustStore|string? cert = oauthSecureSocket?.cert;
            if cert is crypto:TrustStore|string {
                httpSecureSocket.cert = cert;
            }
            crypto:KeyStore|oauth2:CertKey? key = oauthSecureSocket?.key;
            if key is crypto:KeyStore {
                httpSecureSocket.key = key;
            } else if key is oauth2:CertKey {
                http:CertKey httpCertKey = {
                    certFile: key.certFile,
                    keyFile: key.keyFile,
                    keyPassword: key?.keyPassword
                };
                httpSecureSocket.key = httpCertKey;
            }
            httpClientConfig.secureSocket = httpSecureSocket;
        }

        string tokenUrl = grantConfig.tokenUrl;
        self.tokenClient = check new (tokenUrl, httpClientConfig);
    }

    # Requests a new access token through the configured proxy.
    #
    # + return - The access token or an error if the token endpoint call fails
    isolated function generateToken() returns string|error {
        ProxyOAuth2GrantConfig & readonly config = self.grantConfig;
        string payload;
        string? clientId = ();
        string? clientSecret = ();
        string|string[]? scopes;
        map<string>? optionalParams;
        oauth2:CredentialBearer credentialBearer;

        if config is oauth2:ClientCredentialsGrantConfig {
            if config.clientId == "" || config.clientSecret == "" {
                return error("Client-id or client-secret cannot be empty.");
            }
            payload = "grant_type=client_credentials";
            clientId = config.clientId;
            clientSecret = config.clientSecret;
            scopes = config?.scopes;
            optionalParams = config?.optionalParams;
            credentialBearer = config.credentialBearer;
        } else {
            payload = "grant_type=password&username=" + check url:encode(config.username, "UTF-8") +
                "&password=" + check url:encode(config.password, "UTF-8");
            clientId = config?.clientId;
            clientSecret = config?.clientSecret;
            if (clientId is string) != (clientSecret is string) {
                return error("Both client-id and client-secret must be provided together.");
            }
            if clientId is string && clientSecret is string && (clientId == "" || clientSecret == "") {
                return error("Client-id or client-secret cannot be empty.");
            }
            scopes = config?.scopes;
            optionalParams = config?.optionalParams;
            credentialBearer = config.credentialBearer;
        }

        payload = check appendScopes(payload, scopes);
        payload = check appendOptionalParams(payload, optionalParams);

        http:Request request = new;
        if credentialBearer == oauth2:AUTH_HEADER_BEARER {
            if clientId is string && clientSecret is string {
                string credentials = clientId + ":" + clientSecret;
                request.setHeader("Authorization", "Basic " + credentials.toBytes().toBase64());
            }
        } else if clientId is string && clientSecret is string {
            payload += "&client_id=" + check url:encode(clientId, "UTF-8") +
                "&client_secret=" + check url:encode(clientSecret, "UTF-8");
        }

        map<string>? customHeaders = config.clientConfig?.customHeaders;
        if customHeaders is map<string> {
            foreach [string, string] [name, value] in customHeaders.entries() {
                request.setHeader(name, value);
            }
        }
        string? customPayload = config.clientConfig?.customPayload;
        if customPayload is string && customPayload != "" {
            payload += "&" + customPayload;
        }
        request.setTextPayload(payload, contentType = "application/x-www-form-urlencoded");

        http:Response response = check self.tokenClient->execute("POST", "", request);
        json|error jsonPayload = response.getJsonPayload();
        if response.statusCode < 200 || response.statusCode >= 300 {
            string message = string `Failed to call the token endpoint. HTTP status: ${response.statusCode}`;
            if jsonPayload is json {
                message += ". Response: " + jsonPayload.toJsonString();
            }
            return error(message);
        }
        if jsonPayload is error {
            return error("Failed to parse the token endpoint response as JSON.", jsonPayload);
        }
        json|error accessToken = jsonPayload.access_token;
        if accessToken is string {
            return accessToken;
        }
        return error("Failed to extract 'access_token' from the token endpoint response.");
    }
}

isolated function appendScopes(string payload, string|string[]? scopes) returns string|error {
    string updatedPayload = payload;
    string[] values = [];
    if scopes is string {
        string scope = scopes.trim();
        if scope != "" {
            values.push(scope);
        }
    } else if scopes is string[] {
        foreach string value in scopes {
            string scope = value.trim();
            if scope != "" {
                values.push(scope);
            }
        }
    }
    if values.length() > 0 {
        updatedPayload += "&scope=" + check url:encode(string:'join(" ", ...values), "UTF-8");
    }
    return updatedPayload;
}

isolated function appendOptionalParams(string payload, map<string>? optionalParams) returns string|error {
    string updatedPayload = payload;
    if optionalParams is map<string> {
        foreach [string, string] [key, value] in optionalParams.entries() {
            updatedPayload += "&" + check url:encode(key.trim(), "UTF-8") +
                "=" + check url:encode(value.trim(), "UTF-8");
        }
    }
    return updatedPayload;
}
