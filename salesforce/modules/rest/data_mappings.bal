// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

isolated function toVersions(json payload) returns Version[]|error {
    Version[] versions = [];
    json[] versionsArr = <json[]>payload;

    foreach json ele in versionsArr {
        Version ver = check ele.cloneWithType(Version);
        versions[versions.length()] = ver;
    }
    return versions;
}

type StringMap map<string>;

isolated function toMapOfStrings(json payload) returns map<string>|error {
    return check payload.cloneWithType(StringMap);
}

type JsonMap map<json>;

isolated function toMapOfLimits(json payload) returns map<Limit>|error {
    map<Limit> limits = {};
    map<json> payloadMap = check payload.cloneWithType(JsonMap);
    foreach var [key, value] in payloadMap.entries() {
        Limit|error lim = value.cloneWithType(Limit);
        if lim is Limit {
            limits[key] = lim;
        } else {
            string errMsg = "Error occurred while constructing Limit record.";
            log:printError(errMsg + " value:" + value.toJsonString(), 'error = lim);
            return error(errMsg, lim);
        }
    }
    return limits;
}

isolated function toSObjectMetaData(json payload) returns SObjectMetaData|error {
    return check payload.cloneWithType(SObjectMetaData);
}
