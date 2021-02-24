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
import ballerina/io;
//import ballerina/log;

# The Job object.
public client class BulkJob {
    string jobId;
    JOBTYPE jobDataType;
    OPERATION operation;
    http:Client httpClient;
    SalesforceAuthHandler authHandler;

    public isolated function init(string jobId, JOBTYPE jobDataType, OPERATION operation, http:Client httpClient, SalesforceAuthHandler authHandler) {
        self.jobId = jobId;
        self.jobDataType = jobDataType;
        self.operation = operation;
        self.httpClient = httpClient;
        self.authHandler = authHandler;
    }

    # Add batch to the job.
    #
    # + content - batch content 
    # + return - batch info or error
    remote function addBatch(json|string|xml|io:ReadableByteChannel content) returns @tainted error|BatchInfo {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, self.jobId, BATCH]);
        // https://github.com/ballerina-platform/ballerina-lang/issues/26798
        http:Request req = new;
        http:ClientAuthError|http:Request authorizedReq = self.authHandler.enrich(req);
        if (authorizedReq is http:Request){
            if (self.jobDataType == JSON) {
            if (content is json) {
                authorizedReq.setJsonPayload(content);
            }
            if (content is string) {
                authorizedReq.setTextPayload(content);
            }
            if (content is io:ReadableByteChannel) {
                if (QUERY == self.operation) {
                    string payload = check convertToString(content);
                    authorizedReq.setTextPayload(<@untainted>payload);
                } else {
                    json payload = check convertToJson(content);
                    authorizedReq.setJsonPayload(<@untainted>payload);
                }
            }
            authorizedReq.setHeader(CONTENT_TYPE, APP_JSON);
            var response = self.httpClient->post(path, authorizedReq);
            json|Error batchResponse = checkJsonPayloadAndSetErrors(response);
            if (batchResponse is json) {
                BatchInfo binfo = check batchResponse.cloneWithType(BatchInfo);
                return binfo;
            } else {
                return batchResponse;
            }
            } else if (self.jobDataType == XML) {
                if (content is xml) {
                    authorizedReq.setXmlPayload(content);
                }
                if (content is string) {
                    authorizedReq.setTextPayload(content);
                }
                if (content is io:ReadableByteChannel) {
                    if (QUERY == self.operation) {
                        string payload = check convertToString(content);
                        authorizedReq.setTextPayload(<@untainted>payload);
                    } else {
                        xml payload = check convertToXml(content);
                        authorizedReq.setXmlPayload(<@untainted>payload);
                    }
                }
                authorizedReq.setHeader(CONTENT_TYPE, APP_XML);
                var response = self.httpClient->post(path, authorizedReq);
                xml|Error batchResponse = checkXmlPayloadAndSetErrors(response);
                if (batchResponse is xml) {
                    BatchInfo binfo = check createBatchRecordFromXml(batchResponse);
                    return binfo;
                } else {
                    return batchResponse;
                }
            } else if (self.jobDataType == CSV) {
                if (content is string) {
                    authorizedReq.setTextPayload(content);
                }
                if (content is io:ReadableByteChannel) {
                    string textcontent = check convertToString(content);
                    authorizedReq.setTextPayload(<@untainted>textcontent);
                }
                authorizedReq.setHeader(CONTENT_TYPE, TEXT_CSV);
                var response = self.httpClient->post(path, authorizedReq);
                xml|Error batchResponse = checkXmlPayloadAndSetErrors(response);
                if (batchResponse is xml) {
                    BatchInfo binfo = check createBatchRecordFromXml(batchResponse);
                    return binfo;
                } else {
                    return batchResponse;
                }
            } else {
                return error("Invalid Job Type!");
            }
        }
        else{
            return authorizedReq;
        }
        
        
    }

    # Get information about a batch.
    #
    # + batchId - ID of the batch of which info is required 
    # + return - batch info or error
    remote function getBatchInfo(string batchId) returns @tainted error|BatchInfo {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, self.jobId, BATCH, batchId]);
        http:Request req = new;
        http:ClientAuthError|http:Request authorizedReq = self.authHandler.enrich(req);
        if (authorizedReq is http:Request){
            var response = self.httpClient->get(path, authorizedReq);
            if (JSON == self.jobDataType) {
                json|Error batchResponse = checkJsonPayloadAndSetErrors(response);
                if (batchResponse is json) {
                    BatchInfo binfo = check batchResponse.cloneWithType(BatchInfo);
                    return binfo;
                } else {
                    return batchResponse;
                }
            } else {
                xml|Error batchResponse = checkXmlPayloadAndSetErrors(response);
                if (batchResponse is xml) {
                    BatchInfo binfo = check createBatchRecordFromXml(batchResponse);
                    return binfo;
                } else {
                    return batchResponse;
                }
            }
        }
        else{
            return authorizedReq;
        }
        
    }

    # Get all batches of the job.
    #
    # + return - list of batch infos
    remote function getAllBatches() returns @tainted error|BatchInfo[] {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, self.jobId, BATCH]);
        http:Request req = new;
        http:ClientAuthError|http:Request authorizedReq = self.authHandler.enrich(req);
        if (authorizedReq is http:Request){
            var response = self.httpClient->get(path, authorizedReq);
            BatchInfo[] batchInfoList = [];
            if (JSON == self.jobDataType) {
                json batchResponse = check checkJsonPayloadAndSetErrors(response);
                json batchInfoRes = check batchResponse.batchInfo;
                json[] batchInfoArr =  <json[]>batchInfoRes;
                foreach json batchInfo in batchInfoArr {
                    BatchInfo batch = check batchInfo.cloneWithType(BatchInfo);
                    batchInfoList[batchInfoList.length()] = batch;
                }
            } else {
                xml batchResponse = check checkXmlPayloadAndSetErrors(response);
                foreach var batchInfo in batchResponse/<*> {
                    BatchInfo batch = check createBatchRecordFromXml(batchInfo);
                    batchInfoList[batchInfoList.length()] = batch;
                }
            }
            return batchInfoList;
        }
        else{
            return authorizedReq;
        }
    }

    # Get the request payload of a batch.
    #
    # + batchId - ID of the batch of which the request is required 
    # + return - batch content
    remote function getBatchRequest(string batchId) returns @tainted error|json|xml|string {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, self.jobId, BATCH, batchId, REQUEST]);
        http:Request req = new;
        http:ClientAuthError|http:Request authorizedReq = self.authHandler.enrich(req);
        if (authorizedReq is http:Request){
            var response = self.httpClient->get(path, authorizedReq);
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
        else{
            return authorizedReq;
        }
        
    }

    # Get result of the records processed in a batch.
    #
    # + batchId - batch ID
    # + return - result list
    remote function getBatchResult(string batchId) returns @tainted error|json|xml|string|Result[] {
        string path = prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, self.jobId, BATCH, batchId, RESULT]);
        Result[] results = [];
        http:Request req = new;
        http:ClientAuthError|http:Request authorizedReq = self.authHandler.enrich(req);
        if (authorizedReq is http:Request){
            var response = self.httpClient->get(path, authorizedReq);
            match self.jobDataType {
                JSON => {
                    json resultResponse = check checkJsonPayloadAndSetErrors(response);
                    if (QUERY == self.operation) {
                        return getJsonQueryResult(<@untainted>resultResponse, path, <@untainted>self.httpClient, <@untainted> self.authHandler);
                    }
                    return createBatchResultRecordFromJson(resultResponse);
                }
                XML => {
                    xml resultResponse = check checkXmlPayloadAndSetErrors(response);
                    if (QUERY == self.operation) {
                        return getXmlQueryResult(<@untainted>resultResponse, path, <@untainted>self.httpClient, <@untainted> self.authHandler);
                    }
                    return createBatchResultRecordFromXml(resultResponse);
                }
                CSV => {
                    if (QUERY == self.operation) {
                        xml resultResponse = check checkXmlPayloadAndSetErrors(response);
                        return getCsvQueryResult(<@untainted>resultResponse, path, <@untainted>self.httpClient, <@untainted> self.authHandler);
                    }
                    string resultResponse = check checkTextPayloadAndSetErrors(response);
                    return createBatchResultRecordFromCsv(resultResponse);
                }
                _ => {
                    return error("Invalid Job Type!");
                }
            }
        }
        else{
            return authorizedReq;
        }
    }
}
