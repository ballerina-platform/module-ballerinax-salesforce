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

class SoqlQueryResultStream {
    private record{}[] currentEntries = [];
    private string nextRecordsUrl;
    int index = 0;
    private final http:Client httpClient;
    private final string path;

    isolated function  init(http:Client httpClient, string path) returns @tainted error? {
        self.httpClient = httpClient;
        self.path = path;
        self.nextRecordsUrl = EMPTY_STRING;
        self.currentEntries = check self.fetchQueryResult();
    }

    public isolated function next() returns @tainted record {| record{} value; |}|error? {
        if(self.index < self.currentEntries.length()) {
            record {| record{} value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        // This code block is for retrieving the next batch of records when the initial batch is finished.
        if (self.nextRecordsUrl.trim() != EMPTY_STRING) {
            self.index = 0;
            self.currentEntries = check self.fetchQueryResult();
            record {| record{} value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        return;
    }

    isolated function fetchQueryResult() returns @tainted record{}[]|error {
          SoqlQueryResult response;
          if (self.nextRecordsUrl.trim() != EMPTY_STRING) {
               response = check self.httpClient->get(self.nextRecordsUrl);
          } else {
               response = check self.httpClient->get(self.path);
          }
          self.nextRecordsUrl = response.hasKey("nextRecordsUrl") ? check response.get("nextRecordsUrl").ensureType() : EMPTY_STRING;

          map<json>[] array = response.records;
          return check covertToRecordsArray(array);
    }
}

isolated function covertToRecordsArray(map<json>[] queryResultArray) returns record{}[]|error {
     record {}[] resultRecordArray = [];
     foreach map<json> queryResult in queryResultArray {
          _ = check queryResult.removeIfHasKey("attributes").ensureType();
          resultRecordArray.push(check queryResult.cloneWithType(Record));
     }
     return resultRecordArray;
}

class SoslSearchResultStream {
    private record{}[] currentEntries = [];
    int index = 0;
    private final http:Client httpClient;
    private final string path;

    isolated function  init(http:Client httpClient, string path) returns @tainted error? {
        self.httpClient = httpClient;
        self.path = path;
        self.currentEntries = check self.fetchSearchResult();
    }

    public isolated function next() returns @tainted record {| record{} value; |}|error? {
        if(self.index < self.currentEntries.length()) {
            record {| record{} value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        return;
    }

    isolated function fetchSearchResult() returns @tainted record{}[]|error {
          SoslSearchResult response = check self.httpClient->get(self.path);
          map<json>[] array = response.searchRecords;
          return check covertSearchResultsToRecordsArray(array);
    }
}

isolated function covertSearchResultsToRecordsArray(map<json>[] queryResultArray) returns record{}[]|error {
     record {}[] resultRecordArray = [];
     foreach map<json> queryResult in queryResultArray {
        resultRecordArray.push(check queryResult.cloneWithType(Record));
     }
     return resultRecordArray;
}

type Record record{};

# Define the SOQL result type.
#
# + done - Query is completed or not
# + totalSize - The total number result records
# + records - Result records
type SoqlQueryResult record {|
    boolean done;
    int totalSize;
    SoqlRecord[] records;
    json...;
|};

# Defines the SOQL query result record type. 
#
# + attributes - Attribute record
type SoqlRecord record {|
    Attribute attributes?;
    json...;
|};

# Defines SOSL query result.
#
# + searchRecords - Matching records for the given search string
type SoslSearchResult record {|
    SoslRecord[] searchRecords;
    json...;
|};

# Defines SOSL query result.
#
# + attributes - Attribute record
# + Id - ID of the matching object
type SoslRecord record {|
    Attribute attributes;
    string Id;
    json...;
|};

# Defines the Attribute type.
# Contains the attribute information of the resultant record.
#
# + type - Type of the resultant record
# + url - URL of the resultant record
type Attribute record {|
    string 'type;
    string url;
|};