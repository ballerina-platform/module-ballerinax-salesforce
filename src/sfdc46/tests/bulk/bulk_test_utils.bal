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

import ballerina/log;
import ballerina/test;
import ballerina/lang.'xml as xmllib;

function checkBatchResults(Result[] results) returns boolean {
    foreach Result res in results {
        if (!res.success) {
            log:printError("Failed result, res=" + res.toString(), err = ());
            return false;
        }
    }
    return true;
}

function getDeleteContacts() returns @tainted json {
    json[] deleteContacts = [];

    // Create JSON query operator.
    JsonQueryOperator|ConnectorError jsonQueryOperator = sfBulkClient->createJsonQueryOperator("Contact");
    // Query string
    string queryStr = "SELECT Id, Name FROM Contact WHERE Title='Professor Grade 03'";

    if (jsonQueryOperator is JsonQueryOperator) {
        string batchId = EMPTY_STRING;

        // Create json query batch.
        BatchInfo|ConnectorError batch = jsonQueryOperator->query(queryStr);
        if (batch is BatchInfo) {
            batchId = batch.id;

            // Close job.
            JobInfo|ConnectorError closedJob = jsonQueryOperator->closeJob();
            if (closedJob is JobInfo) {
                if (closedJob.state == "Closed") {

                    // Get the result list.
                    string[]|ConnectorError resultList = jsonQueryOperator->getResultList(batchId, noOfRetries);

                    if (resultList is string[]) {
                        test:assertTrue(resultList.length() > 0, msg = "Getting query result list failed.");

                        foreach string resultId in resultList {

                            // Get query result.
                            json|ConnectorError queryResult = jsonQueryOperator->getResult(batchId, resultId);

                            if (queryResult is json) {
                                json[] queryResArr = <json[]> queryResult;

                                foreach json queryRes in queryResArr {
                                    json|error resId = queryRes.Id;

                                    if (resId is json){
                                        json temp = {
                                            id: resId
                                        }; 
                                        deleteContacts[deleteContacts.length()] = temp;
                                    } else {
                                        test:assertFail(msg = "Failed to get query result ID.");                            
                                    }
                                }
                            } else {
                                test:assertFail(msg = queryResult.detail()?.message.toString());                            
                            }
                        }
                    } else {
                        test:assertFail(msg = resultList.detail()?.message.toString());
                    }
                } else {
                    test:assertFail(msg = "Failed to close the job.");
                }
            } else {
                test:assertFail(msg = closedJob.detail()?.message.toString());
            }    
        } else {
            test:assertFail(msg = batch.detail()?.message.toString());
        }
    } else {
        test:assertFail(msg = jsonQueryOperator.detail()?.message.toString());
    }
    return <json>deleteContacts;
}

function getDeleteContactsAsText() returns @tainted string {
    string deleteContacts = "Id";

    // Create JSON query operator.
    JsonQueryOperator|ConnectorError jsonQueryOperator = sfBulkClient->createJsonQueryOperator("Contact");
    // Query string
    string queryStr = "SELECT Id, Name FROM Contact WHERE Title='Professor Grade 04'";

    if (jsonQueryOperator is JsonQueryOperator) {
        string batchId = EMPTY_STRING;

        // Create json query batch.
        BatchInfo|ConnectorError batch = jsonQueryOperator->query(queryStr);
        if (batch is BatchInfo) {
            batchId = batch.id;

            // Close job.
            JobInfo|ConnectorError closedJob = jsonQueryOperator->closeJob();
            if (closedJob is JobInfo) {
                if (closedJob.state == "Closed") {

                    // Get the result list.
                    string[]|ConnectorError resultList = jsonQueryOperator->getResultList(batchId, noOfRetries);

                    if (resultList is string[]) {
                        test:assertTrue(resultList.length() > 0, msg = "Getting query result list failed.");

                        foreach string resultId in resultList {
                            // Get query result.
                            json|ConnectorError queryResult = jsonQueryOperator->getResult(batchId, resultId);

                            if (queryResult is json) {
                                json[] queryResArr = <json[]> queryResult;

                                foreach json queryRes in queryResArr {
                                    json|error resId = queryRes.Id;

                                    if (resId is json){
                                        deleteContacts = deleteContacts + "\n" + resId.toString();
                                    } else {
                                        test:assertFail(msg = "Failed to get query result ID.");                            
                                    }
                                }
                            } else {
                                test:assertFail(msg = queryResult.detail()?.message.toString());                            
                            }
                        }

                    } else {
                        test:assertFail(msg = resultList.detail()?.message.toString());
                    }
                } else {
                    test:assertFail(msg = "Failed to close the job.");
                }
            } else {
                test:assertFail(msg = closedJob.detail()?.message.toString());
            }    
        } else {
            test:assertFail(msg = batch.detail()?.message.toString());
        }
    } else {
        test:assertFail(msg = jsonQueryOperator.detail()?.message.toString());
    }
    return deleteContacts;
}

