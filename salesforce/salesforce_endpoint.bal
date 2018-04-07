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

package salesforce;

import wso2/oauth2;

@Description {value:"Represents Salesforce Configuration struct that contains OAuth2 Configuration"}
public struct SalesforceConfiguration {
    oauth2:OAuth2Configuration oauth2Config;
}

@Description {value:"Function to create Salesforce configuration"}
public function <SalesforceConfiguration oauth2Config> SalesforceConfiguration () {
    oauth2Config.oauth2Config = {};
}

@Description {value:"Represents Salesforce Endpoint"}
public struct SalesforceEndpoint {
    SalesforceConfiguration salesforceConfig;
    SalesforceConnector salesforceConnector;
}

@Description {value:"Initialize Salesforce Endpoint"}
public function <SalesforceEndpoint ep> init (SalesforceConfiguration salesforceConfig) {
    endpoint oauth2:OAuth2Endpoint oauth2Endpoint {
        baseUrl:salesforceConfig.oauth2Config.baseUrl,
        accessToken:salesforceConfig.oauth2Config.accessToken,
        clientConfig:{},
        refreshToken:salesforceConfig.oauth2Config.refreshToken,
        clientId:salesforceConfig.oauth2Config.clientId,
        clientSecret:salesforceConfig.oauth2Config.clientSecret,
        refreshTokenEP:salesforceConfig.oauth2Config.refreshTokenEP,
        refreshTokenPath:salesforceConfig.oauth2Config.refreshTokenPath,
        useUriParams:true
    };

    ep.salesforceConnector = {
                                 oauth2EP:oauth2Endpoint
                             };
}

@Description {value:"Register Endpoint"}
public function <SalesforceEndpoint ep> register (typedesc serviceType) {

}

@Description {value:"Start Endpoint"}
public function <SalesforceEndpoint ep> start () {

}

@Description {value:"Returns the connector that client code uses"}
@Return {value:"The connector that client code uses"}
public function <SalesforceEndpoint ep> getClient () returns SalesforceConnector {
    return ep.salesforceConnector;
}

@Description {value:"Stops the registered service"}
@Return {value:"Error occured during registration"}
public function <SalesforceEndpoint ep> stop () {

}