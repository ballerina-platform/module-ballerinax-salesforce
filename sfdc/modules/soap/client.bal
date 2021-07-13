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
import ballerinax/sfdc;

# The Salesforce Client object.
#
# + salesforceClient - OAuth2 client endpoint
# + clientHandler - http:ClientOAuth2Handler class instance 
# + clientConfig - http:OAuth2RefreshTokenGrantConfig|http:BearerTokenConfig record to initialize the Salesforce client
@display {
    label: "Salesforce SOAP Client",
    iconPath: "SalesforceLogo.png"
}
public client class Client {
    http:Client salesforceClient;
    http:OAuth2RefreshTokenGrantConfig|http:BearerTokenConfig clientConfig;
    http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler clientHandler;

    # Initializes Salesforce SOAP Client.
    #
    # + salesforceConfig - Salesforce Connector configuration
    public isolated function init(sfdc:SalesforceConfiguration salesforceConfig) returns error? {
        self.clientConfig = salesforceConfig.clientConfig;
        http:ClientSecureSocket? socketConfig = salesforceConfig?.secureSocketConfig;

        http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler|error httpHandlerResult;
        if self.clientConfig is http:OAuth2RefreshTokenGrantConfig {
            httpHandlerResult = trap new (<http:OAuth2RefreshTokenGrantConfig>self.clientConfig);
        } else {
            httpHandlerResult = trap new (<http:BearerTokenConfig>self.clientConfig);
        }

        if (httpHandlerResult is http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler) {
            self.clientHandler = httpHandlerResult;
        } else {
            return error(sfdc:INVALID_CLIENT_CONFIG);
        }

        http:Client|error httpClientResult = trap new (salesforceConfig.baseUrl, {secureSocket: socketConfig});

        if (httpClientResult is http:Client) {
            self.salesforceClient = httpClientResult;
        } else {
            return error(sfdc:INVALID_CLIENT_CONFIG);
        }
    }

    # Convert lead to to account and contact
    #
    # + leadId - Lead ID
    # + opportunityNotRequired - By default an opportunity is also created in the conversion. Can be omited by providing
    # `True` value
    # + return - `ConvertedLead` or error
    isolated remote function convertLead(@display {label: "Lead ID"} string leadId, @display 
                                         {label: "Not to create Opportunity?"} boolean? opportunityNotRequired = ()) returns 
    ConvertedLead|error {
        string sessionId = check getSessionId(self.clientHandler);
        string payload = check buildXMLPayload(sessionId, leadId, opportunityNotRequired);
        http:Request request = new;
        request.setHeader(SOAP_ACTION, ADD);
        request.setTextPayload(payload, contentType = TEXT_XML);
        string path = sfdc:prepareUrl([sfdc:SERVICES, SOAP, C, sfdc:API_VERSION]);
        http:Response response = check self.salesforceClient->post(path, request);
        return createResponse(response);
    }
}