function getDeleteContactsAsXml() returns @tainted xml {
    xmllib:Element deleteContacts = <xmllib:Element> xml `<sObjects xmlns="http://www.force.com/2009/06/asyncapi/dataload"/>`;

    // Create JSON query operator.
    XmlQueryOperator|ConnectorError xmlQueryOperator = sfBulkClient->createXmlQueryOperator("Contact");
    // Query string
    string queryStr = "SELECT Name, Id FROM Contact WHERE Title='Professor Grade 05'";

    if (xmlQueryOperator is XmlQueryOperator) {
        string batchId = EMPTY_STRING;

        // Create json query batch.
        BatchInfo|ConnectorError batch = xmlQueryOperator->query(queryStr);
        if (batch is BatchInfo) {
            batchId = batch.id;

            // Close job.
            JobInfo|ConnectorError closedJob = xmlQueryOperator->closeJob();
            if (closedJob is JobInfo) {
                if (closedJob.state == "Closed") {

                    // Get the result list.
                    string[]|ConnectorError resultList = xmlQueryOperator->getResultList(batchId, noOfRetries);

                    if (resultList is string[]) {
                        test:assertTrue(resultList.length() > 0, msg = "Getting query result list failed, "
                            + "resultList=" + resultList.toString());

                        foreach string resultId in resultList {

                            // Get query result.
                            xml|ConnectorError queryResult = xmlQueryOperator->getResult(batchId, resultId);

                            if (queryResult is xml) {
                                xmllib:Element element = <xmllib:Element> queryResult;
                                foreach var queryRes in element.getChildren().elements() {
                                    if (queryRes is xml) {
                                        // Get 0th ID since queryRes has 2 ID elements.
                                        string|error recordId = queryRes[getElementNameWithNamespace("Id")][0]
                                            .toString();

                                        if (recordId is string){
                                            xml rec = xml `<sObject xmlns="http://www.force.com/2009/06/asyncapi/dataload"><Id>${recordId}</Id></sObject>`;
                                            // Set rec as a children for deleteContacts xml.
                                            xml listOfChildren = deleteContacts.getChildren();
                                            listOfChildren = listOfChildren.concat(rec);
                                            deleteContacts.setChildren(listOfChildren);
                                        } else {
                                            test:assertFail(msg = "Failed to get query result ID.");                            
                                        }
                                    } else {
                                        test:assertFail(msg = "Invalid query result, queryRes: " + queryRes);
                                    }
                                }

                            } else {
                                test:assertFail(msg = queryResult.detail()?.message.toString());                            
                            }
                        }
                    } else {
                        test:assertFail(msg = resultList.detail()?.message.toString());
                    }
                } else {
                    test:assertFail(msg = "Failed to close the job.");
                }
            } else {
                test:assertFail(msg = closedJob.detail()?.message.toString());
            }    
        } else {
            test:assertFail(msg = batch.detail()?.message.toString());
        }
    } else {
        test:assertFail(msg = xmlQueryOperator.detail()?.message.toString());
    }
    return deleteContacts;
}

function getContactIdByName(string firstName, string lastName, string title) returns @tainted string {
    string contactId = "";
    string sampleQuery = "SELECT Id FROM Contact WHERE FirstName='" + firstName + "' AND LastName='" + lastName 
        + "' AND Title='" + title + "'";
    json|ConnectorError jsonRes = salesforceClient->getQueryResult(sampleQuery);

    if (jsonRes is json) {
        json|error records = jsonRes.records;
        if (records is json) {
            json[] recordsArr = <json[]> records;
            string id = recordsArr[0].Id.toString();
            contactId = id;
        } else {
            test:assertFail(msg = "Getting contact ID by name failed. err=" + records.toString());            
        }
    } else {
        test:assertFail(msg = "Getting contact ID by name failed. err=" + jsonRes.toString());
    }
    return contactId;
}
