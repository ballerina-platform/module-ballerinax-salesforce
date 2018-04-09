//
// Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import wso2/oauth2;

@Description {value:"Salesforce connector configurations can be setup here. In order to use this connector,
the user will need to have a Salesforce account and a connected app (visit Salesforce:
https://www.salesforce.com for more info) and obtain the following parameters:
Base URl (Endpoint), Client Id, Client Secret, Access Token, Refresh Token, Refresh Token Endpoint,
Refresh Token Path. Provide the obtained credentials to the SalesforceConnectorConfiguration"}
@Field {value:"oauth2Config: OAuth2 Client endpoint configurations provided by the user"}
public type SalesforceConfiguration {
            oauth2:OAuth2ClientEndpointConfiguration oauth2Config;
};

@Description {value:"Salesforce connector endpoint"}
@Field {value:"salesforceConfig: Salesforce connector configurations"}
@Field {value:"salesforceConnector: Salesforce Connector object"}
public type Client object {
    public {
        oauth2:Client oauth2EP = new();
        SalesforceConfiguration salesforceConfig={};
        SalesforceConnector salesforceConnector=new();
    }

    new () {}

    @Description {value:"Salesforce connector endpoint initialization function"}
    @Param {value:"salesforceConfig: salesforce connector configuration"}
    public function init (SalesforceConfiguration salesforceConfig) {
        //salesforceConfig.oauth2Config.useUriParams = true;
        self.oauth2EP.init(salesforceConfig.oauth2Config);
        self.salesforceConnector.oauth2Endpoint = self.oauth2EP;
    }

    @Description {value:"Register Salesforce connector endpoint"}
    @Param {value:"typedesc: Accepts types of data (int, float, string, boolean, etc)"}
    public function register (typedesc serviceType) {
    }

    @Description {value:"Start Salesforce connector endpoint"}
    public function start () {
    }

    @Description {value:"Return the Salesforce connector client"}
    @Return {value:"Client client"}
    public function getClient () returns SalesforceConnector {
        return self.salesforceConnector;
    }

    @Description {value:"Stop Salesforce connector client"}
    public function stop () {

    }
};