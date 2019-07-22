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

# JSON insert operator client.
public type JsonInsertOperator client object {
    Job job;
    SalesforceBaseClient httpBaseClient;

    public function __init(Job job, SalesforceConfiguration salesforceConfig) {
        self.job = job;
        self.httpBaseClient = new(salesforceConfig);
    }

    # Create JSON insert batch.
    #
    # + payload - insertion data in JSON format
    # + return - Batch record if successful else SalesforceError occured
    public remote function upload(json payload) returns @tainted Batch | SalesforceError {
        json | SalesforceError response = self.httpBaseClient->createJsonRecord([<@untainted> JOB, self.job.id, 
            <@untainted> BATCH], payload);

        if (response is json) {
            Batch | SalesforceError batch = getBatch(response);
            return batch;
        } else {
            return response;
        }
    }

    # Create JSON insert batch using a JSON file.
    #
    # + filePath - insertion JSON file path
    # + return - Batch record if successful else SalesforceError occured
    public remote function uploadFile(string filePath) returns @tainted Batch | SalesforceError {
        if (filepath:extension(filePath) == "json") {
            io:ReadableByteChannel|io:GenericError|io:ConnectionTimedOutError rbc = io:openReadableFile(filePath);

            if (rbc is io:GenericError|io:ConnectionTimedOutError) {
                log:printError("Error occurred while reading the json file, file: " + filePath, err = rbc);
                return getSalesforceError("Error occurred while reading the json file, file: " + filePath, 
                    http:STATUS_BAD_REQUEST.toString());
            } else {
                io:ReadableCharacterChannel|io:GenericError|io:ConnectionTimedOutError rch = new(rbc, "UTF8");

                if (rch is io:GenericError|io:ConnectionTimedOutError) {
                    log:printError("Error occurred while reading the json file, file: " + filePath, err = rch);
                    return getSalesforceError("Error occurred while reading the json file, file: " + filePath, 
                        http:STATUS_BAD_REQUEST.toString());
                } else {
                    json|error fileContent = rch.readJson();

                    if (fileContent is json) {
                        json | SalesforceError response = self.httpBaseClient->createJsonRecord([<@untainted> JOB, 
                            self.job.id, <@untainted> BATCH], <@untainted> fileContent);

                        if (response is json) {
                            Batch | SalesforceError batch = getBatch(response);
                            return batch;
                        } else {
                            return response;
                        }
                    } else {
                        log:printError("Error occurred while reading the json file, file: " + filePath, err = fileContent);
                        return getSalesforceError("Error occurred while reading the json file, file: " + filePath, 
                            http:STATUS_BAD_REQUEST.toString());
                    }
                }
            }
        } else {
            log:printError("Invalid file type, file: " + filePath);
            return getSalesforceError("Invalid file type, file: " + filePath, http:STATUS_BAD_REQUEST.toString());
        }
    }

    # Get JSON insert operator job information.
    #
    # + return - Job record if successful else SalesforceError occured
    public remote function getJobInfo() returns @tainted Job | SalesforceError {
        json | SalesforceError response = self.httpBaseClient->getJsonRecord([<@untainted> JOB, self.job.id]);
        if (response is json) {
            Job | SalesforceError job = getJob(response);
            return job;
        } else {
            return response;
        }
    }

    # Close JSON insert operator job.
    #
    # + return - Job record if successful else SalesforceError occured
    public remote function closeJob() returns @tainted Job | SalesforceError {
        json | SalesforceError response = self.httpBaseClient->createJsonRecord([<@untainted> JOB, self.job.id], 
        JSON_STATE_CLOSED_PAYLOAD);
        if (response is json) {
            Job | SalesforceError job = getJob(response);
            return job;
        } else {
            return response;
        }
    }

    # Abort JSON insert operator job.
    #
    # + return - Job record if successful else SalesforceError occured
    public remote function abortJob() returns @tainted Job | SalesforceError {
        json | SalesforceError response = self.httpBaseClient->createJsonRecord([<@untainted> JOB, self.job.id], 
        JSON_STATE_ABORTED_PAYLOAD);
        if (response is json) {
            Job | SalesforceError job = getJob(response);
            return job;
        } else {
            return response;
        }
    }

    # Get JSON insert batch information.
    #
    # + batchId - batch ID 
    # + return - Batch record if successful else SalesforceError occured
    public remote function getBatchInfo(string batchId) returns @tainted Batch | SalesforceError {
        json | SalesforceError response = self.httpBaseClient->getJsonRecord([<@untainted> JOB, self.job.id, 
        <@untainted> BATCH, batchId]);
        if (response is json) {
            Batch | SalesforceError batch = getBatch(response);
            return batch;
        } else {
            return response;
        }
    }

    # Get information of all batches of JSON insert operator job.
    #
    # + return - BatchInfo record if successful else SalesforceError occured
    public remote function getAllBatches() returns @tainted BatchInfo | SalesforceError {
        json | SalesforceError response = self.httpBaseClient->getJsonRecord([<@untainted> JOB, self.job.id, 
        <@untainted> BATCH]);
        if (response is json) {
            BatchInfo | SalesforceError batchInfo = getBatchInfo(response);
            return batchInfo;
        } else {
            return response;
        }
    }

    # Retrieve the JSON batch request.
    #
    # + batchId - batch ID
    # + return - JSON Batch request if successful else SalesforceError occured
    public remote function getBatchRequest(string batchId) returns @tainted json | SalesforceError {
        return self.httpBaseClient->getJsonRecord([<@untainted> JOB, self.job.id, <@untainted> BATCH, batchId, 
        <@untainted> REQUEST]);
    }

    # Get the results of the batch.
    #
    # + batchId - batch ID
    # + return - Batch result in JSON if successful else SalesforceError occured
    public remote function getBatchResults(string batchId) returns @tainted json | SalesforceError {
        return self.httpBaseClient->getJsonRecord([<@untainted> JOB, self.job.id, <@untainted> BATCH, batchId, 
        <@untainted> RESULT]);
    }
};
