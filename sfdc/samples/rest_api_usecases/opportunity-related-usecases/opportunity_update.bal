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
sfdc:ConnectionConfig sfConfig = {
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

    string opportunityId = getOpportunityIdByName("Alan Kimberly", "New");

    json opportunityRecord = {
        Name: "Alan Kimberly",
        CloseDate: "2020-02-25",
        StageName: "Prospecting"
    };

    sfdc:Error? res = baseClient->updateOpportunity(opportunityId,opportunityRecord);

    if res is sfdc:Error{
        log:printError(res.message());
    } else {
        log:printInfo("Opportunity updated successfully");
    }

}

function getOpportunityIdByName(string name, string stageName) returns @tainted string {
    string opportunityId = "";
    string sampleQuery = "SELECT Id FROM Opportunity WHERE Name='" + name + "' AND StageName='" + stageName + "'";
    sfdc:SoqlResult|sfdc:Error res = baseClient->getQueryResult(sampleQuery);

    if (res is sfdc:SoqlResult) {
        sfdc:SoqlRecord[]|error records = res.records;
        if (records is sfdc:SoqlRecord[]) {
            string id = records[0]["Id"].toString();
            opportunityId = id;
        } else {
            log:printInfo("Getting Opportunity ID by name failed. err=" + records.toString());            
        }
    } else {
        log:printInfo("Getting Opportunity ID by name failed. err=" + res.toString());
    }
    return opportunityId;
}
