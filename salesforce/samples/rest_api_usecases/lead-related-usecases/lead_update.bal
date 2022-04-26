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
import ballerinax/salesforce as sfdc;

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
sfdc:Client baseClient = check new (sfConfig);

public function main() returns error? {

    string leadId = check getLeadIdByName("Mark", "Wahlberg", "IT World");

    json leadRecord = {
        FirstName: "Mark",
        LastName: "Wahlberg",
        Title: "Director in Technology",
        Company: "IT World"
    };

    sfdc:Error? res = baseClient->updateLead(leadId, leadRecord);

    if res is sfdc:Error {
        log:printError(res.message());
    } else {
        log:printInfo("Lead updated successfully");
    }

}

function getLeadIdByName(string firstName, string lastName, string compnay) returns string|error {
    string leadId = "";
    string sampleQuery = "SELECT Id FROM Lead WHERE FirstName='" + firstName + "' AND LastName='" + lastName
        + "' AND Company='" + compnay + "'";
    stream<record {}, error?> queryResults = check baseClient->getQueryResult(sampleQuery);
    var result = queryResults.next();
    if result is ResultValue {
        leadId = check result.value.get("Id").ensureType();
    } else {
        log:printError(msg = "Getting Lead ID by name failed.");
    }
    return leadId;
}

type ResultValue record {|
    record {} value;
|};
