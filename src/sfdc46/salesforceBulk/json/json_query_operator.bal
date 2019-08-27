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

# JSON query operator client.
public type JsonQueryOperator client object {
    Job job;
    SalesforceBaseClient httpBaseClient;

    public function __init(Job job, SalesforceConfiguration salesforceConfig) {
        self.job = job;
        self.httpBaseClient = new(salesforceConfig);
    }

    # Create JSON query batch.
    #
    # + queryString - SOQL query want to perform
    # + return - Batch record if successful else SalesforceError occured
    public remote function query(string queryString) returns @tainted Batch | SalesforceError {
        json | SalesforceError jsonPayload = self.httpBaseClient->createJsonQuery([<@untainted> JOB, self.job.id, 
        <@untainted> BATCH], queryString);
        if (jsonPayload is json) {
            Batch | SalesforceError batch = getBatch(jsonPayload);
            return batch;
        } else {
            return jsonPayload;
        }
    }

    # Get JSON query operator job information.
    #
    # + return - Job record if successful else SalesforceError occured
    public remote function getJobInfo() returns @tainted Job | SalesforceError {
        json | SalesforceError payload = self.httpBaseClient->getJsonRecord([<@untainted> JOB, self.job.id]);
        if (payload is json) {
            Job | SalesforceError job = getJob(payload);
            return job;
        } else {
            return payload;
        }
    }

    # Close JSON query operator job.
    #
    # + return - Job record if successful else SalesforceError occured
    public remote function closeJob() returns @tainted Job | SalesforceError {
        json | SalesforceError payload = self.httpBaseClient->createJsonRecord([<@untainted> JOB, self.job.id], 
        JSON_STATE_CLOSED_PAYLOAD);
        if (payload is json) {
            Job | SalesforceError job = getJob(payload);
            return job;
        } else {
            return payload;
        }
    }

    # Abort JSON query operator job.
    #
    # + return - Job record if successful else SalesforceError occured
    public remote function abortJob() returns @tainted Job | SalesforceError {
        json | SalesforceError payload = self.httpBaseClient->createJsonRecord([<@untainted> JOB, self.job.id], 
        JSON_STATE_ABORTED_PAYLOAD);
        if (payload is json) {
            Job | SalesforceError job = getJob(payload);
            return job;
        } else {
            return payload;
        }
    }

    # Get JSON query batch information.
    #
    # + batchId - batch ID 
    # + return - Batch record if successful else SalesforceError occured
    public remote function getBatchInfo(string batchId) returns @tainted Batch | SalesforceError {
        json | SalesforceError payload = self.httpBaseClient->getJsonRecord([<@untainted> JOB, self.job.id, 
        <@untainted> BATCH, batchId]);
        if (payload is json) {
            Batch | SalesforceError batch = getBatch(payload);
            return batch;
        } else {
            return payload;
        }
    }

    # Get information of all batches of JSON query operator job.
    #
    # + return - BatchInfo record if successful else SalesforceError occured
    public remote function getAllBatches() returns @tainted BatchInfo | SalesforceError {
        json | SalesforceError payload = self.httpBaseClient->getJsonRecord([<@untainted> JOB, self.job.id, 
        <@untainted> BATCH]);
        if (payload is json) {
            BatchInfo | SalesforceError batchInfo = getBatchInfo(payload);
            return batchInfo;
        } else {
            return payload;
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
                    json | SalesforceError payload = self.httpBaseClient->getJsonRecord([<@untainted> JOB, self.job.id, 
                        <@untainted> BATCH, batchId, <@untainted> RESULT]);
                    if (payload is json) {
                        ResultList | SalesforceError resultList = getResultList(payload);
                        return resultList;
                    } else {
                        return payload;
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
    # + return - Query result in JSON format if successful else SalesforceError occured
    public remote function getResult(string batchId, string resultId) returns @tainted json | SalesforceError {
        return self.httpBaseClient->getJsonRecord([<@untainted> JOB, self.job.id, <@untainted> BATCH, batchId, 
        <@untainted> RESULT, resultId]);
    }
};
