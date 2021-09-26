// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/io;
import ballerina/log;
import ballerina/test;
import ballerina/lang.'xml as xmllib;
import ballerina/regex;
import ballerina/os;
import ballerinax/sfdc;

json[] jsonQueryResult = [];
xml xmlQueryResult = xml `<test/>`;
string csvQueryResult = "";


// import ballerina/log;
// import ballerina/test;

// Create Salesforce client configuration by reading from environemnt.
configurable string & readonly clientId = os:getEnv("CLIENT_ID");
configurable string & readonly clientSecret = os:getEnv("CLIENT_SECRET");
configurable string & readonly refreshToken = os:getEnv("REFRESH_TOKEN");
configurable string & readonly refreshUrl = os:getEnv("REFRESH_URL");
configurable string & readonly baseUrl = os:getEnv("EP_URL");

// Using direct-token config for client configuration
ConnectionConfig sfConfig = {
    baseUrl: baseUrl,
    clientConfig: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
    }
};

Client baseClient = check new (sfConfig);
sfdc:Client restClient = check new (sfConfig);

isolated function closeRb(io:ReadableByteChannel ch) {
    var cr = ch.close();
    if (cr is error) {
        log:printError("Error occured while closing the channel: ", 'error = cr);
    }
}

isolated function checkBatchResults(Result result) returns boolean {
    if (!result.success) {
        return false;
    }
    return true;
}

isolated function checkCsvResult(string result) returns int {
    string[] lineArray = regex:split(result, "\n");
    int arrLength = lineArray.length();
    return arrLength - 1;
}

function getContactIdByName(string firstName, string lastName, string title) returns @tainted string {
    string contactId = "";
    string sampleQuery = 
    "SELECT Id FROM Contact WHERE FirstName='" + firstName + "' AND LastName='" + lastName + "' AND Title='" + title + "'";
    sfdc:SoqlResult|sfdc:Error res = restClient->getQueryResult(sampleQuery);

    if (res is sfdc:SoqlResult) {
        sfdc:SoqlRecord[]|error records = res.records;
        if (records is sfdc:SoqlRecord[]) {
            string id = records[0]["Id"].toString();
            contactId = id;
        } else {
            test:assertFail(msg = "Getting contact ID by name failed. err=" + records.toString());
        }
    } else {
        test:assertFail(msg = "Getting contact ID by name failed. err=" + res.toString());
    }
    return contactId;
}

isolated function getJsonContactsToDelete(json[] resultList) returns json[] {
    json[] contacts = [];
    foreach var item in resultList {
        json|error itemId = item.Id;
        if (itemId is json) {
            string id = itemId.toString();
            contacts[contacts.length()] = {"Id": id};
        }
    }
    return contacts;
}

isolated function getXmlContactsToDelete(xml resultList) returns xml {
    xmllib:Element contacts = <xmllib:Element>xml `<sObjects xmlns="http://www.force.com/2009/06/asyncapi/dataload"/>`;

    xmlns "http://www.force.com/2009/06/asyncapi/dataload" as ns;

    xmllib:Element ele = <xmllib:Element>resultList;
    foreach var item in ele.getChildren().elements() {
        string id = (item/<ns:Id>[0]/*).toString();
        xml child = xml `<sObject><Id>${id}</Id></sObject>`;
        contacts.setChildren(contacts.getChildren() + child);
    }
    return contacts;
}

isolated function getCsvContactsToDelete(string resultString) returns string {
    string contacts = "Id";
    string[] lineArray = regex:split(resultString, "\n");
    int arrLength = lineArray.length();
    int counter = 1;
    while (counter < arrLength) {
        string? line = lineArray[counter];
        if (line is string) {
            int? inof = line.indexOf(",");
            if (inof is int) {
                string id = line.substring(0, inof);
                contacts = contacts.concat("\n", id);
            }
        }
        counter = counter + 1;
    }
    return contacts;
}
