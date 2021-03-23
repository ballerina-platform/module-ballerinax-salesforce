//
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
//
import ballerina/log;

isolated function toVersions(json payload) returns Version[]|Error {
    Version[] versions = [];
    json[] versionsArr = <json[]>payload;

    foreach json ele in versionsArr {
        Version|error ver = ele.cloneWithType(Version);

        if (ver is Version) {
            versions[versions.length()] = ver;
        } else {
            string errMsg = "Error occurred while constructing Version record.";
            log:printError(errMsg + " ele:" + ele.toJsonString(), 'error = ver);
            return error Error(errMsg, ver);
        }
    }
    return versions;
}

type StringMap map<string>;

isolated function toMapOfStrings(json payload) returns map<string>|Error {
    map<string>|error strMap = payload.cloneWithType(StringMap);

    if (strMap is map<string>) {
        return strMap;
    } else {
        string errMsg = "Error occurred while constructing map<string>.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), 'error = strMap);
        return error Error(errMsg, strMap);
    }
}

type JsonMap map<json>;

isolated function toMapOfLimits(json payload) returns map<Limit>|Error {
    map<Limit> limits = {};
    map<json>|error payloadMap = payload.cloneWithType(JsonMap);

    if (payloadMap is error) {
        string errMsg = "Error occurred while constructing map<json> using json payload.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), 'error = payloadMap);
        return error Error(errMsg, payloadMap);
    } else {
        foreach var [key, value] in payloadMap.entries() {
            Limit|error lim = value.cloneWithType(Limit);
            if (lim is Limit) {
                limits[key] = lim;
            } else {
                string errMsg = "Error occurred while constructing Limit record.";
                log:printError(errMsg + " value:" + value.toJsonString(), 'error = lim);
                return error Error(errMsg, lim);
            }
        }
    }
    return limits;
}

isolated function toSoqlResult(json payload) returns SoqlResult|Error {
    SoqlResult|error res = payload.cloneWithType(SoqlResult);

    if (res is SoqlResult) {
        return res;
    } else {
        string errMsg = "Error occurred while constructing SoqlResult record.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), 'error = res);
        return error Error(errMsg, res);
    }
}

isolated function toSoslResult(json payload) returns SoslResult|Error {
    SoslResult|error res = payload.cloneWithType(SoslResult);

    if (res is SoslResult) {
        return res;
    } else {
        string errMsg = "Error occurred while constructing SoslResult record.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), 'error = res);
        return error Error(errMsg, res);
    }
}

isolated function toSObjectMetaData(json payload) returns SObjectMetaData|Error {
    SObjectMetaData|error res = payload.cloneWithType(SObjectMetaData);

    if (res is SObjectMetaData) {
        return res;
    } else {
        string errMsg = "Error occurred while constructing SObjectMetaData record.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), 'error = res);
        return error Error(errMsg, res);
    }
}

isolated function toOrgMetadata(json payload) returns OrgMetadata|Error {
    OrgMetadata|error res = payload.cloneWithType(OrgMetadata);

    if (res is OrgMetadata) {
        return res;
    } else {
        string errMsg = "Error occurred while constructing OrgMetadata record.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), 'error = res);
        return error Error(errMsg, res);
    }
}

isolated function toSObjectBasicInfo(json payload) returns SObjectBasicInfo|Error {
    SObjectBasicInfo|error res = payload.cloneWithType(SObjectBasicInfo);

    if (res is SObjectBasicInfo) {
        return res;
    } else {
        string errMsg = "Error occurred while constructing SObjectBasicInfo record.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), 'error = res);
        return error Error(errMsg, res);
    }
}
