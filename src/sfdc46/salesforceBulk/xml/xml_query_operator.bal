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
    *BulkOperator;

    public function __init(JobInfo job, SalesforceConfiguration salesforceConfig) {
        self.job = job;
        self.httpBaseClient = new(salesforceConfig);
    }

    # Create XML query batch.
    #
    # + queryString - SOQL query want to perform
    # + return - BatchInfo record if successful else ConnectorError occured
    public remote function query(string queryString) returns @tainted BatchInfo|ConnectorError {
        xml xmlResponse = check self.httpBaseClient->createXmlQuery([JOB, self.job.id, BATCH], queryString);
        return getBatch(xmlResponse);
    }

    # Get XML query operator job information.
    #
    # + return - JobInfo record if successful else ConnectorError occured
    public remote function getJobInfo() returns @tainted JobInfo|ConnectorError {
        xml xmlResponse = check self.httpBaseClient->getXmlRecord([JOB, self.job.id]);
        return getJob(xmlResponse);
    }

    # Close XML query operator job.
    #
    # + return - JobInfo record if successful else ConnectorError occured
    public remote function closeJob() returns @tainted JobInfo|ConnectorError {
        xml xmlResponse = check self.httpBaseClient->createXmlRecord([JOB, self.job.id], XML_STATE_CLOSED_PAYLOAD);
        return getJob(xmlResponse);
    }

    # Abort XML query operator job.
    #
    # + return - JobInfo record if successful else ConnectorError occured
    public remote function abortJob() returns @tainted JobInfo|ConnectorError {
        xml xmlResponse = check self.httpBaseClient->createXmlRecord([JOB, self.job.id], XML_STATE_ABORTED_PAYLOAD);
        return getJob(xmlResponse);
    }

    # Get XML query batch information.
    #
    # + batchId - batch ID 
    # + return - BatchInfo record if successful else ConnectorError occured
    public remote function getBatchInfo(string batchId) returns @tainted BatchInfo|ConnectorError {
        xml xmlResponse = check self.httpBaseClient->getXmlRecord([JOB, self.job.id, BATCH, batchId]);
        return getBatch(xmlResponse);
    }

    # Get information of all batches of XML query operator job.
    #
    # + return - BatchInfo record if successful else ConnectorError occured
    public remote function getAllBatches() returns @tainted BatchInfo[]|ConnectorError {
        xml xmlResponse = check self.httpBaseClient->getXmlRecord([JOB, self.job.id, BATCH]);
        return getBatchInfoList(xmlResponse);
    }

    # Get result IDs as a list.
    #
    # + batchId - batch ID
    # + numberOfTries - number of times checking the batch state
    # + waitTime - time between two tries in ms
    # + return - ResultList record if successful else ConnectorError occured
    public remote function getResultList(string batchId, int numberOfTries = 1, int waitTime = 3000) 
        returns @tainted string[]|ConnectorError {
        return checkBatchStateAndGetResultList(getBatchPointer, getResultListPointer, self, batchId, numberOfTries, 
            waitTime);        
    }

    # Get query results.
    #
    # + batchId - batch ID
    # + resultId - result ID
    # + return - Query result in XML format if successful else ConnectorError occured
    public remote function getResult(string batchId, string resultId) returns @tainted xml|ConnectorError {
        return self.httpBaseClient->getXmlRecord([JOB, self.job.id, BATCH, batchId, RESULT, resultId]);
    }
};
