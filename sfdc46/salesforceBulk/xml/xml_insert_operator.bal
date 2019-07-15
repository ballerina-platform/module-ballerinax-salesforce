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
    SalesforceBaseClient httpClient;

    public function __init(Job job, SalesforceConfiguration salesforceConfig) {
        self.job = job;
        self.httpClient = new(salesforceConfig);
    }

    public remote function upload(xml payload) returns Batch | SalesforceError;
    public remote function getJobInfo() returns Job | SalesforceError;
    public remote function closeJob() returns Job | SalesforceError;
    public remote function abortJob() returns Job | SalesforceError;
    public remote function getBatchInfo(string batchId) returns Batch | SalesforceError;
    public remote function getAllBatches() returns BatchInfo | SalesforceError;
    public remote function getBatchRequest(string batchId) returns xml | SalesforceError;
    public remote function getBatchResults(string batchId) returns xml | SalesforceError;
};

# Create XML insert batch.
#
# + payload - insertion data in XML format
# + return - Batch record if successful else SalesforceError occured
public remote function XmlInsertOperator.upload(xml payload) returns Batch | SalesforceError {
    xml | SalesforceError xmlResponse = self.httpClient->createXmlRecord([JOB, self.job.id, BATCH], payload);

    if (xmlResponse is xml) {
        Batch | SalesforceError batch = getBatch(xmlResponse);
        return batch;
    } else {
        return xmlResponse;
    }
}

# Get XML insert operator job information.
#
# + return - Job record if successful else SalesforceError occured
public remote function XmlInsertOperator.getJobInfo() returns Job | SalesforceError {
    xml | SalesforceError xmlResponse = self.httpClient->getXmlRecord([JOB, self.job.id]);
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
public remote function XmlInsertOperator.closeJob() returns Job | SalesforceError {
    xml | SalesforceError xmlResponse = self.httpClient->createXmlRecord([JOB, self.job.id], XML_STATE_CLOSED_PAYLOAD);
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
public remote function XmlInsertOperator.abortJob() returns Job | SalesforceError {
    xml | SalesforceError xmlResponse = self.httpClient->createXmlRecord([JOB, self.job.id], XML_STATE_ABORTED_PAYLOAD);
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
public remote function XmlInsertOperator.getBatchInfo(string batchId) returns Batch | SalesforceError {
    xml | SalesforceError xmlResponse = self.httpClient->getXmlRecord([JOB, self.job.id, BATCH, batchId]);
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
public remote function XmlInsertOperator.getAllBatches() returns BatchInfo | SalesforceError {
    xml | SalesforceError xmlResponse = self.httpClient->getXmlRecord([JOB, self.job.id, BATCH]);
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
public remote function XmlInsertOperator.getBatchRequest(string batchId) returns xml | SalesforceError {
    xml | SalesforceError xmlResponse = self.httpClient->getXmlRecord([JOB, self.job.id, BATCH, batchId, REQUEST]);
    return xmlResponse;
}

# Get the results of the batch.
#
# + batchId - batch ID
# + return - Batch result in XML if successful else SalesforceError occured
public remote function XmlInsertOperator.getBatchResults(string batchId) returns xml | SalesforceError {
    xml | SalesforceError xmlResponse = self.httpClient->getXmlRecord([JOB, self.job.id, BATCH, batchId, RESULT]);
    return xmlResponse;
}
