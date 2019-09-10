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

import ballerina/filepath;
import ballerina/io;
import ballerina/log;

# JSON insert operator client.
public type JsonInsertOperator client object {
    JobInfo job;
    SalesforceBaseClient httpBaseClient;

    public function __init(JobInfo job, SalesforceConfiguration salesforceConfig) {
        self.job = job;
        self.httpBaseClient = new(salesforceConfig);
    }

    # Create JSON insert batch.
    #
    # + payload - insertion data in JSON format
    # + return - BatchInfo record if successful else ConnectorError occured
    public remote function insert(json payload) returns @tainted BatchInfo|ConnectorError {
        json response = check self.httpBaseClient->createJsonRecord([<@untainted> JOB, self.job.id, <@untainted> BATCH], 
            payload);
        return getBatch(response);
    }

    # Create JSON insert batch using a JSON file.
    #
    # + filePath - insertion JSON file path
    # + return - BatchInfo record if successful else ConnectorError occured
    public remote function insertFile(string filePath) returns @tainted BatchInfo|ConnectorError {
        if (filepath:extension(filePath) == "json") {
            io:ReadableByteChannel|io:Error rbc = io:openReadableFile(filePath);

            if (rbc is io:Error) {
                string errMsg = "Error occurred while reading the json file, file: " + filePath;
                log:printError(errMsg, err = rbc);
                IOError ioError = error(IO_ERROR, message = errMsg, errorCode = IO_ERROR, cause = rbc);
                return ioError;
            } else {
                io:ReadableCharacterChannel|io:Error rch = new(rbc, "UTF8");

                if (rch is io:Error) {
                    string errMsg = "Error occurred while reading the json file, file: " + filePath;
                    log:printError(errMsg, err = rch);
                    IOError ioError = error(IO_ERROR, message = errMsg, errorCode = IO_ERROR, cause = rch);
                    return ioError;
                } else {
                    json|error fileContent = rch.readJson();

                    if (fileContent is json) {
                        json response = check self.httpBaseClient->createJsonRecord([<@untainted> JOB, self.job.id, 
                            <@untainted> BATCH], <@untainted> fileContent);
                        return getBatch(response);
                    } else {
                        string errMsg = "Error occurred while reading the json file, file: " + filePath;
                        log:printError(errMsg, err = fileContent);
                        IOError ioError = error(IO_ERROR, message = errMsg, errorCode = IO_ERROR, cause = fileContent);
                        return ioError;
                    }
                }
            }
        } else {
            string errMsg = "Invalid file type, file: " + filePath;
            log:printError(errMsg, err = ());
            IOError ioError = error(IO_ERROR, message = errMsg, errorCode = IO_ERROR);
            return ioError;
        }
    }

    # Get JSON insert operator job information.
    #
    # + return - JobInfo record if successful else ConnectorError occured
    public remote function getJobInfo() returns @tainted JobInfo|ConnectorError {
        json response = check self.httpBaseClient->getJsonRecord([<@untainted> JOB, self.job.id]);
        return getJob(response);
    }

    # Close JSON insert operator job.
    #
    # + return - JobInfo record if successful else ConnectorError occured
    public remote function closeJob() returns @tainted JobInfo|ConnectorError {
        json response = check self.httpBaseClient->createJsonRecord([<@untainted> JOB, self.job.id],
            JSON_STATE_CLOSED_PAYLOAD);
        return getJob(response);
    }

    # Abort JSON insert operator job.
    #
    # + return - JobInfo record if successful else ConnectorError occured
    public remote function abortJob() returns @tainted JobInfo|ConnectorError {
        json response = check self.httpBaseClient->createJsonRecord([<@untainted> JOB, self.job.id],
            JSON_STATE_ABORTED_PAYLOAD);
        return getJob(response);
    }

    # Get JSON insert batch information.
    #
    # + batchId - batch ID 
    # + return - BatchInfo record if successful else ConnectorError occured
    public remote function getBatchInfo(string batchId) returns @tainted BatchInfo|ConnectorError {
        json response = check self.httpBaseClient->getJsonRecord([<@untainted> JOB, self.job.id, <@untainted> BATCH, 
            batchId]);
        return getBatch(response);
    }

    # Get information of all batches of JSON insert operator job.
    #
    # + return - BatchInfo record if successful else ConnectorError occured
    public remote function getAllBatches() returns @tainted BatchInfo[]|ConnectorError {
        json response = check self.httpBaseClient->getJsonRecord([<@untainted> JOB, self.job.id, <@untainted> BATCH]);
        return getBatchInfoList(response);
    }

    # Retrieve the JSON batch request.
    #
    # + batchId - batch ID
    # + return - JSON Batch request if successful else ConnectorError occured
    public remote function getBatchRequest(string batchId) returns @tainted json|ConnectorError {
        return self.httpBaseClient->getJsonRecord([<@untainted> JOB, self.job.id, <@untainted> BATCH, batchId, 
            <@untainted> REQUEST]);
    }

    # Get the results of the batch.
    #
    # + batchId - batch ID
    # + numberOfTries - number of times checking the batch state
    # + waitTime - time between two tries in ms
    # + return - Batch result as CSV if successful else ConnectorError occured
    public remote function getResult(string batchId, int numberOfTries = 1, int waitTime = 3000) 
        returns @tainted Result[]|ConnectorError {
        return checkBatchStateAndGetResults(getBatchPointer, getResultsPointer, self, batchId, numberOfTries, waitTime);
    }
};
