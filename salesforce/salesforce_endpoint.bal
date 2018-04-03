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

import ballerina/io;
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
    oauth2:OAuth2Configuration oAuth2Configuration = salesforceConfig.oauth2Config;
    oauth2:OAuth2Connector oAuth2Connector = {accessToken:oAuth2Configuration.accessToken,
                                          refreshToken:oAuth2Configuration.refreshToken,
                                          clientId:oAuth2Configuration.clientId,
                                          clientSecret:oAuth2Configuration.clientSecret,
                                          refreshTokenEP:oAuth2Configuration.refreshTokenEP,
                                          refreshTokenPath:oAuth2Configuration.refreshTokenPath,
                                          useUriParams:oAuth2Configuration.useUriParams,
                                          httpClient:http:createHttpClient(oAuth2Configuration.baseUrl, oAuth2Configuration.clientConfig)};
    ep.salesforceConnector = {oauth2:oAuth2Connector};
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