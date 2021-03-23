// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/log;
import ballerinax/sfdc;

public function main() {

    // Create Salesforce client configuration by reading from config file.
    sfdc:SalesforceConfiguration sfConfig = {
        baseUrl: "https://af15-dev-ed.my.salesforce.com",
        clientConfig: {
            refreshUrl: "https://login.salesforce.com/services/oauth2/token",
            refreshToken: "5Aep861NT6Ju45T6F2404ReNAZgt2m7cyFsTHRkS5sTqURqh2U3tf9q4gvWM59Tq3kdYPrMtLqgY4MehU3t0OA4",
            clientId: "3MVG9Nk1FpUrSQHc75WsaUUz730wnsEN_5A805judZJBQGOhfxhc4VXKHo5ps7FlcObrLauqgJ_hFrM7fSIrs",
            clientSecret: "044246381F2EE91D3B1CDE1ED1A7395D35C1CEA4329CC82499037EA111E7D56E"
        }
    };

    // Create Salesforce client.
    sfdc:Client baseClient = checkpanic new(sfConfig);

    json accountRecord = {
        Name: "University of All",
        BillingCity: "Colombo"
    };

    string|sfdc:Error res = baseClient->createAccount(accountRecord);

    if (res is string) {
        log:printInfo("Account Created Successfully. Account ID : " + res);
    } else {
        log:printError(msg = res.message());
    }
}
