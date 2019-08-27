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
    # + return - CSV insert operator client if successful else SalesforceError occured
    public remote function createCsvInsertOperator(string objectName)
    returns @tainted CsvInsertOperator | SalesforceError {
        xml | SalesforceError response =
        self.httpBaseClient->createXmlRecord([JOB], getXmlJobDetails(INSERT, objectName, CSV));
        if (response is xml) {
            Job | SalesforceError job = getJob(response);
            if (job is Job) {
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
    # + return - CSV upsert operator client if successful else SalesforceError occured
    public remote function createCsvUpsertOperator(string objectName, string externalIdFieldName)
    returns @tainted CsvUpsertOperator | SalesforceError {
        xml | SalesforceError response = self.httpBaseClient->createXmlRecord([JOB], 
        getXmlJobDetails(UPSERT, objectName, CSV, extIdFieldName = externalIdFieldName));

        if (response is xml) {
            Job | SalesforceError job = getJob(response);
            if (job is Job) {
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
    # + return - CSV update operator client if successful else SalesforceError occured
    public remote function createCsvUpdateOperator(string objectName)
    returns @tainted CsvUpdateOperator | SalesforceError {
        xml | SalesforceError response = 
        self.httpBaseClient->createXmlRecord([JOB], getXmlJobDetails(UPDATE, objectName, CSV));

        if (response is xml) {
            Job | SalesforceError job = getJob(response);
            if (job is Job) {
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
    # + return - CSV query operator client if successful else SalesforceError occured
    public remote function createCsvQueryOperator(string objectName, 
    boolean enablePkChunking = false) returns @tainted CsvQueryOperator | SalesforceError {
        xml | SalesforceError response = self.httpBaseClient->createXmlRecord([JOB], 
        <@untainted> getXmlJobDetails(QUERY, objectName, CSV), enablePkChunking = enablePkChunking);
        if (response is xml) {
            Job | SalesforceError job = getJob(response);
            if (job is Job) {
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
    # + return - CSV delete operator client if successful else SalesforceError occured
    public remote function createCsvDeleteOperator(string objectName)
    returns @tainted CsvDeleteOperator | SalesforceError {
        xml | SalesforceError response = 
        self.httpBaseClient->createXmlRecord([JOB], getXmlJobDetails(DELETE, objectName, CSV));

        if (response is xml) {
            Job | SalesforceError job = getJob(response);
            if (job is Job) {
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
    # + return - XML insert operator client if successful else SalesforceError occured
    public remote function createXmlInsertOperator(string objectName)
    returns @tainted XmlInsertOperator | SalesforceError {
        xml | SalesforceError response = 
        self.httpBaseClient->createXmlRecord([JOB], getXmlJobDetails(INSERT, objectName, XML));
        if (response is xml) {
            Job | SalesforceError job = getJob(response);
            if (job is Job) {
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
    # + return - XML upsert operator client if successful else SalesforceError occured
    public remote function createXmlUpsertOperator(string objectName, string externalIdFieldName)
    returns @tainted XmlUpsertOperator | SalesforceError {
        xml | SalesforceError response = self.httpBaseClient->createXmlRecord([JOB], 
        getXmlJobDetails(UPSERT, objectName, XML, extIdFieldName = externalIdFieldName));
        if (response is xml) {
            Job | SalesforceError job = getJob(response);
            if (job is Job) {
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
    # + return - XML update operator client if successful else SalesforceError occured
    public remote function createXmlUpdateOperator(string objectName)
    returns @tainted XmlUpdateOperator | SalesforceError {
        xml | SalesforceError response = 
        self.httpBaseClient->createXmlRecord([JOB], getXmlJobDetails(UPDATE, objectName, XML));
        if (response is xml) {
            Job | SalesforceError job = getJob(response);
            if (job is Job) {
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
    # + return - XML query operator client if successful else SalesforceError occured
    public remote function createXmlQueryOperator(string objectName, 
            boolean enablePkChunking = false) returns @tainted XmlQueryOperator | SalesforceError {
        xml | SalesforceError response = self.httpBaseClient->createXmlRecord([JOB], 
        <@untainted> getXmlJobDetails(QUERY, objectName, XML), enablePkChunking = enablePkChunking);
        if (response is xml) {
            Job | SalesforceError job = getJob(response);
            if (job is Job) {
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
    # + return - XML delete operator client if successful else SalesforceError occured
    public remote function createXmlDeleteOperator(string objectName)
    returns @tainted XmlDeleteOperator | SalesforceError {
        xml | SalesforceError response = 
        self.httpBaseClient->createXmlRecord([JOB], getXmlJobDetails(DELETE, objectName, XML));
        if (response is xml) {
            Job | SalesforceError job = getJob(response);
            if (job is Job) {
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
    # + return - JSON insert operator client if successful else SalesforceError occured
    public remote function createJsonInsertOperator(string objectName)
    returns @tainted JsonInsertOperator | SalesforceError {
        json | SalesforceError response = 
        self.httpBaseClient->createJsonRecord([JOB], getJsonJobDetails(INSERT, objectName));
        if (response is json) {
            Job | SalesforceError job = getJob(response);
            if (job is Job) {
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
    # + return - JSON upsert operator client if successful else SalesforceError occured
    public remote function createJsonUpsertOperator(string objectName, string externalIdFieldName)
    returns @tainted JsonUpsertOperator | SalesforceError {
        json | SalesforceError response = self.httpBaseClient->createJsonRecord([JOB], 
        getJsonJobDetails(UPSERT, objectName, extIdFieldName = externalIdFieldName));
        if (response is json) {
            Job | SalesforceError job = getJob(response);
            if (job is Job) {
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
    # + return - JSON update operator client if successful else SalesforceError occured
    public remote function createJsonUpdateOperator(string objectName)
    returns @tainted JsonUpdateOperator | SalesforceError {
        json | SalesforceError response = 
        self.httpBaseClient->createJsonRecord([JOB], getJsonJobDetails(UPDATE, objectName));
        if (response is json) {
            Job | SalesforceError job = getJob(response);
            if (job is Job) {
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
    # + return - JSON query operator client if successful else SalesforceError occured
    public remote function createJsonQueryOperator(string objectName, 
    boolean enablePkChunking = false) returns @tainted JsonQueryOperator | SalesforceError {
        json | SalesforceError response = 
        self.httpBaseClient->createJsonRecord([JOB], <@untainted> getJsonJobDetails(QUERY, objectName), 
        enablePkChunking = enablePkChunking);
        if (response is json) {
            Job | SalesforceError job = getJob(response);
            if (job is Job) {
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
    # + return - JSON delete operator client if successful else SalesforceError occured
    public remote function createJsonDeleteOperator(string objectName)
    returns @tainted JsonDeleteOperator | SalesforceError {
        json | SalesforceError response = 
        self.httpBaseClient->createJsonRecord([JOB], getJsonJobDetails(DELETE, objectName));
        if (response is json) {
            Job | SalesforceError job = getJob(response);
            if (job is Job) {
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
