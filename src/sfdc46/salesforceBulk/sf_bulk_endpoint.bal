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

# Salesforce bulk API client.
public type SalesforceBulkClient client object {
    SalesforceBaseClient httpBaseClient;
    SalesforceConfiguration salesforceConfiguration;

    public function __init(SalesforceConfiguration sfConfig) {
        self.httpBaseClient = new(sfConfig);
        self.salesforceConfiguration = sfConfig;
    }

    # Create CSV insert operator client.
    # 
    # + objectName - Object operation applies 
    # + return - CSV insert operator client if successful else ConnectorError occured
    public remote function createCsvInsertOperator(string objectName)
        returns @tainted CsvInsertOperator|ConnectorError {
        xml|ConnectorError response =
        self.httpBaseClient->createXmlRecord([JOB], getXmlJobDetails(INSERT, objectName, CSV));
        if (response is xml) {
            JobInfo|ConnectorError job = getJob(response);
            if (job is JobInfo) {
                CsvInsertOperator csvInsertOperator = new(job, self.salesforceConfiguration);
                return csvInsertOperator;
            } else {
                return job;
            }
        } else {
            return response;
        }
    }

    # Create CSV upsert operator client.
    #
    # + objectName - Object operation applies 
    # + externalIdFieldName - Field using as external Id 
    # + return - CSV upsert operator client if successful else ConnectorError occured
    public remote function createCsvUpsertOperator(string objectName, string externalIdFieldName)
    returns @tainted CsvUpsertOperator|ConnectorError {
        xml|ConnectorError response = self.httpBaseClient->createXmlRecord([JOB],
        getXmlJobDetails(UPSERT, objectName, CSV, extIdFieldName = externalIdFieldName));

        if (response is xml) {
            JobInfo|ConnectorError job = getJob(response);
            if (job is JobInfo) {
                CsvUpsertOperator csvUpsertOperator = new(job, self.salesforceConfiguration);
                return csvUpsertOperator;
            } else {
                return job;
            }
        } else {
            return response;
        }
    }

    # Create CSV update operator client.
    #
    # + objectName - Object operation applies
    # + return - CSV update operator client if successful else ConnectorError occured
    public remote function createCsvUpdateOperator(string objectName)
    returns @tainted CsvUpdateOperator|ConnectorError {
        xml|ConnectorError response =
        self.httpBaseClient->createXmlRecord([JOB], getXmlJobDetails(UPDATE, objectName, CSV));

        if (response is xml) {
            JobInfo|ConnectorError job = getJob(response);
            if (job is JobInfo) {
                CsvUpdateOperator csvUpdateOperator = new(job, self.salesforceConfiguration);
                return csvUpdateOperator;
            } else {
                return job;
            }
        } else {
            return response;
        }
    }

    # Create CSV query operator client.
    #
    # + enablePkChunking - PK chunking is enabled or not
    # + objectName - Object operation applies
    # + return - CSV query operator client if successful else ConnectorError occured
    public remote function createCsvQueryOperator(string objectName, 
    boolean enablePkChunking = false) returns @tainted CsvQueryOperator|ConnectorError {
        xml|ConnectorError response = self.httpBaseClient->createXmlRecord([JOB],
        <@untainted> getXmlJobDetails(QUERY, objectName, CSV), enablePkChunking = enablePkChunking);
        if (response is xml) {
            JobInfo|ConnectorError job = getJob(response);
            if (job is JobInfo) {
                CsvQueryOperator csvQueryOperator = new(job, self.salesforceConfiguration);
                return csvQueryOperator;
            } else {
                return job;
            }
        } else {
            return response;
        }
    }

    # Create CSV delete operator client.
    #
    # + objectName - Object operation applies
    # + return - CSV delete operator client if successful else ConnectorError occured
    public remote function createCsvDeleteOperator(string objectName)
    returns @tainted CsvDeleteOperator|ConnectorError {
        xml|ConnectorError response =
        self.httpBaseClient->createXmlRecord([JOB], getXmlJobDetails(DELETE, objectName, CSV));

        if (response is xml) {
            JobInfo|ConnectorError job = getJob(response);
            if (job is JobInfo) {
                CsvDeleteOperator csvDeleteOperator = new(job, self.salesforceConfiguration);
                return csvDeleteOperator;
            } else {
                return job;
            }
        } else {
            return response;
        }
    }

    # Create XML insert operator client.
    #
    # + objectName - Object operation applies 
    # + return - XML insert operator client if successful else ConnectorError occured
    public remote function createXmlInsertOperator(string objectName)
    returns @tainted XmlInsertOperator|ConnectorError {
        xml|ConnectorError response =
        self.httpBaseClient->createXmlRecord([JOB], getXmlJobDetails(INSERT, objectName, XML));
        if (response is xml) {
            JobInfo|ConnectorError job = getJob(response);
            if (job is JobInfo) {
                XmlInsertOperator xmlInsertOperator = new(job, self.salesforceConfiguration);
                return xmlInsertOperator;
            } else {
                return job;
            }
        } else {
            return response;
        }
    }

    # Create XML upsert operator client.
    #
    # + objectName - Object operation applies 
    # + externalIdFieldName - Field using as external Id
    # + return - XML upsert operator client if successful else ConnectorError occured
    public remote function createXmlUpsertOperator(string objectName, string externalIdFieldName)
    returns @tainted XmlUpsertOperator|ConnectorError {
        xml|ConnectorError response = self.httpBaseClient->createXmlRecord([JOB],
        getXmlJobDetails(UPSERT, objectName, XML, extIdFieldName = externalIdFieldName));
        if (response is xml) {
            JobInfo|ConnectorError job = getJob(response);
            if (job is JobInfo) {
                XmlUpsertOperator xmlUpsertOperator = new(job, self.salesforceConfiguration);
                return xmlUpsertOperator;
            } else {
                return job;
            }
        } else {
            return response;
        }
    }

    # Create XML update operator client.
    #
    # + objectName - Object operation applies 
    # + return - XML update operator client if successful else ConnectorError occured
    public remote function createXmlUpdateOperator(string objectName)
    returns @tainted XmlUpdateOperator|ConnectorError {
        xml|ConnectorError response =
        self.httpBaseClient->createXmlRecord([JOB], getXmlJobDetails(UPDATE, objectName, XML));
        if (response is xml) {
            JobInfo|ConnectorError job = getJob(response);
            if (job is JobInfo) {
                XmlUpdateOperator xmlUpdateOperator = new(job, self.salesforceConfiguration);
                return xmlUpdateOperator;
            } else {
                return job;
            }
        } else {
            return response;
        }
    }

    # Create XML query operator client.
    #
    # + enablePkChunking - PK chunking is enabled or not
    # + objectName - Object operation applies 
    # + return - XML query operator client if successful else ConnectorError occured
    public remote function createXmlQueryOperator(string objectName, 
            boolean enablePkChunking = false) returns @tainted XmlQueryOperator|ConnectorError {
        xml|ConnectorError response = self.httpBaseClient->createXmlRecord([JOB],
        <@untainted> getXmlJobDetails(QUERY, objectName, XML), enablePkChunking = enablePkChunking);
        if (response is xml) {
            JobInfo|ConnectorError job = getJob(response);
            if (job is JobInfo) {
                XmlQueryOperator xmlQueryOperator = new(job, self.salesforceConfiguration);
                return xmlQueryOperator;
            } else {
                return job;
            }
        } else {
            return response;
        }
    }

    # Create XML delete operator client.
    #
    # + objectName - Object operation applies 
    # + return - XML delete operator client if successful else ConnectorError occured
    public remote function createXmlDeleteOperator(string objectName)
    returns @tainted XmlDeleteOperator|ConnectorError {
        xml|ConnectorError response =
        self.httpBaseClient->createXmlRecord([JOB], getXmlJobDetails(DELETE, objectName, XML));
        if (response is xml) {
            JobInfo|ConnectorError job = getJob(response);
            if (job is JobInfo) {
                XmlDeleteOperator xmlDeleteOperator = new(job, self.salesforceConfiguration);
                return xmlDeleteOperator;
            } else {
                return job;
            }
        } else {
            return response;
        }
    }

    # Create JSON insert operator client.
    #
    # + objectName - Object operation applies 
    # + return - JSON insert operator client if successful else ConnectorError occured
    public remote function createJsonInsertOperator(string objectName)
    returns @tainted JsonInsertOperator|ConnectorError {
        json|ConnectorError response =
        self.httpBaseClient->createJsonRecord([JOB], getJsonJobDetails(INSERT, objectName));
        if (response is json) {
            JobInfo|ConnectorError job = getJob(response);
            if (job is JobInfo) {
                JsonInsertOperator jsonInsertOperator = new(job, self.salesforceConfiguration);
                return jsonInsertOperator;
            } else {
                return job;
            }
        } else {
            return response;
        }
    }

    # Create XML upsert operator client.
    #
    # + objectName - Object operation applies 
    # + externalIdFieldName - externalIdFieldName Parameter Description 
    # + return - JSON upsert operator client if successful else ConnectorError occured
    public remote function createJsonUpsertOperator(string objectName, string externalIdFieldName)
    returns @tainted JsonUpsertOperator|ConnectorError {
        json|ConnectorError response = self.httpBaseClient->createJsonRecord([JOB],
        getJsonJobDetails(UPSERT, objectName, extIdFieldName = externalIdFieldName));
        if (response is json) {
            JobInfo|ConnectorError job = getJob(response);
            if (job is JobInfo) {
                JsonUpsertOperator jsonUpsertOperator = new(job, self.salesforceConfiguration);
                return jsonUpsertOperator;
            } else {
                return job;
            }
        } else {
            return response;
        }
    }

    # Create XML update operator client.
    #
    # + objectName - Object operation applies 
    # + return - JSON update operator client if successful else ConnectorError occured
    public remote function createJsonUpdateOperator(string objectName)
    returns @tainted JsonUpdateOperator|ConnectorError {
        json|ConnectorError response =
        self.httpBaseClient->createJsonRecord([JOB], getJsonJobDetails(UPDATE, objectName));
        if (response is json) {
            JobInfo|ConnectorError job = getJob(response);
            if (job is JobInfo) {
                JsonUpdateOperator jsonUpdateOperator = new(job, self.salesforceConfiguration);
                return jsonUpdateOperator;
            } else {
                return job;
            }
        } else {
            return response;
        }
    }

    # Create XML query operator client.
    #
    # + enablePkChunking - enablePkChunking Parameter Description 
    # + objectName - Object operation applies 
    # + return - JSON query operator client if successful else ConnectorError occured
    public remote function createJsonQueryOperator(string objectName, 
    boolean enablePkChunking = false) returns @tainted JsonQueryOperator|ConnectorError {
        json|ConnectorError response =
        self.httpBaseClient->createJsonRecord([JOB], <@untainted> getJsonJobDetails(QUERY, objectName), 
        enablePkChunking = enablePkChunking);
        if (response is json) {
            JobInfo|ConnectorError job = getJob(response);
            if (job is JobInfo) {
                JsonQueryOperator jsonQueryOperator = new(job, self.salesforceConfiguration);
                return jsonQueryOperator;
            } else {
                return job;
            }
        } else {
            return response;
        }
    }

    # Create XML delete operator client.
    #
    # + objectName - Object operation applies 
    # + return - JSON delete operator client if successful else ConnectorError occured
    public remote function createJsonDeleteOperator(string objectName)
    returns @tainted JsonDeleteOperator|ConnectorError {
        json|ConnectorError response =
        self.httpBaseClient->createJsonRecord([JOB], getJsonJobDetails(DELETE, objectName));
        if (response is json) {
            JobInfo|ConnectorError job = getJob(response);
            if (job is JobInfo) {
                JsonDeleteOperator jsonDeleteOperator = new(job, self.salesforceConfiguration);
                return jsonDeleteOperator;
            } else {
                return job;
            }
        } else {
            return response;
        }
    }
};
