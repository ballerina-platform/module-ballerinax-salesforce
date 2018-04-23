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

import ballerina/http;

documentation { Salesforce client configuration
    F{{clientConfig}} HTTP configuration
}
public type SalesforceConfiguration {
    string baseUrl;
    http:ClientEndpointConfig clientConfig;
};

documentation {Salesforce Client object
    E{{}}
    F{{salesforceConfig}} Salesforce configration
    F{{salesforceConnector}} Salesforce connector
}
public type Client object {
    public {
        SalesforceConfiguration salesforceConfig = {};
        SalesforceConnector salesforceConnector = new();
    }

    documentation {Salesforce connector endpoint initialization function
        P{{salesforceConfig}} salesforce connector configuration)
    }
    public function init(SalesforceConfiguration salesforceConfig) {
        salesforceConfig.clientConfig.url = salesforceConfig.baseUrl;
        self.salesforceConnector.httpClient.init(salesforceConfig.clientConfig);
    }

    documentation {Get Salesforce client
        R{{}} returns salesforce connector instance
    }
    public function getCallerActions() returns SalesforceConnector {
        return self.salesforceConnector;
    }
};
