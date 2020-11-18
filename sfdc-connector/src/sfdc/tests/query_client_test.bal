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

@test:Config {}
function testGetQueryResult() {
    QueryClient queryClient = baseClient->getQueryClient();
    log:printInfo("queryClient -> getQueryResult()");
    string sampleQuery = "SELECT name FROM Account";
    SoqlResult|Error res = queryClient->getQueryResult(sampleQuery);

    if (res is SoqlResult) {
        assertSoqlResult(res);
        string|error nextRecordsUrl = res["nextRecordsUrl"].toString();

        while (nextRecordsUrl is string && trim(nextRecordsUrl) != EMPTY_STRING) {
            log:printInfo("Found new query result set! nextRecordsUrl:" + nextRecordsUrl);
            SoqlResult|Error resp = queryClient->getNextQueryResult(<@untainted> nextRecordsUrl);

            if (resp is SoqlResult) {
                assertSoqlResult(resp);
                res = resp;
            } else {
                test:assertFail(msg = resp.message());
            }
        }
    } else {
        test:assertFail(msg = res.message());
    }
}

@test:Config {
    dependsOn: ["testUpdateRecord"]
}
function testSearchSOSLString() {
    QueryClient queryClient = baseClient->getQueryClient();
    log:printInfo("queryClient -> searchSOSLString()");
    string searchString = "FIND {WSO2 Inc}";
    SoslResult|Error res = queryClient->searchSOSLString(searchString);

    if (res is SoslResult) {
        test:assertTrue(res.searchRecords.length() > 0, msg = "Found 0 search records!");
        test:assertTrue(res.searchRecords[0].attributes.'type == ACCOUNT, 
            msg = "Matched search record is not an Account type!");
    } else {
        test:assertFail(msg = res.message());
    }
}

isolated function assertSoqlResult(SoqlResult|Error res) {
    if (res is SoqlResult) {
        test:assertTrue(res.totalSize > 0, "Total number result records is 0");
        test:assertTrue(res.'done, "Query is not completed");
        test:assertTrue(res.records.length() == res.totalSize, "Query result records not equal to totalSize");
    } else {
        test:assertFail(msg = res.message());
    }
}
