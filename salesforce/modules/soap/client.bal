// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/http;
import ballerinax/salesforce.utils;

# Ballerina Salesforce SOAP connector provides the capability to access Salesforce SOAP API. 
# This connector lets you to perform operations like create, retrieve, update or delete sobjects, such as accounts,
# leads, custom objects, and etc..
#
# + salesforceClient - OAuth2 client endpoint
# + clientHandler - http:ClientOAuth2Handler class instance 
# + clientConfig - Configurations required to initialize the `Client`
@display {
    label: "Salesforce SOAP API Client",
    iconPath: "resources/sfdc.svg"
}
public isolated client class Client {
    private final http:Client salesforceClient;
    private final http:OAuth2RefreshTokenGrantConfig|http:BearerTokenConfig clientConfig;
    private final http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler clientHandler;

    # Initializes the connector. During initialization you can pass either http:BearerTokenConfig if you have a bearer
    # token or http:OAuth2RefreshTokenGrantConfig if you have Oauth tokens.
    # Create a Salesforce account and obtain tokens following 
    # [this guide](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm). 
    #
    # + salesforceConfig - Salesforce Connector configuration
    # + return - An error on failure of initialization or else `()`
    public isolated function init(ConnectionConfig salesforceConfig) returns error? {
        self.clientConfig = salesforceConfig.clientConfig.cloneReadOnly();
        http:ClientSecureSocket? socketConfig = salesforceConfig?.secureSocketConfig;

        http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler|error httpHandlerResult;
        if self.clientConfig is http:OAuth2RefreshTokenGrantConfig {
            httpHandlerResult = trap new (<http:OAuth2RefreshTokenGrantConfig>self.clientConfig);
        } else {
            httpHandlerResult = trap new (<http:BearerTokenConfig>self.clientConfig);
        }

        if httpHandlerResult is http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler {
            self.clientHandler = httpHandlerResult;
        } else {
            return error(utils:INVALID_CLIENT_CONFIG);
        }

        http:Client|error httpClientResult = trap new (salesforceConfig.baseUrl, {
            secureSocket: socketConfig,
            httpVersion: salesforceConfig.httpVersion,
            http1Settings: salesforceConfig.http1Settings,
            http2Settings: salesforceConfig.http2Settings,
            timeout: salesforceConfig.timeout,
            forwarded: salesforceConfig.forwarded,
            followRedirects: salesforceConfig.followRedirects,
            poolConfig: salesforceConfig.poolConfig,
            cache: salesforceConfig.cache,
            compression: salesforceConfig.compression,
            circuitBreaker: salesforceConfig.circuitBreaker,
            retryConfig: salesforceConfig.retryConfig,
            cookieConfig: salesforceConfig.cookieConfig,
            responseLimits: salesforceConfig.responseLimits
        });

        if httpClientResult is http:Client {
            self.salesforceClient = httpClientResult;
        } else {
            return error(utils:INVALID_CLIENT_CONFIG);
        }
    }

    # Convert lead to to account and contact
    #
    # + payload - Record represent convertLead paramaters
    # + return - `ConvertedLead` or error
    isolated remote function convertLead(LeadConvert payload) returns ConvertedLead|error {
        string sessionId = check getSessionId(self.clientHandler);
        string xmlPayload = check buildXMLPayload(sessionId, payload);
        http:Request request = new;
        request.setHeader(SOAP_ACTION, ADD);
        request.setTextPayload(xmlPayload, contentType = TEXT_XML);
        string path = utils:prepareUrl([SERVICES, SOAP, C, VERSION]);
        http:Response response = check self.salesforceClient->post(path, request);
        return createResponse(response);
    }
}

# Salesforce client configuration.
#
# + baseUrl - The Salesforce endpoint URL
# + clientConfig - OAuth2 direct token configuration
# + secureSocketConfig - HTTPS secure socket configuration
# + httpVersion - The HTTP version understood by the client
# + http1Settings - Configurations related to HTTP/1.x protocol
# + http2Settings - Configurations related to HTTP/2 protocol
# + timeout - The maximum time to wait (in seconds) for a response before closing the connection
# + forwarded - The choice of setting `forwarded`/`x-forwarded` header
# + followRedirects - Configurations associated with Redirection
# + poolConfig - Configurations associated with request pooling
# + cache - HTTP caching related configurations
# + compression - Specifies the way of handling compression (`accept-encoding`) header
# + circuitBreaker - Configurations associated with the behaviour of the Circuit Breaker
# + retryConfig - Configurations associated with retrying
# + cookieConfig - Configurations associated with cookies
# + responseLimits - Configurations associated with inbound response size limits
@display {label: "Connection Config"}
public type ConnectionConfig record {|
    @display {label: "Salesforce Domain URL"}
    string baseUrl;
    @display {label: "Auth Config"}
    http:OAuth2RefreshTokenGrantConfig|http:BearerTokenConfig clientConfig;
    @display {label: "SSL Config"}
    http:ClientSecureSocket secureSocketConfig?;
    string httpVersion = "1.1";
    http:ClientHttp1Settings http1Settings = {};
    http:ClientHttp2Settings http2Settings = {};
    decimal timeout = 60;
    string forwarded = "disable";
    http:FollowRedirects? followRedirects = ();
    http:PoolConfiguration? poolConfig = ();
    http:CacheConfig cache = {};
    http:Compression compression = http:COMPRESSION_AUTO;
    http:CircuitBreakerConfig? circuitBreaker = ();
    http:RetryConfig? retryConfig = ();
    http:CookieConfig? cookieConfig = ();
    http:ResponseLimitConfigs responseLimits = {};
|};
