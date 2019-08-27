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

import ballerina/runtime;

# CSV query operator client.
public type CsvQueryOperator client object {
    Job job;
    SalesforceBaseClient httpBaseClient;

    public function __init(Job job, SalesforceConfiguration salesforceConfig) {
        self.job = job;
        self.httpBaseClient = new(salesforceConfig);
    }

    # Create CSV query batch.
    #
    # + queryString - SOQL query want to perform
    # + return - Batch record if successful else SalesforceError occured
    public remote function query(string queryString) returns @tainted Batch | SalesforceError {
        xml | SalesforceError xmlResponse = self.httpBaseClient->createCsvRecord([JOB, self.job.id, BATCH], queryString);
        if (xmlResponse is xml) {
            Batch | SalesforceError batch = getBatch(xmlResponse);
            return batch;
        } else {
            return xmlResponse;
        }
    }

    # Get CSV query operator job information.
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

    # Close CSV query operator job.
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

    # Abort CSV query operator job.
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

    # Get CSV query batch information.
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

    # Get information of all batches of CSV query operator job.
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

    # Get result IDs as a list.
    #
    # + batchId - batch ID
    # + numberOfTries - number of times checking the batch state
    # + waitTime - time between two tries in ms
    # + return - ResultList record if successful else SalesforceError occured
    public remote function getResultList(string batchId, int numberOfTries = 1, int waitTime = 3000) 
        returns @tainted ResultList | SalesforceError {
        int counter = 0;
        while (counter < numberOfTries) {
            Batch|SalesforceError batch = self->getBatchInfo(batchId);
            
            if (batch is Batch) {

                if (batch.state == COMPLETED) {
                    xml | SalesforceError response = 
                        self.httpBaseClient->getXmlRecord([JOB, self.job.id, BATCH, batchId, RESULT]);
                    if (response is xml) {
                        ResultList | SalesforceError resultList = getResultList(response);
                        return resultList;
                    } else {
                        return response;
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

    # Get query results.
    #
    # + batchId - batch ID
    # + resultId - result ID
    # + return - Query result in CSV format if successful else SalesforceError occured
    public remote function getResult(string batchId, string resultId) returns @tainted string | SalesforceError {
        return self.httpBaseClient->getCsvRecord([JOB, self.job.id, BATCH, batchId, RESULT, resultId]);
    }
};
