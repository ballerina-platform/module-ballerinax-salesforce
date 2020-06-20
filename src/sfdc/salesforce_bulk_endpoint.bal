//
// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;
import ballerina/oauth2;
import ballerina/io;

# The Salesforce Bulk Client object.
# + httpClient - OAuth2 client endpoint
# + salesforceConfiguration - Salesforce Connector configuration
public type BulkClient client object {
    http:Client httpClient;
    SalesforceConfiguration salesforceConfiguration;

    # The Salesforce Bulk client initialization function.
    # + salesforceConfig - the Salesforce Connector configuration
    public function init(SalesforceConfiguration salesforceConfig) {
        self.salesforceConfiguration = salesforceConfig;
        // Create the OAuth2 provider.
        oauth2:OutboundOAuth2Provider oauth2Provider = new(salesforceConfig.clientConfig);
        // Create the bearer auth handler using the created provider.
        SalesforceBulkAuthHandler bearerHandler = new(oauth2Provider);

        http:ClientSecureSocket? socketConfig = salesforceConfig?.secureSocketConfig;
        
        // Create an HTTP client.
        if (socketConfig is http:ClientSecureSocket) {
            self.httpClient = new(salesforceConfig.baseUrl, {
                secureSocket: socketConfig,
                auth: {
                    authHandler: bearerHandler
                }
            });
        } else {
            self.httpClient = new(salesforceConfig.baseUrl, {
                auth: {
                    authHandler: bearerHandler
                }
            });
        }
    }

    # Create a bulk job.
    #
    # + operation - type of operation like insert, delete, etc.
    # + sobj - kind of sobject 
    # + contentType - content type of the job 
    # + extIdFieldName - field name of the external ID incase of an Upsert operation
    # + return - returns job object or error
    public remote function creatJob(OPERATION operation, string sobj, JOBTYPE contentType, string extIdFieldName = "") returns @tainted error|BulkJob {
        json jobPayload = {
            "operation" : operation,
            "object" : sobj,
            "contentType" : contentType
        };
        if (UPSERT == operation) {
            if (extIdFieldName.length() > 0) {
                json extField = {
                    "externalIdFieldName" : extIdFieldName
                };
                jobPayload = check jobPayload.mergeJson(extField);
            } else {
                return error("External ID Field Name Required for UPSERT Operation!");
            }
        }        
        http:Request req = new;
        req.setJsonPayload(jobPayload);
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB]);
        var response = self.httpClient->post(path, req);
        json|Error jobResponse = checkJsonPayloadAndSetErrors(response);
        if (jobResponse is json) {
            BulkJob bulkJob = new(jobResponse.id.toString(), contentType, operation, self.httpClient);
            return bulkJob;
        } else {
            return jobResponse;
        }
    }

    # Get information about a job.
    #
    # + bulkJob - job object of which the info is required 
    # + return - job information record or error
    public remote function getJobInfo(BulkJob bulkJob) returns @tainted error|JobInfo {
        string jobId = bulkJob.jobId;
        JOBTYPE jobDataType = bulkJob.jobDataType;
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, jobId]);
        http:Request req = new;
        var response = self.httpClient->get(path, req);
        if (JSON == jobDataType) {
            json|Error jobResponse = checkJsonPayloadAndSetErrors(response);
            if (jobResponse is json){            
                JobInfo jobInfo = check jobResponse.cloneWithType(JobInfo);
                return jobInfo;
            } else {
                return jobResponse;
            }
        } else {
            xml|Error jobResponse = checkXmlPayloadAndSetErrors(response);
            if (jobResponse is xml){            
                JobInfo jobInfo = check createJobRecordFromXml(jobResponse);
                return jobInfo;
            } else {
                return jobResponse;
            }
        }
        
    }

    # Close a job.
    #
    # + bulkJob - job to be closed 
    # + return - job info after the state change of the job
    public remote function closeJob(BulkJob bulkJob) returns @tainted error|JobInfo {
        string jobId = bulkJob.jobId;
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, jobId]);
        http:Request req = new;
        req.setJsonPayload(JSON_STATE_CLOSED_PAYLOAD);
        var response = self.httpClient->post(path, req);
        json|Error jobResponse = checkJsonPayloadAndSetErrors(response);
        if (jobResponse is json){
            JobInfo jobInfo = check jobResponse.cloneWithType(JobInfo);
            return jobInfo;
        } else {
            return jobResponse;
        }
    }

    # Abort a job.
    #
    # + bulkJob - job to be aborted 
    # + return - job info after the state change of the job
    public remote function abortJob(BulkJob bulkJob) returns @tainted error|JobInfo {
        string jobId = bulkJob.jobId;
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, jobId]);
        http:Request req = new;
        req.setJsonPayload(JSON_STATE_CLOSED_PAYLOAD);
        var response = self.httpClient->post(path, req);
        json|Error jobResponse = checkJsonPayloadAndSetErrors(response);
        if (jobResponse is json){
            JobInfo jobInfo = check jobResponse.cloneWithType(JobInfo);
            return jobInfo;
        } else {
            return jobResponse;
        }
    }
};


