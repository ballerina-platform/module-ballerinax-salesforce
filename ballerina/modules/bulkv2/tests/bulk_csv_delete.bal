// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/lang.runtime;
import ballerina/log;
import ballerina/test;

@test:AfterSuite {}
function deleteCSV() returns error? {
    Client baseClient = check new (sfConfigRefreshCodeFlow);
    if !isLiveServer {
        return;
    }
    log:printInfo("baseClient -> deleteCsv");
    //create job
    BulkCreatePayload payload = {
        'object: "Contact",
        contentType: "CSV",
        operation: "delete",
        lineEnding: "LF"
    };
    BulkJob insertJob = check baseClient->createIngestJob(payload);

    //add csv content
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error? response = baseClient->addBatch(insertJob.id, batchId);
        if response is error {
            if currentRetry == maxIterations {
                log:printWarn("addBatch Operation Failed!");
                test:assertFail(msg = "Could not upload the contacts using CSV. " + response.message());
            } else {
                log:printWarn("addBatch Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            }
        } else {
            break;
        }
    }

    //get job info
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        error|BulkJobInfo jobInfo = baseClient->getJobInfo(insertJob.id, INGEST);
        if jobInfo is BulkJobInfo {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
            break;
        } else {
            if currentRetry != maxIterations {
                log:printWarn("getJobInfo Operation Failed! Retrying...");
                runtime:sleep(delayInSecs);
            } else {
                log:printWarn("getJobInfo Operation Failed! Giving up after 5 tries.");
                test:assertFail(msg = jobInfo.message());
            }
        }
    }

    //close job
    foreach int currentRetry in 1 ..< maxIterations + 1 {
        future<BulkJobInfo|error> closedJob = check baseClient->closeIngestJobAndWait(insertJob.id);
        BulkJobInfo|error closedJobInfo = wait closedJob;
        if closedJobInfo is BulkJobInfo {
            test:assertTrue(closedJobInfo.state == "JobComplete", msg = "Closing job failed.");
            break;
        } else {
            test:assertFail(msg = closedJobInfo.message());
        }
    }
}
