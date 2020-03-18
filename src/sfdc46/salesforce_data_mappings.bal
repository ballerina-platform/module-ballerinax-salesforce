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

function toVersions(json payload) returns Version[]|ConnectorError {
    Version[] versions = [];
    json[] versionsArr = <json[]> payload;

    foreach json ele in versionsArr {
        Version|error ver = Version.constructFrom(ele);

        if (ver is Version) {
            versions[versions.length()] = ver;
        } else {
            string errMsg = "Error occurred while constructing Version record.";
            log:printError(errMsg + " ele:" + ele.toJsonString(), err = ver);
            TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
                errorCode = TYPE_CONVERSION_ERROR, cause = ver);
            return typeError;
        }
    }
    return versions;
}

function toMapOfStrings(json payload) returns map<string>|ConnectorError {
    map<string>|error strMap = map<string>.constructFrom(payload);

    if (strMap is map<string>) {
        return strMap;
    } else {
        string errMsg = "Error occurred while constructing map<string>.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), err = strMap);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = strMap);
        return typeError;
    }
}

function toMapOfLimits(json payload) returns map<Limit>|ConnectorError {
    map<Limit> limits = {};
    map<json>|error payloadMap = map<json>.constructFrom(payload);

    if (payloadMap is error) {
        string errMsg = "Error occurred while constructing map<json> using json payload.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), err = payloadMap);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = payloadMap);
        return typeError;
    } else {
        foreach var [key, value] in payloadMap.entries() {
            Limit|error lim = Limit.constructFrom(value);
            if (lim is Limit) {
                limits[key] = lim;
            } else {
                string errMsg = "Error occurred while constructing Limit record.";
                log:printError(errMsg + " value:" + value.toJsonString(), err = lim);
                TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
                    errorCode = TYPE_CONVERSION_ERROR, cause = lim);
                return typeError;
            }
        }
    }
    return limits;
}

function toSoqlResult(json payload) returns SoqlResult|ConnectorError {
    SoqlResult|error res = SoqlResult.constructFrom(payload);

    if (res is SoqlResult) {
        return res;
    } else {
        string errMsg = "Error occurred while constructing SoqlResult record.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), err = res);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = res);
        return typeError;
    }
}

function toExecutionFeedback(json payload) returns ExecutionFeedback|ConnectorError {
    ExecutionFeedback|error res = ExecutionFeedback.constructFrom(payload);

    if (res is ExecutionFeedback) {
        return res;
    } else {
        string errMsg = "Error occurred while constructing ExecutionFeedback record.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), err = res);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = res);
        return typeError;
    }
}

function toSoslResult(json payload) returns SoslResult|ConnectorError {
    SoslResult|error res = SoslResult.constructFrom(payload);

    if (res is SoslResult) {
        return res;
    } else {
        string errMsg = "Error occurred while constructing SoslResult record.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), err = res);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = res);
        return typeError;
    }
}

function toSObject(json payload) returns SObject|ConnectorError {
    SObject|error res = SObject.constructFrom(payload);

    if (res is SObject) {
        return res;
    } else {
        string errMsg = "Error occurred while constructing SObject record.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), err = res);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = res);
        return typeError;
    }
}

function toSObjectTreeResponse(json payload) returns SObjectTreeResponse|ConnectorError {
    SObjectTreeResponse|error res = SObjectTreeResponse.constructFrom(payload);

    if (res is SObjectTreeResponse) {
        return res;
    } else {
        string errMsg = "Error occurred while constructing SObjectTreeResponse record.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), err = res);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = res);
        return typeError;
    }
}

function toSObjectResult(json payload) returns SObjectResult|ConnectorError {
    SObjectResult|error res = SObjectResult.constructFrom(payload);

    if (res is SObjectResult) {
        return res;
    } else {
        string errMsg = "Error occurred while constructing SObjectResult record.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), err = res);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = res);
        return typeError;
    }
}

function toDeletedRecordsInfo(json payload) returns DeletedRecordsInfo|ConnectorError {
    DeletedRecordsInfo|error res = DeletedRecordsInfo.constructFrom(payload);

    if (res is DeletedRecordsInfo) {
        return res;
    } else {
        string errMsg = "Error occurred while constructing DeletedRecordsInfo record.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), err = res);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = res);
        return typeError;
    }
}

function toSObjectMetaData(json payload) returns SObjectMetaData|ConnectorError {
    SObjectMetaData|error res = SObjectMetaData.constructFrom(payload);

    if (res is SObjectMetaData) {
        return res;
    } else {
        string errMsg = "Error occurred while constructing SObjectMetaData record.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), err = res);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = res);
        return typeError;
    }
}

function toOrgMetadata(json payload) returns OrgMetadata|ConnectorError {
    OrgMetadata|error res = OrgMetadata.constructFrom(payload);

    if (res is OrgMetadata) {
        return res;
    } else {
        string errMsg = "Error occurred while constructing OrgMetadata record.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), err = res);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = res);
        return typeError;
    }
}

function toSObjectBasicInfo(json payload) returns SObjectBasicInfo|ConnectorError {
    SObjectBasicInfo|error res = SObjectBasicInfo.constructFrom(payload);

    if (res is SObjectBasicInfo) {
        return res;
    } else {
        string errMsg = "Error occurred while constructing SObjectBasicInfo record.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), err = res);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = res);
        return typeError;
    }
}

function toUpdatedRecordsInfo(json payload) returns UpdatedRecordsInfo|ConnectorError {
    UpdatedRecordsInfo|error res = UpdatedRecordsInfo.constructFrom(payload);

    if (res is UpdatedRecordsInfo) {
        return res;
    } else {
        string errMsg = "Error occurred while constructing UpdatedRecordsInfo record.";
        log:printError(errMsg + " payload:" + payload.toJsonString(), err = res);
        TypeConversionError typeError = error(TYPE_CONVERSION_ERROR, message = errMsg,
            errorCode = TYPE_CONVERSION_ERROR, cause = res);
        return typeError;
    }
}
