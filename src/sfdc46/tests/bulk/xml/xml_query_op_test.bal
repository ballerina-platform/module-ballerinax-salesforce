// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

@test:Config {
    dependsOn: ["testXmlInsertOperator"]
}
function testXmlQueryOperator() {
    log:printInfo("salesforceBulkClient -> XmlQueryOperator");
    
    // Create JSON insert operator.
    XmlQueryOperator|SalesforceError xmlQueryOperator = sfBulkClient->createXmlQueryOperator("Contact");
    // Query string
    string queryStr = "SELECT Id, Name FROM Contact WHERE Title='Professor Grade 05'";

    if (xmlQueryOperator is XmlQueryOperator) {
        string batchId = EMPTY_STRING;

        // Create json query batch.
        Batch|SalesforceError batch = xmlQueryOperator->addQuery(queryStr);
        if (batch is Batch) {
            test:assertTrue(batch.id.length() > 0, msg = "Creating query batch failed.");
            batchId = batch.id;
        } else {
            test:assertFail(msg = batch.message);
        }

        // Get job information.
        Job|SalesforceError jobInfo = xmlQueryOperator->getJobInfo();
        if (jobInfo is Job) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = jobInfo.message);
        }

        // Close job.
        Job|SalesforceError closedJob = xmlQueryOperator->closeJob();
        if (closedJob is Job) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.message);
        }

        // Abort job.
        Job|SalesforceError abortedJob = xmlQueryOperator->abortJob();
        if (abortedJob is Job) {
            test:assertTrue(abortedJob.state == "Aborted", msg = "Aborting job failed.");
        } else {
            test:assertFail(msg = abortedJob.message);
        }

        // Get batch information.
        Batch|SalesforceError batchInfo = xmlQueryOperator->getBatchInfo(batchId);
        if (batchInfo is Batch) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.message);
        }

        // Get informations of all batches of this job.
        BatchInfo|SalesforceError allBatchInfo = xmlQueryOperator->getAllBatches();
        if (allBatchInfo is BatchInfo) {
            test:assertTrue(allBatchInfo.batchInfoList.length() == 1, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = allBatchInfo.message);
        }

        // Get the result list.
        ResultList|SalesforceError resultList = getXmlQueryResultList(xmlQueryOperator, batchId, 5);

        if (resultList is ResultList) {
            test:assertTrue(resultList.result.length() > 0, msg = "Getting query result list failed, resultList=" 
                + resultList.toString());

            // Get results.
            xml|SalesforceError result = xmlQueryOperator->getResult(batchId, resultList.result[0]);

            if (result is xml) {
                xml records = result[getElementNameWithNamespace("records")];
                test:assertTrue(records.*.elements().length() > 0, msg = "Getting query result failed.");
            } else {
                test:assertFail(msg = result.message);
            }
        } else {
            test:assertFail(msg = resultList.message);
        }
    } else {
        test:assertFail(msg = xmlQueryOperator.message);
    }
}

function getXmlQueryResultList(@tainted XmlQueryOperator xmlQueryOperator, string batchId, int numberOfTries) 
    returns @tainted ResultList|SalesforceError {
    int counter = 0;
    while (counter < numberOfTries) {
        ResultList|SalesforceError queryResultList = xmlQueryOperator->getResultList(batchId);
        if (queryResultList is ResultList) {
            string[]|error results = queryResultList.result;
            if (results is string[] && results.length() > 0) {
                return queryResultList;
            }
        } 
        runtime:sleep(3000); // Sleep 3s.
        counter = counter + 1;
    }
    return xmlQueryOperator->getResultList(batchId);
}
