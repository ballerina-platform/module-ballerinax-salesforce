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

import ballerina/http;

# Salesforce Client object.
# + salesforceClient - OAuth2 client endpoint
# + salesforceConfiguration - Salesforce Connector configuration
public type Client client object {
    http:Client salesforceClient;
    SalesforceConfiguration salesforceConfiguration;

    # Salesforce Connector endpoint initialization function.
    # + salesforceConfig - Salesforce Connector configuration
    public function __init(SalesforceConfiguration salesforceConfig) {
        self.salesforceClient = new(salesforceConfig.baseUrl, config = salesforceConfig.clientConfig);
        self.salesforceConfiguration = salesforceConfig;
    }

    public remote function createSalesforceBulkClient() returns SalesforceBulkClient;
};

# Salesforce client configuration.
# + clientConfig - HTTP configuration
# + baseUrl - The Salesforce API URL
public type SalesforceConfiguration record {
    string baseUrl;
    http:ClientEndpointConfig clientConfig;
};

public remote function Client.createSalesforceBulkClient() returns SalesforceBulkClient {
    SalesforceBulkClient salesforceBulkClient = new(self.salesforceConfiguration);
    return salesforceBulkClient;
}
