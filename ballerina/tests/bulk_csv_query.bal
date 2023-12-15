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

import ballerina/log;
import ballerina/test;
import ballerina/lang.runtime;

@test:Config {
    enable: true,
    dependsOn: [insertCsvFromFile, insertCsv, insertCsvStringArrayFromFile, insertCsvStreamFromFile]
}
function queryCsv() returns error? {
    runtime:sleep(delayInSecs);
    log:printInfo("baseClient -> queryCsv");
    string queryStr = "SELECT Id, Name FROM Contact WHERE Title='Professor Level 02'";

    BulkCreatePayload payloadq = {
        operation : "query",
        query : queryStr
    };

    //create job
    BulkJob queryJob = check baseClient->createJob(payloadq, QUERY);

    //get batch result
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        string[][]|error batchResult = baseClient->getqueryResult(queryJob.id);
        if batchResult is string[][] {
            if batchResult.length() == 7 {
                test:assertTrue(batchResult.length() == 7, msg = "Retrieving batch result failed.");
                break;
            } else {
                if currentRetry != maxIterations {
                    log:printWarn("getBatchResult Operation Failed! Retrying...");
                    runtime:sleep(delayInSecs);
                } else {
                    log:printWarn("getBatchResult Operation Failed! Giving up after 5 tries.");
                    test:assertFail(msg = batchResult.toString());
                }
            }
        } else {
            if currentRetry != maxIterations {
                log:printWarn("getBatchResult Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getBatchResult Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = batchResult.message());
            }
        }
    }

}
