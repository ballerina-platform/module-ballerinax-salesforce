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

import ballerina/http;
import ballerina/oauth2;
import ballerina/test;

const int MOCK_OAUTH2_PROXY_PORT = 9091;
const string UNREACHABLE_TOKEN_URL = "http://oauth2-target.invalid/token";

type RecordedProxyRequest readonly & record {|
    string payload;
    string authorization;
|};

isolated RecordedProxyRequest lastProxyRequest = {payload: "", authorization: ""};

isolated function recordProxyRequest(string payload, string authorizationHeader) {
    lock {
        lastProxyRequest = {payload, authorization: authorizationHeader};
    }
}

isolated function getRecordedProxyRequest() returns RecordedProxyRequest {
    lock {
        return lastProxyRequest;
    }
}

final http:Listener mockOAuth2ProxyListener = check new (MOCK_OAUTH2_PROXY_PORT);

final http:Service mockOAuth2ProxyService = service object {
    resource function post [string... path](http:Request request) returns http:Ok|error {
        string payload = check request.getTextPayload();
        string|error authorizationResult = request.getHeader("Authorization");
        string authorization = authorizationResult is string ? authorizationResult : "";
        recordProxyRequest(payload, authorization);
        http:Ok response = {
            body: {
                access_token: "proxy-access-token",
                token_type: "Bearer",
                expires_in: 3600
            }
        };
        return response;
    }
};

@test:BeforeSuite
function startMockOAuth2Proxy() returns error? {
    check mockOAuth2ProxyListener.attach(mockOAuth2ProxyService, "/");
    check mockOAuth2ProxyListener.'start();
}

@test:AfterSuite
function stopMockOAuth2Proxy() returns error? {
    check mockOAuth2ProxyListener.gracefulStop();
}

@test:Config {}
function testClientCredentialsTokenRequestThroughProxy() returns error? {
    oauth2:ClientCredentialsGrantConfig grantConfig = {
        tokenUrl: UNREACHABLE_TOKEN_URL,
        clientId: "client-id",
        clientSecret: "client-secret",
        scopes: ["scope-one", "scope-two"],
        optionalParams: {audience: "salesforce"}
    };
    ProxyConfig proxyConfig = {
        host: "localhost",
        port: MOCK_OAUTH2_PROXY_PORT
    };

    ProxyOAuth2TokenProvider provider = check new (grantConfig, proxyConfig);
    string token = check provider.generateToken();
    test:assertEquals(token, "proxy-access-token");

    RecordedProxyRequest recordedRequest = getRecordedProxyRequest();
    test:assertTrue(recordedRequest.payload.includes("grant_type=client_credentials"));
    test:assertTrue(recordedRequest.payload.includes("scope=scope-one%20scope-two"));
    test:assertTrue(recordedRequest.payload.includes("audience=salesforce"));
    test:assertEquals(recordedRequest.authorization,
            "Basic " + "client-id:client-secret".toBytes().toBase64());
}

@test:Config {}
function testPasswordGrantTokenRequestThroughProxy() returns error? {
    oauth2:PasswordGrantConfig grantConfig = {
        tokenUrl: UNREACHABLE_TOKEN_URL,
        username: "user@example.com",
        password: "password with spaces",
        clientId: "client-id",
        clientSecret: "client-secret",
        credentialBearer: oauth2:POST_BODY_BEARER
    };
    ProxyConfig proxyConfig = {
        host: "localhost",
        port: MOCK_OAUTH2_PROXY_PORT,
        auth: {
            username: "proxy-user",
            password: "proxy-password"
        }
    };

    ProxyOAuth2TokenProvider provider = check new (grantConfig, proxyConfig);
    string token = check provider.generateToken();
    test:assertEquals(token, "proxy-access-token");

    RecordedProxyRequest recordedRequest = getRecordedProxyRequest();
    test:assertTrue(recordedRequest.payload.includes("grant_type=password"));
    test:assertTrue(recordedRequest.payload.includes("username=user%40example.com"));
    test:assertTrue(recordedRequest.payload.includes("password=password%20with%20spaces"));
    test:assertTrue(recordedRequest.payload.includes("client_id=client-id"));
    test:assertTrue(recordedRequest.payload.includes("client_secret=client-secret"));
    test:assertEquals(recordedRequest.authorization, "");
}

@test:Config {}
function testRejectsHttpsProxyForOAuth2TokenRequest() {
    oauth2:ClientCredentialsGrantConfig grantConfig = {
        tokenUrl: UNREACHABLE_TOKEN_URL,
        clientId: "client-id",
        clientSecret: "client-secret"
    };
    ProxyConfig proxyConfig = {
        scheme: HTTPS,
        host: "localhost",
        port: MOCK_OAUTH2_PROXY_PORT
    };

    ProxyOAuth2TokenProvider|error provider = new (grantConfig, proxyConfig);
    test:assertTrue(provider is error);
    if provider is error {
        test:assertEquals(provider.message(),
                "Unsupported proxy scheme 'https'. OAuth2 token requests support only HTTP proxies.");
    }
}
