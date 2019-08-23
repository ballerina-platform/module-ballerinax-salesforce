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

# XML insert operator client.
public type XmlInsertOperator client object {
    Job job;
    SalesforceBaseClient httpBaseClient;

    public function __init(Job job, SalesforceConfiguration salesforceConfig) {
        self.job = job;
        self.httpBaseClient = new(salesforceConfig);
    }

    # Create XML insert batch.
    #
    # + payload - insertion data in XML format
    # + return - Batch record if successful else SalesforceError occured
    public remote function insert(xml payload) returns @tainted Batch | SalesforceError {
        xml | SalesforceError xmlResponse = self.httpBaseClient->createXmlRecord([JOB, self.job.id, BATCH], payload);

        if (xmlResponse is xml) {
            Batch | SalesforceError batch = getBatch(xmlResponse);
            return batch;
        } else {
            return xmlResponse;
        }
    }

    # Create XML insert batch using a XML file.
    #
    # + filePath - insertion XML file path
    # + return - Batch record if successful else SalesforceError occured
    public remote function insertFile(string filePath) returns @tainted Batch | SalesforceError {
        if (filepath:extension(filePath) == "xml") {
            io:ReadableByteChannel|io:GenericError|io:ConnectionTimedOutError rbc = io:openReadableFile(filePath);

            if (rbc is io:GenericError|io:ConnectionTimedOutError) {
                log:printError("Error occurred while reading the xml file, file: " + filePath, err = rbc);
                return getSalesforceError("Error occurred while reading the xml file, file: " + filePath, 
                    http:STATUS_BAD_REQUEST.toString());
            } else {
                io:ReadableCharacterChannel|io:GenericError|io:ConnectionTimedOutError rch = new(rbc, "UTF8");

                if (rch is io:GenericError|io:ConnectionTimedOutError) {
                    log:printError("Error occurred while reading the xml file, file: " + filePath, err = rch);
                    return getSalesforceError("Error occurred while reading the xml file, file: " + filePath, 
                        http:STATUS_BAD_REQUEST.toString());
                } else {
                    xml|error fileContent = rch.readXml();

                    if (fileContent is xml) {
                        xml|SalesforceError response = self.httpBaseClient->createXmlRecord([<@untainted> JOB, 
                            self.job.id, <@untainted> BATCH], <@untainted> fileContent);

                        if (response is xml) {
                            Batch | SalesforceError batch = getBatch(response);
                            return batch;
                        } else {
                            return response;
                        }
                    } else {
                        log:printError("Error occurred while reading the xml file, file: " 
                            + filePath, err = fileContent);
                        return getSalesforceError("Error occurred while reading the xml file, file: " + filePath, 
                            http:STATUS_BAD_REQUEST.toString());
                    }
                }
            }
        } else {
            log:printError("Invalid file type, file: " + filePath);
            return getSalesforceError("Invalid file type, file: " + filePath, http:STATUS_BAD_REQUEST.toString());
        }
    }

    # Get XML insert operator job information.
    #
    # + return - Job record if successful else SalesforceError occured
    public remote function getJobInfo() returns @tainted  Job | SalesforceError {
        xml | SalesforceError xmlResponse = self.httpBaseClient->getXmlRecord([JOB, self.job.id]);
        if (xmlResponse is xml) {
            Job | SalesforceError job = getJob(xmlResponse);
            return job;
        } else {
            return xmlResponse;
        }
    }

    # Close XML insert operator job.
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

    # Abort XML insert operator job.
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

    # Get XML insert batch information.
    #
    # + batchId - batch ID 
    # + return - Batch record if successful else SalesforceError occured
    public remote function getBatchInfo(string batchId) returns @tainted  Batch | SalesforceError {
        xml | SalesforceError xmlResponse = self.httpBaseClient->getXmlRecord([JOB, self.job.id, BATCH, batchId]);
        if (xmlResponse is xml) {
            Batch | SalesforceError batch = getBatch(xmlResponse);
            return batch;
        } else {
            return xmlResponse;
        }
    }

    # Get information of all batches of XML insert operator job.
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

    # Retrieve the XML batch request.
    #
    # + batchId - batch ID
    # + return - JSON Batch request if successful else SalesforceError occured
    public remote function getBatchRequest(string batchId) returns @tainted  xml | SalesforceError {
        xml | SalesforceError xmlResponse = self.httpBaseClient->getXmlRecord([JOB, self.job.id, BATCH, batchId, REQUEST]);
        return xmlResponse;
    }

    # Get the results of the batch.
    #
    # + batchId - batch ID
    # + numberOfTries - number of times checking the batch state
    # + waitTime - time between two tries in ms
    # + return - Batch result as CSV if successful else SalesforceError occured
    public remote function getBatchResults(string batchId, int numberOfTries = 1, int waitTime = 3000) 
        returns @tainted Result[]|SalesforceError {
        int counter = 0;
        while (counter < numberOfTries) {
            Batch|SalesforceError batch = self->getBatchInfo(batchId);
            
            if (batch is Batch) {
                
                if (batch.state == COMPLETED) {
                    xml|SalesforceError result = 
                        self.httpBaseClient->getXmlRecord([JOB, self.job.id, BATCH, batchId, RESULT]);
                    if (result is xml) {
                        return getBatchResults(result);
                    } else {
                        return result;
                    }
                } else if (batch.state == FAILED) {
                    return getFailedBatchError(batch);
                } else {
                    printWaitingMessage(batch);
                }

            } else {
                return batch;
            }

            runtime:sleep(waitTime); // Sleep 3s.
            counter = counter + 1;
        }
        return getResultTimeoutError(batchId, numberOfTries, waitTime);
    }
};
