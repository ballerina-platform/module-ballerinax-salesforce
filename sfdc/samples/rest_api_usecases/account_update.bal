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

// Create Salesforce client configuration by reading from config file.
sfdc:SalesforceConfiguration sfConfig = {
    baseUrl: "<BASE_URL>",
    clientConfig: {
        clientId: "<CLIENT_ID>",
        clientSecret: "<CLIENT_SECRET>",
        refreshToken: "<REFESH_TOKEN>",
        refreshUrl: "<REFRESH_URL>"
    }
};

// Create Salesforce client.
sfdc:Client baseClient = checkpanic new(sfConfig);

public function main(){

    string accountId = getAccountIdByName("University of Colombo");

    json accountRecord = {
        Name: "University of Colombo",
        BillingCity: "Colombo 3"
    };

    boolean|sfdc:Error res = baseClient->updateAccount(accountId,accountRecord);

   if res is boolean{
        string outputMessage = (res == true) ? "Account Updated Successfully!" : "Failed to Update the Account";
        log:print(outputMessage);
    } else {
        log:printError(msg = res.message());
    }

}

function getAccountIdByName(string name) returns @tainted string {
    string contactId = "";
    string sampleQuery = "SELECT Id FROM Account WHERE Name='" + name + "'";
    sfdc:SoqlResult|sfdc:Error res = baseClient->getQueryResult(sampleQuery);

    if (res is sfdc:SoqlResult) {
        sfdc:SoqlRecord[]|error records = res.records;
        if (records is sfdc:SoqlRecord[]) {
            log:print(records.toString());
            string id = records[0]["Id"].toString();
            contactId = id;
        } else {
            log:print("Getting contact ID by name failed. err=" + records.toString());            
        }
    } else {
        log:print("Getting contact ID by name failed. err=" + res.toString());
    }
    return contactId;
}
