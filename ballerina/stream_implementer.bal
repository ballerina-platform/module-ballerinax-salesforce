// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;

class SOQLQueryResultStream {
    private record {}[] currentEntries = [];
    private string nextRecordsUrl;
    int index = 0;
    private final http:Client httpClient;
    private final string path;
    private final typedesc<record {}[]> returnType;

    isolated function init(http:Client httpClient, string path, typedesc<record {}[]> returnType) returns error? {
        self.httpClient = httpClient;
        self.path = path;
        self.returnType = returnType;
        self.nextRecordsUrl = PRIVATE_EMPTY_STRING;
        self.currentEntries = check self.fetchQueryResult();
    }

    public isolated function next() returns record {|record {} value;|}|error? {
        if (self.index < self.currentEntries.length()) {
            record {|record {} value;|} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        // This code block is for retrieving the next batch of records when the initial batch is finished.
        if (self.nextRecordsUrl.trim() != PRIVATE_EMPTY_STRING) {
            self.index = 0;
            self.currentEntries = check self.fetchQueryResult();
            record {|record {} value;|} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        return;
    }

    isolated function fetchQueryResult() returns record {}[]|error {
        SoqlQueryResult response;
        if (self.nextRecordsUrl.trim() != PRIVATE_EMPTY_STRING) {
            response = check self.httpClient->get(self.nextRecordsUrl);
        } else {
            response = check self.httpClient->get(self.path);
        }
        self.nextRecordsUrl = response.hasKey(NEXT_RECORDS_URL) ? check response.get(NEXT_RECORDS_URL).ensureType() :
            PRIVATE_EMPTY_STRING;

        record {}[] returnData = check response.records.cloneWithType(self.returnType);
        return returnData;
    }
}

class SOSLSearchResult {
    private record {}[] currentEntries = [];
    int index = 0;
    private final http:Client httpClient;
    private final string path;

    isolated function init(http:Client httpClient, string path) returns error? {
        self.httpClient = httpClient;
        self.path = path;
        self.currentEntries = check self.fetchSearchResult();
    }

    public isolated function next() returns record {|record {} value;|}|error? {
        if (self.index < self.currentEntries.length()) {
            record {|record {} value;|} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        return;
    }

    isolated function fetchSearchResult() returns record {}[]|error {
        SoslSearchResult response = check self.httpClient->get(self.path);
        record{}[] array = response.searchRecords;
        return array;
    }
}

isolated function covertSearchResultsToRecordsArray(map<json>[] queryResultArray) returns record {}[]|error {
    record {}[] resultRecordArray = [];
    foreach map<json> queryResult in queryResultArray {
        resultRecordArray.push(check queryResult.cloneWithType(Record));
    }
    return resultRecordArray;
}

type Record record {};

# Define the SOQL result type.
#
# + done - Query is completed or not
# + totalSize - The total number result records
# + records - Result records
type SoqlQueryResult record {|
    boolean done;
    int totalSize;
    record {}[] records;
    json...;
|};

# Defines SOSL query result.
#
# + searchRecords - Matching records for the given search string
type SoslSearchResult record {|
    SoslRecordData[] searchRecords;
    json...;
|};

# Defines SOSL query result.
#
# + attributes - Attribute record
# + Id - ID of the matching object
type SoslRecordData record {|
    Attribute attributes;
    string Id;
    json...;
|};
