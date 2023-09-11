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
import ballerinax/'client.config;
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
    public isolated function init(ConnectionConfig config) returns error? {
        http:ClientConfiguration httpClientConfig = check config:constructHTTPClientConfig(config);
        http:OAuth2RefreshTokenGrantConfig|http:BearerTokenConfig auth = let var authConfig = config.auth in 
                (authConfig is http:BearerTokenConfig ?  authConfig : {...authConfig});
        self.clientConfig = auth.cloneReadOnly();

        http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler|error httpHandlerResult;
        if auth is http:OAuth2RefreshTokenGrantConfig {
            httpHandlerResult = trap new (<http:OAuth2RefreshTokenGrantConfig>auth);
        } else {
            httpHandlerResult = trap new (<http:BearerTokenConfig>auth);
        }

        if httpHandlerResult is http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler {
            self.clientHandler = httpHandlerResult;
        } else {
            return error(utils:INVALID_CLIENT_CONFIG);
        }
        
        http:Client|error httpClientResult = trap new (config.baseUrl, httpClientConfig);

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
