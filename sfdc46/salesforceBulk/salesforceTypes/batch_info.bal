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

public type BatchInfo record {
    Batch[] batchInfoList;
};

function getBatchInfo(xml|json batchInfoDetails) returns BatchInfo|SalesforceError {
    if(batchInfoDetails is xml){
        return createBatchInfoRecordFromXml(batchInfoDetails);
    } else {
        return createBatchInfoRecordFromJson(batchInfoDetails);
    }
}

function createBatchInfoRecordFromXml(xml batchInfoDetails) returns BatchInfo | SalesforceError {
    Batch[] batchInfoList = [];
    foreach var batchDetails in batchInfoDetails.*.elements() {
        if (batchDetails is xml) {
            Batch | SalesforceError batch = getBatch(batchDetails);
            if (batch is Batch) {
                batchInfoList[batchInfoList.length()] = batch;
            } else {
                return getSalesforceError("Error occurred when creating batch info record.", "500");
            }
        }
    }

    BatchInfo batchInfo = {
        batchInfoList: batchInfoList
    };
    return batchInfo;
}

function createBatchInfoRecordFromJson(json batchInfoDetails) returns BatchInfo | SalesforceError {
    Batch[] batchInfoList = [];

    json[] batchInfoArr = <json[]>batchInfoDetails.batchInfo;
    foreach json batchInfo in batchInfoArr {
        Batch | SalesforceError batch = getBatch(batchInfo);
        if (batch is Batch) {
            batchInfoList[batchInfoList.length()] = batch;
        } else {
            return getSalesforceError("Error occurred when creating batch info record from JSON.", "500");
        }
    }

    BatchInfo batchInfo = {
        batchInfoList: batchInfoList
    };
    return batchInfo;
}
