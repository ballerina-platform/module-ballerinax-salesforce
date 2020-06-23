//
// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;
import ballerina/oauth2;

# The Salesforce Client object.
# + salesforceClient - OAuth2 client endpoint
# + salesforceConfiguration - Salesforce Connector configuration
public type BaseClient client object {
    http:Client salesforceClient;
    SalesforceConfiguration salesforceConfiguration;

    # Salesforce Connector endpoint initialization function.
    # + salesforceConfig - Salesforce Connector configuration
    public function init(SalesforceConfiguration salesforceConfig) {
        self.salesforceConfiguration = salesforceConfig;
        // Create an OAuth2 provider.
        oauth2:OutboundOAuth2Provider oauth2Provider = new(salesforceConfig.clientConfig);
        // Create a bearer auth handler using the a created provider.
        http:BearerAuthHandler bearerHandler = new(oauth2Provider);

        http:ClientSecureSocket? socketConfig = salesforceConfig?.secureSocketConfig;
        
        // Create an HTTP client.
        if (socketConfig is http:ClientSecureSocket) {
            self.salesforceClient = new(salesforceConfig.baseUrl, {
                secureSocket: socketConfig,
                auth: {
                    authHandler: bearerHandler
                }
            });
        } else {
            self.salesforceClient = new(salesforceConfig.baseUrl, {
                auth: {
                    authHandler: bearerHandler
                }
            });
        }
    }

    # Get the Salesforce bulk API client.
    # + return - Salesforce bulk client
    public remote function getBulkClient() returns BulkClient {
        BulkClient bulkClient = new(self.salesforceConfiguration);
        return bulkClient;
    }

    # Get the Sobject client.
    # + return - the Sobject client
    public remote function getSobjectClient() returns SObjectClient{
        SObjectClient sobjectClient = new(self.salesforceConfiguration);
        return sobjectClient;
    }

    # Get the Query client.
    # + return - the query client
    public remote function getQueryClient() returns QueryClient{
        QueryClient queryClient = new(self.salesforceConfiguration);
        return queryClient;
    }

    # Lists summary details about each REST API version available.
    # + return - List of `Version` if successful. Else, the occured Error.
    public remote function getAvailableApiVersions() returns @tainted Version[]|Error {
        string path = prepareUrl([BASE_PATH]);
        json res = check self.getRecord(path);
        return toVersions(res);
    }

    # Lists the resources available for the specified API version.
    # + apiVersion - API version (v37)
    # + return - `Resources` as map of strings if successful. Else, the occurred `Error`.
    public remote function getResourcesByApiVersion(string apiVersion) returns @tainted map<string>|Error {
        string path = prepareUrl([BASE_PATH, apiVersion]);
        json res = check self.getRecord(path);
        return toMapOfStrings(res);            
    }

    # Lists the Limits information for your organization.
    # + return - `OrganizationLimits` as map of `Limit` if successful. Else, the occurred `Error`.
    public remote function getOrganizationLimits() returns @tainted map<Limit>|Error {
        string path = prepareUrl([API_BASE_PATH, LIMITS]);
        json res = check self.getRecord(path);
        return toMapOfLimits(res);
    }    

    # The Util function of the get request.
    # + path - resource path 
    # + return - the JSON response or the error
    public function getRecord(string path) returns @tainted json|Error {
        http:Response|error response = self.salesforceClient->get(path);
        return checkAndSetErrors(response);
    }
};

# Salesforce client configuration.
# + baseUrl - The Salesforce endpoint URL
# + clientConfig - OAuth2 direct token configuration
# + secureSocketConfig - HTTPS secure socket configuration
public type SalesforceConfiguration record {
    string baseUrl;
    oauth2:DirectTokenConfig clientConfig;
    http:ClientSecureSocket secureSocketConfig?;
};
