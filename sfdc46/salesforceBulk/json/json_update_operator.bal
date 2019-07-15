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

# JSON update operator client.
public type JsonUpdateOperator client object {
    Job job;
    SalesforceBaseClient httpClient;

    public function __init(Job job, SalesforceConfiguration salesforceConfig) {
        self.job = job;
        self.httpClient = new(salesforceConfig);
    }

    public remote function upload(json payload) returns Batch | SalesforceError;
    public remote function getJobInfo() returns Job | SalesforceError;
    public remote function closeJob() returns Job | SalesforceError;
    public remote function abortJob() returns Job | SalesforceError;
    public remote function getBatchInfo(string batchId) returns Batch | SalesforceError;
    public remote function getAllBatches() returns BatchInfo | SalesforceError;
    public remote function getBatchRequest(string batchId) returns json | SalesforceError;
    public remote function getBatchResults(string batchId) returns json | SalesforceError;
};

# Create JSON update batch.
#
# + payload - update data in JSON format
# + return - Batch record if successful else SalesforceError occured
public remote function JsonUpdateOperator.upload(json payload) returns Batch | SalesforceError {
    json | SalesforceError response = self.httpClient->createJsonRecord([JOB, self.job.id, BATCH], payload);
    if (response is json) {
        Batch | SalesforceError batch = getBatch(response);
        return batch;
    } else {
        return response;
    }
}

# Get JSON update operator job information.
#
# + return - Job record if successful else SalesforceError occured
public remote function JsonUpdateOperator.getJobInfo() returns Job | SalesforceError {
    json | SalesforceError response = self.httpClient->getJsonRecord([JOB, self.job.id]);
    if (response is json) {
        Job | SalesforceError job = getJob(response);
        return job;
    } else {
        return response;
    }
}

# Close JSON update operator job.
#
# + return - Job record if successful else SalesforceError occured
public remote function JsonUpdateOperator.closeJob() returns Job | SalesforceError {
    json | SalesforceError response = self.httpClient->createJsonRecord([JOB, self.job.id], JSON_STATE_CLOSED_PAYLOAD);
    if (response is json) {
        Job | SalesforceError job = getJob(response);
        return job;
    } else {
        return response;
    }
}

# Abort JSON update operator job.
#
# + return - Job record if successful else SalesforceError occured
public remote function JsonUpdateOperator.abortJob() returns Job | SalesforceError {
    json | SalesforceError response = self.httpClient->createJsonRecord([JOB, self.job.id], JSON_STATE_ABORTED_PAYLOAD);
    if (response is json) {
        Job | SalesforceError job = getJob(response);
        return job;
    } else {
        return response;
    }
}

# Get JSON update batch information.
#
# + batchId - batch ID 
# + return - Batch record if successful else SalesforceError occured
public remote function JsonUpdateOperator.getBatchInfo(string batchId) returns Batch | SalesforceError {
    json | SalesforceError response = self.httpClient->getJsonRecord([JOB, self.job.id, BATCH, batchId]);
    if (response is json) {
        Batch | SalesforceError batch = getBatch(response);
        return batch;
    } else {
        return response;
    }
}

# Get information of all batches of JSON update operator job.
#
# + return - BatchInfo record if successful else SalesforceError occured
public remote function JsonUpdateOperator.getAllBatches() returns BatchInfo | SalesforceError {
    json | SalesforceError response = self.httpClient->getJsonRecord([JOB, self.job.id, BATCH]);
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
public remote function JsonUpdateOperator.getBatchRequest(string batchId) returns json | SalesforceError {
    return self.httpClient->getJsonRecord([JOB, self.job.id, BATCH, batchId, REQUEST]);
}

# Get the results of the batch.
#
# + batchId - batch ID
# + return - Batch result in JSON if successful else SalesforceError occured
public remote function JsonUpdateOperator.getBatchResults(string batchId) returns json | SalesforceError {
    return self.httpClient->getJsonRecord([JOB, self.job.id, BATCH, batchId, RESULT]);
}
