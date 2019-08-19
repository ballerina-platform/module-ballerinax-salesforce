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

public type ResultList record {
    string[] result;
};

function getResultList(xml|json resultListDetails) returns ResultList | SalesforceError {
    if(resultListDetails is xml){
        return createResultListRecordFromXml(resultListDetails);
    }else{
        return createResultListRecordFromJson(resultListDetails);
    }
}

function createResultListRecordFromXml(xml payload) returns ResultList | SalesforceError {
    string[] results = [];
    foreach var result in payload.*.elements() {
        if (result is xml) {
            string | SalesforceError resultId = result.getTextValue();
            if (resultId is string) {
                results[results.length()] = resultId;
            } else {
                return getSalesforceError("Error occurred when retrieving result id.", "500");
            }
        }
    }

    ResultList resultList = {
        result: results
    };
    return resultList;
}

function createResultListRecordFromJson(json payload) returns ResultList | SalesforceError {
    string[] results = [];
    json[] resultsArr = <json[]>payload;

    foreach json result in resultsArr {
        string resultId = result.toString();
        results[results.length()] = resultId;
    }

    ResultList resultList = {
        result: results
    };
    return resultList;
}