# The Job object.
public type BulkJob client object {
    string jobId;
    JOBTYPE jobDataType;
    OPERATION operation;
    http:Client httpClient;

    public function init(string jobId, JOBTYPE jobDataType, OPERATION operation, http:Client httpClient) {
        self.jobId = jobId;
        self.jobDataType = jobDataType;
        self.operation = operation;
        self.httpClient = httpClient;
    }

    # Add batch to the job.
    #
    # + content - batch content 
    # + return - batch info or error
    public remote function addBatch(json|string|xml|io:ReadableByteChannel content) returns @tainted error|BatchInfo{
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, self.jobId, BATCH]);
        http:Request req = new;
        match self.jobDataType {
            JSON => {
                if (content is json) {
                    req.setJsonPayload(content);
                }
                if (content is string) {
                    req.setTextPayload(content);
                }                
                if (content is io:ReadableByteChannel) {
                    if (QUERY == self.operation) {
                        string payload = check convertToString(content);
                        req.setTextPayload(<@untainted>  payload);
                    } else {
                        json payload = check convertToJson(content);
                        req.setJsonPayload(<@untainted>  payload);
                    }
                }
                req.setHeader(CONTENT_TYPE, APP_JSON);
                var response = self.httpClient->post(path, req);
                json|Error batchResponse = checkJsonPayloadAndSetErrors(response);
                if (batchResponse is json){
                    BatchInfo binfo = check batchResponse.cloneWithType(BatchInfo);
                    return binfo;
                } else {
                    return batchResponse;
                } 
            }
            XML => {
                if (content is xml) {
                    req.setXmlPayload(content);
                }
                if (content is string) {
                    req.setTextPayload(content);
                }
                if (content is io:ReadableByteChannel) {
                    if (QUERY == self.operation) {
                        string payload = check convertToString(content);
                        req.setTextPayload(<@untainted>  payload);
                    } else {
                        xml payload = check convertToXml(content);
                        req.setXmlPayload(<@untainted>  payload);
                    }
                } 
                req.setHeader(CONTENT_TYPE, APP_XML);
                var response = self.httpClient->post(path, req);
                xml|Error batchResponse = checkXmlPayloadAndSetErrors(response);
                if (batchResponse is xml){
                    BatchInfo binfo = check createBatchRecordFromXml(batchResponse);
                    return binfo;
                } else {
                    return batchResponse;
                }
            }
            CSV => {
                if (content is string) {
                    req.setTextPayload(content);
                }                
                if (content is io:ReadableByteChannel) {
                    string textcontent = check convertToString(content);
                    req.setTextPayload(<@untainted> textcontent);
                }
                req.setHeader(CONTENT_TYPE, TEXT_CSV);
                var response = self.httpClient->post(path, req);
                xml|Error batchResponse = checkXmlPayloadAndSetErrors(response);
                if (batchResponse is xml){
                    BatchInfo binfo = check createBatchRecordFromXml(batchResponse);
                    return binfo;
                } else {
                    return batchResponse;
                }
            }
            _ => {
                return error("Invalid Job Type!");
            }
        }
    }

    # Get information about a batch.
    #
    # + batchId - ID of the batch of which info is required 
    # + return - batch info or error
    public remote function getBatchInfo(string batchId) returns @tainted error|BatchInfo {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, self.jobId, BATCH, batchId]);
        http:Request req = new;
        var response = self.httpClient->get(path, req);
        if (JSON == self.jobDataType) {
            json|Error batchResponse = checkJsonPayloadAndSetErrors(response);
            if (batchResponse is json){
                BatchInfo binfo = check batchResponse.cloneWithType(BatchInfo);
                return binfo;
            } else {
                return batchResponse;
            }
        } else {
            xml|Error batchResponse = checkXmlPayloadAndSetErrors(response);
            if (batchResponse is xml){
                BatchInfo binfo = check createBatchRecordFromXml(batchResponse);
                return binfo;
            } else {
                return batchResponse;
            }
        }
        
    }

    # Get all batches of the job.
    #
    # + return - list of batch infos
    public remote function getAllBatches() returns @tainted error|BatchInfo[] {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, self.jobId, BATCH]);
        http:Request req = new;
        var response = self.httpClient->get(path, req);
        BatchInfo[] batchInfoList = [];
        if (JSON == self.jobDataType) {
            json batchResponse = check checkJsonPayloadAndSetErrors(response);
            json[] batchInfoArr = <json[]>batchResponse.batchInfo;
            foreach json batchInfo in batchInfoArr {
                BatchInfo batch = check batchInfo.cloneWithType(BatchInfo);
                batchInfoList[batchInfoList.length()] = batch;
            }
        } else {
            xml batchResponse = check checkXmlPayloadAndSetErrors(response);
            foreach var batchInfo in batchResponse/<*> {
                if (batchInfo is xml) {
                    BatchInfo batch = check createBatchRecordFromXml(batchInfo);
                    batchInfoList[batchInfoList.length()] = batch;
                }
            }
        }        
        return batchInfoList;
    }

    # Get the request payload of a batch.
    #
    # + batchId - ID of the batch of which the request is required 
    # + return - batch content
    public remote function getBatchRequest(string batchId) returns @tainted error|json|xml|string{
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, self.jobId, BATCH, batchId, REQUEST]);
        http:Request req = new;
        var response = self.httpClient->get(path, req);
        if (QUERY == self.operation) {
            return getQueryRequest(response, self.jobDataType);
        } else {
            match self.jobDataType {
                JSON => {
                    return checkJsonPayloadAndSetErrors(response);
                }
                XML => {
                    return checkXmlPayloadAndSetErrors(response);
                }
                CSV => {
                    return checkTextPayloadAndSetErrors(response);
                }
                _ => {
                    return error("Invalid Job Type!");
                }
            }
        }       
    }

    # Get result of the records processed in a batch.
    #
    # + batchId - batch ID
    # + return - result list
    public remote function getBatchResult(string batchId) returns @tainted error|json|xml|string|Result[]{
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, self.jobId, BATCH, batchId, RESULT]);
        Result [] results = [];
        http:Request req = new;
        var response = self.httpClient->get(path, req);
        
        match self.jobDataType {
            JSON => {
                json resultResponse = check checkJsonPayloadAndSetErrors(response);
                if (QUERY == self.operation) {
                    return getJsonQueryResult(<@untainted>resultResponse, path, <@untainted>self.httpClient);
                }
                return createBatchResultRecordFromJson(resultResponse);
            }
            XML => {
                xml resultResponse = check checkXmlPayloadAndSetErrors(response);
                if (QUERY == self.operation) {
                    return getXmlQueryResult(<@untainted>resultResponse, path, <@untainted>self.httpClient);
                }
                return createBatchResultRecordFromXml(resultResponse);
            }
            CSV => {
                if (QUERY == self.operation) {
                    xml resultResponse = check checkXmlPayloadAndSetErrors(response);
                    return getCsvQueryResult(<@untainted>resultResponse, path, <@untainted>self.httpClient);
                }
                string resultResponse = check checkTextPayloadAndSetErrors(response);
                return createBatchResultRecordFromCsv(resultResponse);
            }
            _ => {
                return error("Invalid Job Type!");
            }
        }
    }
};
