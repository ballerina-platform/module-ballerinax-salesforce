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

public type SalesforceConfiguration {
            oauth2:OAuth2ClientEndpointConfig oauth2Config;
};

public type SalesforceClient object {
    private {
        SalesforceConfiguration salesforceConfig;
        SalesforceConnector salesforceConnector;
    }

    public function init (SalesforceConfiguration salesforceConfiguration);
    public function register (typedesc serviceType);
    public function start ();
    public function getClient () returns SalesforceConnector;
    public function stop ();
};

public function SalesforceClient::init (SalesforceConfiguration salesforceConfig){
    salesforceConnector = new(salesforceConfig.oauth2Config);
}
public function SalesforceClient::register (typedesc serviceType) {
}

public function SalesforceClient::start () {
}

public function SalesforceClient::getClient () returns SalesforceConnector {
    return self.salesforceConnector;
}

public function SalesforceClient::stop () {

}