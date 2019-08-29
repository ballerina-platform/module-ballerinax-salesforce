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

import ballerina/encoding;
import ballerina/filepath;
import ballerina/io;
import ballerina/log;
import ballerina/http;

# CSV insert operator client.
public type CsvInsertOperator client object {
    Job job;
    SalesforceBaseClient httpBaseClient;

    public function __init(Job job, SalesforceConfiguration salesforceConfig) {
        self.job = job;
        self.httpBaseClient = new(salesforceConfig);
    }

    # Create CSV insert batch.
    #
    # + csvContent - insertion data in CSV format
    # + return - Batch record if successful else SalesforceError occured
    public remote function insert(string csvContent) returns @tainted Batch | SalesforceError {
        xml | SalesforceError xmlResponse = self.httpBaseClient->createCsvRecord([JOB, self.job.id, BATCH], csvContent);
        if (xmlResponse is xml) {
            Batch | SalesforceError batch = getBatch(xmlResponse);
            return batch;
        } else {
            return xmlResponse;
        }
    }

    # Create CSV insert batch using a CSV file.
    #
    # + filePath - insertion CSV file path
    # + return - Batch record if successful else SalesforceError occured
    public remote function insertFile(string filePath) returns @tainted Batch | SalesforceError {
        if (filepath:extension(filePath) == "csv") {
            io:ReadableByteChannel|io:GenericError|io:ConnectionTimedOutError rbc = io:openReadableFile(filePath);

            if (rbc is io:GenericError|io:ConnectionTimedOutError) {
                log:printError("Error occurred while reading the csv file, file: " + filePath, err = rbc);
                return getSalesforceError("Error occurred while reading the csv file, file: " + filePath, 
                    http:STATUS_BAD_REQUEST.toString());
            } else {
                // Read content.
                int readCount = 1;
                byte[] readContent;
                string textContent = "";
                while (readCount > 0) {
                    [byte[], int]|io:GenericError|io:ConnectionTimedOutError result = rbc.read(1000);
                    if (result is io:GenericError|io:ConnectionTimedOutError) {
                        log:printError("Error occurred while reading the csv file, file: " + filePath, err = result);
                        return getSalesforceError("Error occurred while reading the csv file, file: " + filePath, 
                            http:STATUS_BAD_REQUEST.toString());
                    } else {
                        [readContent, readCount] = result;  
                        textContent = textContent + encoding:byteArrayToString(readContent, "UTF-8");                      
                    }
                }
                // close channel.
                closeRb(rbc);

                xml | SalesforceError response = 
                self.httpBaseClient->createCsvRecord([<@untainted> JOB, self.job.id, <@untainted> BATCH], textContent);

                if (response is xml) {
                    Batch | SalesforceError batch = getBatch(response);
                    return batch;
                } else {
                    return response;
                }
            }
        } else {
            log:printError("Invalid file type, file: " + filePath);
            return getSalesforceError("Invalid file type, file: " + filePath, http:STATUS_BAD_REQUEST.toString());
        }
    }

    # Get CSV insert operator job information.
    #
    # + return - Job record if successful else SalesforceError occured
    public remote function getJobInfo() returns @tainted Job | SalesforceError {
        xml | SalesforceError xmlResponse = self.httpBaseClient->getXmlRecord([JOB, self.job.id]);
        if (xmlResponse is xml) {
            Job | SalesforceError job = getJob(xmlResponse);
            return job;
        } else {
            return xmlResponse;
        }
    }

    # Close CSV insert operator job.
    #
    # + return - Job record if successful else SalesforceError occured
    public remote function closeJob() returns @tainted Job | SalesforceError {
        xml | SalesforceError xmlResponse = self.httpBaseClient->createXmlRecord([JOB, self.job.id], 
        XML_STATE_CLOSED_PAYLOAD);
        if (xmlResponse is xml) {
            Job | SalesforceError job = getJob(xmlResponse);
            return job;
        } else {
            return xmlResponse;
        }
    }

    # Abort CSV insert operator job.
    #
    # + return - Job record if successful else SalesforceError occured
    public remote function abortJob() returns @tainted Job | SalesforceError {
        xml | SalesforceError xmlResponse = self.httpBaseClient->createXmlRecord([JOB, self.job.id], 
        XML_STATE_ABORTED_PAYLOAD);
        if (xmlResponse is xml) {
            Job | SalesforceError job = getJob(xmlResponse);
            return job;
        } else {
            return xmlResponse;
        }
    }

    # Get CSV insert batch information.
    #
    # + batchId - batch ID 
    # + return - Batch record if successful else SalesforceError occured
    public remote function getBatchInfo(string batchId) returns @tainted Batch | SalesforceError {
        xml | SalesforceError xmlResponse = self.httpBaseClient->getXmlRecord([JOB, self.job.id, BATCH, batchId]);
        if (xmlResponse is xml) {
            Batch | SalesforceError batch = getBatch(xmlResponse);
            return batch;
        } else {
            return xmlResponse;
        }
    }

    # Get information of all batches of CSV insert operator job.
    #
    # + return - BatchInfo record if successful else SalesforceError occured
    public remote function getAllBatches() returns @tainted BatchInfo | SalesforceError {
        xml | SalesforceError xmlResponse = self.httpBaseClient->getXmlRecord([JOB, self.job.id, BATCH]);
        if (xmlResponse is xml) {
            BatchInfo | SalesforceError batchInfo = getBatchInfo(xmlResponse);
            return batchInfo;
        } else {
            return xmlResponse;
        }
    }

    # Retrieve the CSV batch request.
    #
    # + batchId - batch ID
    # + return - CSV Batch request if successful else SalesforceError occured
    public remote function getBatchRequest(string batchId) returns @tainted string | SalesforceError {
        return self.httpBaseClient->getCsvRecord([JOB, self.job.id, BATCH, batchId, REQUEST]);
    }

    # Get the results of the batch.
    #
    # + batchId - batch ID
    # + numberOfTries - number of times checking the batch state
    # + waitTime - time between two tries in ms
    # + return - Results array if successful else SalesforceError occured
    public remote function getResult(string batchId, int numberOfTries = 1, int waitTime = 3000) 
        returns @tainted Result[]|SalesforceError {
        return checkBatchStateAndGetResults(getBatchPointer, getResultsPointer, self, batchId, numberOfTries, waitTime);
    }
};
