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

# JSON query operator client.
public type JsonQueryOperator client object {
    Job job;
    SalesforceBaseClient httpClient;

    public function __init(Job job, SalesforceConfiguration salesforceConfig) {
        self.job = job;
        self.httpClient = new(salesforceConfig);
    }

    public remote function addQuery(string queryString) returns Batch | SalesforceError;
    public remote function getJobInfo() returns Job | SalesforceError;
    public remote function closeJob() returns Job | SalesforceError;
    public remote function abortJob() returns Job | SalesforceError;
    public remote function getBatchInfo(string batchId) returns Batch | SalesforceError;
    public remote function getAllBatches() returns BatchInfo | SalesforceError;
    public remote function getResultList(string batchId) returns ResultList | SalesforceError;
    public remote function getResult(string batchId, string resultId) returns json | SalesforceError;
};

# Create JSON query batch.
#
# + queryString - SOQL query want to perform
# + return - Batch record if successful else SalesforceError occured
public remote function JsonQueryOperator.addQuery(string queryString) returns Batch | SalesforceError {
    json | SalesforceError jsonPayload = self.httpClient->createJsonQuery([JOB, self.job.id, BATCH], queryString);
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
public remote function JsonQueryOperator.getJobInfo() returns Job | SalesforceError {
    json | SalesforceError payload = self.httpClient->getJsonRecord([JOB, self.job.id]);
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
public remote function JsonQueryOperator.closeJob() returns Job | SalesforceError {
    json | SalesforceError payload = self.httpClient->createJsonRecord([JOB, self.job.id], JSON_STATE_CLOSED_PAYLOAD);
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
public remote function JsonQueryOperator.abortJob() returns Job | SalesforceError {
    json | SalesforceError payload = self.httpClient->createJsonRecord([JOB, self.job.id], JSON_STATE_ABORTED_PAYLOAD);
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
public remote function JsonQueryOperator.getBatchInfo(string batchId) returns Batch | SalesforceError {
    json | SalesforceError payload = self.httpClient->getJsonRecord([JOB, self.job.id, BATCH, batchId]);
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
public remote function JsonQueryOperator.getAllBatches() returns BatchInfo | SalesforceError {
    json | SalesforceError payload = self.httpClient->getJsonRecord([JOB, self.job.id, BATCH]);
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
# + return - ResultList record if successful else SalesforceError occured
public remote function JsonQueryOperator.getResultList(string batchId) returns ResultList | SalesforceError {
    json | SalesforceError payload = self.httpClient->getJsonRecord([JOB, self.job.id, BATCH, batchId, RESULT]);
    if (payload is json) {
        ResultList | SalesforceError resultList = getResultList(payload);
        return resultList;
    } else {
        return payload;
    }
}

# Get query results.
#
# + batchId - batch ID
# + resultId - result ID
# + return - Query result in JSON format if successful else SalesforceError occured
public remote function JsonQueryOperator.getResult(string batchId, string resultId) returns json | SalesforceError {
    return self.httpClient->getJsonRecord([JOB, self.job.id, BATCH, batchId, RESULT, resultId]);
}
