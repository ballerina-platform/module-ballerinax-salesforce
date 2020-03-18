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

# CSV delete operator client.
public type CsvDeleteOperator client object {
    *BulkOperator;

    public function __init(JobInfo job, SalesforceConfiguration salesforceConfig) {
        self.job = job;
        self.httpBaseClient = new(salesforceConfig);
    }

    # Create CSV delete batch.
    #
    # + csvContent - delete data with IDs in CSV format
    # + return - BatchInfo record if successful else ConnectorError occured
    public remote function delete(string csvContent) returns @tainted BatchInfo|ConnectorError {
        xml xmlResponse = check self.httpBaseClient->createCsvRecord([JOB, self.job.id, BATCH], csvContent);
        return getBatch(xmlResponse);
    }

    # Get CSV delete operator job information.
    #
    # + return - JobInfo record if successful else ConnectorError occured
    public remote function getJobInfo() returns @tainted JobInfo|ConnectorError {
        xml xmlResponse = check self.httpBaseClient->getXmlRecord([JOB, self.job.id]);
        return getJob(xmlResponse);
    }

    # Close CSV delete operator job.
    #
    # + return - JobInfo record if successful else ConnectorError occured
    public remote function closeJob() returns @tainted JobInfo|ConnectorError {
        xml xmlResponse = check self.httpBaseClient->createXmlRecord([JOB, self.job.id], XML_STATE_CLOSED_PAYLOAD);
        return getJob(xmlResponse);
    }

    # Abort CSV delete operator job.
    #
    # + return - JobInfo record if successful else ConnectorError occured
    public remote function abortJob() returns @tainted JobInfo|ConnectorError {
        xml xmlResponse = check self.httpBaseClient->createXmlRecord([JOB, self.job.id], XML_STATE_ABORTED_PAYLOAD);
        return getJob(xmlResponse);
    }

    # Get CSV delete batch information.
    #
    # + batchId - batch ID 
    # + return - BatchInfo record if successful else ConnectorError occured
    public remote function getBatchInfo(string batchId) returns @tainted BatchInfo|ConnectorError {
        xml xmlResponse = check self.httpBaseClient->getXmlRecord([JOB, self.job.id, BATCH, batchId]);
        return getBatch(xmlResponse);
    }

    # Get information of all batches of CSV delete operator job.
    #
    # + return - BatchInfo record if successful else ConnectorError occured
    public remote function getAllBatches() returns @tainted BatchInfo[]|ConnectorError {
        xml xmlResponse = check self.httpBaseClient->getXmlRecord([JOB, self.job.id, BATCH]);
        return getBatchInfoList(xmlResponse);
    }

    # Retrieve the CSV batch request.
    #
    # + batchId - batch ID
    # + return - CSV Batch request if successful else ConnectorError occured
    public remote function getBatchRequest(string batchId) returns @tainted string|ConnectorError {
        return self.httpBaseClient->getCsvRecord([JOB, self.job.id, BATCH, batchId, REQUEST]);
    }

    # Get the results of the batch.
    #
    # + batchId - batch ID
    # + numberOfTries - number of times checking the batch state
    # + waitTime - time between two tries in ms
    # + return - Results array if successful else ConnectorError occured
    public remote function getResult(string batchId, int numberOfTries = 1, int waitTime = 3000) 
        returns @tainted Result[]|ConnectorError {
        return checkBatchStateAndGetResults(getBatchPointer, getResultsPointer, self, batchId, numberOfTries, waitTime);
    }
};
