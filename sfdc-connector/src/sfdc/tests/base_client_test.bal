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

import ballerina/test;
import ballerina/log;
import ballerina/config;

// Create Salesforce client configuration by reading from config file.
SalesforceConfiguration sfConfig = {
    baseUrl: config:getAsString("EP_URL"),
    clientConfig: {
        accessToken: config:getAsString("ACCESS_TOKEN"),
        refreshConfig: {
            clientId: config:getAsString("CLIENT_ID"),
            clientSecret: config:getAsString("CLIENT_SECRET"),
            refreshToken: config:getAsString("REFRESH_TOKEN"),
            refreshUrl: config:getAsString("REFRESH_URL")
        }
    }
};

BaseClient baseClient = new(sfConfig);

@test:Config{}
function testGetAvailableApiVersions(){
    log:printInfo("baseClient -> getAvailableApiVersions()");
    Version[]|Error versions = baseClient->getAvailableApiVersions();

    if (versions is Version[]) {
        test:assertTrue(versions.length() > 0, msg = "Found 0 or No API versions");
    } else {
        test:assertFail(msg = versions.message());
    }
}

@test:Config {}
function testGetResourcesByApiVersion() {
    log:printInfo("baseClient -> getResourcesByApiVersion()");
    map<string>|Error resources = baseClient->getResourcesByApiVersion(API_VERSION);

    if (resources is map<string>) {
        test:assertTrue(resources.length() > 0, msg = "Found empty resource map");
        test:assertTrue(trim(resources["sobjects"].toString()).length() > 0, msg = "Found null for resource sobjects");
        test:assertTrue(trim(resources["search"].toString()).length() > 0, msg = "Found null for resource search");
        test:assertTrue(trim(resources["query"].toString()).length() > 0, msg = "Found null for resource query");
        test:assertTrue(trim(resources["licensing"].toString()).length() > 0, 
            msg = "Found null for resource licensing");
        test:assertTrue(trim(resources["connect"].toString()).length() > 0, msg = "Found null for resource connect");
        test:assertTrue(trim(resources["tooling"].toString()).length() > 0, msg = "Found null for resource tooling");
        test:assertTrue(trim(resources["chatter"].toString()).length() > 0, msg = "Found null for resource chatter");
        test:assertTrue(trim(resources["recent"].toString()).length() > 0, msg = "Found null for resource recent");
    } else {
        test:assertFail(msg = resources.message());
    }
}

@test:Config {}
function testGetOrganizationLimits() {
    log:printInfo("baseClient -> getOrganizationLimits()");
    map<Limit>|Error limits = baseClient->getOrganizationLimits();

    if (limits is map<Limit>) {
        test:assertTrue(limits.length() > 0, msg = "Found empty resource map");
        string[] keys = limits.keys();
        test:assertTrue(keys.length() > 0, msg = "Response doesn't have enough keys");
        foreach var key in keys {
            Limit? lim = limits[key];
            if (lim is Limit) {
                test:assertNotEquals(lim.Max, (), msg = "Max limit not found");
                test:assertNotEquals(lim.Remaining, (), msg = "Remaining resources not found");
            } else {
                test:assertFail(msg = "Could not get the Limit for the key:" + key);
            }
        }
    } else {
        test:assertFail(msg = limits.message());
    }
}
