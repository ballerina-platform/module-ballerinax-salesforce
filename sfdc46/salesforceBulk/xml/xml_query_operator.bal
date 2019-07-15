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

# XML query operator client.
public type XmlQueryOperator client object {
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
    public remote function getResult(string batchId, string resultId) returns xml | SalesforceError;
};

# Create XML query batch.
#
# + queryString - SOQL query want to perform
# + return - Batch record if successful else SalesforceError occured
public remote function XmlQueryOperator.addQuery(string queryString) returns Batch | SalesforceError {
    xml | SalesforceError xmlResponse = self.httpClient->createXmlQuery([JOB, self.job.id, BATCH], queryString);
    if (xmlResponse is xml) {
        Batch | SalesforceError batch = getBatch(xmlResponse);
        return batch;
    } else {
        return xmlResponse;
    }
}

# Get XML query operator job information.
#
# + return - Job record if successful else SalesforceError occured
public remote function XmlQueryOperator.getJobInfo() returns Job | SalesforceError {
    xml | SalesforceError xmlResponse = self.httpClient->getXmlRecord([JOB, self.job.id]);
    if (xmlResponse is xml) {
        Job | SalesforceError job = getJob(xmlResponse);
        return job;
    } else {
        return xmlResponse;
    }
}

# Close XML query operator job.
#
# + return - Job record if successful else SalesforceError occured
public remote function XmlQueryOperator.closeJob() returns Job | SalesforceError {
    xml | SalesforceError xmlResponse = self.httpClient->createXmlRecord([JOB, self.job.id], XML_STATE_CLOSED_PAYLOAD);
    if (xmlResponse is xml) {
        Job | SalesforceError job = getJob(xmlResponse);
        return job;
    } else {
        return xmlResponse;
    }
}

# Abort XML query operator job.
#
# + return - Job record if successful else SalesforceError occured
public remote function XmlQueryOperator.abortJob() returns Job | SalesforceError {
    xml | SalesforceError xmlResponse = self.httpClient->createXmlRecord([JOB, self.job.id], XML_STATE_ABORTED_PAYLOAD);
    if (xmlResponse is xml) {
        Job | SalesforceError job = getJob(xmlResponse);
        return job;
    } else {
        return xmlResponse;
    }
}

# Get XML query batch information.
#
# + batchId - batch ID 
# + return - Batch record if successful else SalesforceError occured
public remote function XmlQueryOperator.getBatchInfo(string batchId) returns Batch | SalesforceError {
    xml | SalesforceError xmlResponse = self.httpClient->getXmlRecord([JOB, self.job.id, BATCH, batchId]);
    if (xmlResponse is xml) {
        Batch | SalesforceError batch = getBatch(xmlResponse);
        return batch;
    } else {
        return xmlResponse;
    }
}

# Get information of all batches of XML query operator job.
#
# + return - BatchInfo record if successful else SalesforceError occured
public remote function XmlQueryOperator.getAllBatches() returns BatchInfo | SalesforceError {
    xml | SalesforceError xmlResponse = self.httpClient->getXmlRecord([JOB, self.job.id, BATCH]);
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
# + return - ResultList record if successful else SalesforceError occured
public remote function XmlQueryOperator.getResultList(string batchId) returns ResultList | SalesforceError {
    xml | SalesforceError response = self.httpClient->getXmlRecord([JOB, self.job.id, BATCH, batchId, RESULT]);
    if (response is xml) {
        ResultList | SalesforceError resultList = getResultList(response);
        return resultList;
    } else {
        return response;
    }
}

# Get query results.
#
# + batchId - batch ID
# + resultId - result ID
# + return - Query result in XML format if successful else SalesforceError occured
public remote function XmlQueryOperator.getResult(string batchId, string resultId) returns xml | SalesforceError {
    return self.httpClient->getXmlRecord([JOB, self.job.id, BATCH, batchId, RESULT, resultId]);
}
