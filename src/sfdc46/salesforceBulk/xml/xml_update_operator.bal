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

# XML update operator client.
public type XmlUpdateOperator client object {
    Job job;
    SalesforceBaseClient httpBaseClient;

    public function __init(Job job, SalesforceConfiguration salesforceConfig) {
        self.job = job;
        self.httpBaseClient = new(salesforceConfig);
    }

    # Create XML update batch.
    #
    # + payload - update data in XML format
    # + return - Batch record if successful else SalesforceError occured
    public remote function update(xml payload) returns @tainted Batch | SalesforceError {
        xml | SalesforceError xmlResponse = self.httpBaseClient->createXmlRecord([JOB, self.job.id, BATCH], payload);
        if (xmlResponse is xml) {
            Batch | SalesforceError batch = getBatch(xmlResponse);
            return batch;
        } else {
            return xmlResponse;
        }
    }

    # Get XML update operator job information.
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

    # Close XML update operator job.
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

    # Abort XML update operator job.
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

    # Get XML update batch information.
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

    # Get information of all batches of XML update operator job.
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
    public remote function getBatchRequest(string batchId) returns @tainted xml | SalesforceError {
        return self.httpBaseClient->getXmlRecord([JOB, self.job.id, BATCH, batchId, REQUEST]);
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
