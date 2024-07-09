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

import ballerina/http;
import ballerina/io;
import ballerinax/'client.config;
import ballerinax/salesforce.utils;

# Ballerina Salesforce connector provides the capability to access Salesforce Bulk API.
# This connector lets you to perform bulk data operations for CSV, JSON, and XML data types.
#
# + salesforceClient - OAuth2 client endpoint
# + clientHandler - http:ClientOAuth2Handler class instance 
# + clientConfig - Configurations required to initialize the `Client`
public isolated client class Client {
    private final http:Client salesforceClient;
    private final http:OAuth2RefreshTokenGrantConfig|http:BearerTokenConfig clientConfig;
    private final http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler clientHandler;

    # Initializes the connector. During initialization you can pass either http:BearerTokenConfig if you have a bearer
    # token or http:OAuth2RefreshTokenGrantConfig if you have Oauth tokens.
    # Create a Salesforce account and obtain tokens following 
    # [this guide](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm). 
    #
    # + salesforceConfig - Salesforce Connector configuration
    # + return - An error on failure of initialization or else `()`
    public isolated function init(ConnectionConfig config) returns error? {
        http:ClientConfiguration httpClientConfig = check config:constructHTTPClientConfig(config);
        http:OAuth2RefreshTokenGrantConfig|http:BearerTokenConfig auth = let var authConfig = config.auth in 
                (authConfig is http:BearerTokenConfig ?  authConfig : {...authConfig});
        self.clientConfig = auth.cloneReadOnly();

        http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler|error httpHandlerResult;
        if auth is http:OAuth2RefreshTokenGrantConfig {
            httpHandlerResult = trap new http:ClientOAuth2Handler(auth);
        } else {
            httpHandlerResult = trap new http:ClientBearerTokenAuthHandler(auth);
        }

        if httpHandlerResult is http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler {
            self.clientHandler = httpHandlerResult;
        } else {
            return error(INVALID_CLIENT_CONFIG);
        }

        http:Client|http:ClientError|error httpClientResult;
        httpClientResult = trap new (config.baseUrl, httpClientConfig);

        if httpClientResult is http:Client {
            self.salesforceClient = httpClientResult;
        } else {
            return error(INVALID_CLIENT_CONFIG);
        }
    }

    // ******************************************* Bulk Operations *****************************************************
    # Creates a bulk job.
    #
    # + operation - Type of operation like insert, delete, etc.
    # + sobj - Type of sobject
    # + contentType - Content type of the job
    # + extIdFieldName - Field name of the external ID incase of an Upsert operation
    # + return - returns `BulkJob` record or `error`
    isolated remote function createJob(Operation operation, string sobj, JobType contentType, string extIdFieldName = "")
                                        returns error|BulkJob {
        json jobPayload = {
            "operation": operation,
            "object": sobj,
            "contentType": contentType
        };
        if UPSERT == operation {
            if extIdFieldName.length() > 0 {
                json extField = {"externalIdFieldName": extIdFieldName};
                jobPayload = check jobPayload.mergeJson(extField);
            } else {
                return error("External ID Field Name Required for UPSERT Operation!");
            }
        }
        map<string> headerMap = check getBulkApiHeaders(self.clientHandler);
        string path = utils:prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB]);
        http:Response response = check self.salesforceClient->post(path, jobPayload, headers = headerMap);
        json jobResponse = check checkJsonPayloadAndSetErrors(response);
        json jobResponseId = check jobResponse.id;
        BulkJob bulkJob = {
            jobId: jobResponseId.toString(),
            jobDataType: contentType,
            operation: operation
        };
        return bulkJob;
    }

    # Gets information about a job.
    #
    # + bulkJob - `BulkJob` record of which the info is required
    # + return - `JobInfo` record or `error`
    isolated remote function getJobInfo(BulkJob bulkJob)returns error|JobInfo {
        string jobId = bulkJob.jobId;
        JobType jobDataType = bulkJob.jobDataType;
        string path = utils:prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, jobId]);
        map<string> headerMap = check getBulkApiHeaders(self.clientHandler);
        http:Response response = check self.salesforceClient->get(path, headerMap);
        if JSON == jobDataType {
            json jobResponse = check checkJsonPayloadAndSetErrors(response);
            JobInfo jobInfo = check jobResponse.cloneWithType(JobInfo);
            return jobInfo;
        } else {
            xml jobResponse = check checkXmlPayloadAndSetErrors(response);
            JobInfo jobInfo = check createJobRecordFromXml(jobResponse);
            return jobInfo;
        }
    }

    # Closes a job.
    #
    # + bulkJob - `BulkJob` record to be closed
    # + return - `JobInfo` after the state change of the job
    remote function closeJob(BulkJob bulkJob) returns error|JobInfo {
        string jobId = bulkJob.jobId;
        string path = utils:prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, jobId]);
        map<string> headerMap = check getBulkApiHeaders(self.clientHandler);
        http:Response response = check self.salesforceClient->post(path, JSON_STATE_CLOSED_PAYLOAD, headers = headerMap);
        json jobResponse = check checkJsonPayloadAndSetErrors(response);
        JobInfo jobInfo = check jobResponse.cloneWithType(JobInfo);
        return jobInfo;
    }

    # Aborts a job.
    #
    # + bulkJob - `BulkJob` to be aborted 
    # + return - `JobInfo` record after the state change of the job
    remote function abortJob(BulkJob bulkJob) returns error|JobInfo {
        string jobId = bulkJob.jobId;
        string path = utils:prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, jobId]);
        map<string> headerMap = check getBulkApiHeaders(self.clientHandler);
        http:Response response = check self.salesforceClient->post(path, JSON_STATE_CLOSED_PAYLOAD, headers = headerMap);
        json jobResponse = check checkJsonPayloadAndSetErrors(response);
        JobInfo jobInfo = check jobResponse.cloneWithType(JobInfo);
        return jobInfo;
    }

    # Adds batch to the job.
    #
    # + bulkJob - `BulkJob` record
    # + content - Batch content
    # + return - Batch info or `error`
    isolated remote function addBatch(BulkJob bulkJob,
                                    json|string|xml|string[][]|stream<string[], error?>|io:ReadableByteChannel content)
                                    returns error|BatchInfo {
        string path = utils:prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, bulkJob.jobId, BATCH]);
        // https://github.com/ballerina-platform/ballerina-lang/issues/26798
        string|json|xml payload;
        if bulkJob.jobDataType == JSON {
            if content is io:ReadableByteChannel {
                if QUERY == bulkJob.operation {
                    payload = check convertToString(content);
                } else {
                    payload = check convertToJson(content);
                }
            } else if content is string|json|xml {
                payload = content;
            } else {
                return error("Invalid request content");
            }
            map<string> headerMap = check getBulkApiHeaders(self.clientHandler, APP_JSON);
            http:Response response = check self.salesforceClient->post(path, payload, headers = headerMap);
            json batchResponse = check checkJsonPayloadAndSetErrors(response);
            BatchInfo binfo = check batchResponse.cloneWithType(BatchInfo);
            return binfo;
        } else if bulkJob.jobDataType == XML {
            if content is io:ReadableByteChannel {
                if QUERY == bulkJob.operation {
                    payload = check convertToString(content);
                } else {
                    payload = check convertToXml(content);
                }
            } else if content is string|json|xml {
                payload = content;
            } else {
                return error("Invalid request content");
            }
            map<string> headerMap = check getBulkApiHeaders(self.clientHandler, APP_XML);
            http:Response response = check self.salesforceClient->post(path, payload, headers = headerMap);
            xml batchResponse = check checkXmlPayloadAndSetErrors(response);
            BatchInfo binfo = check createBatchRecordFromXml(batchResponse);
            return binfo;
        } else if bulkJob.jobDataType == CSV {
            if content is io:ReadableByteChannel {
                payload = check convertToString(content);
            } else if content is string[][]|stream<string[], error?> {
                payload = check convertStringListToString(content);
            } else {
                payload = content;
            }
            map<string> headerMap = check getBulkApiHeaders(self.clientHandler, TEXT_CSV);
            http:Response response = check self.salesforceClient->post(path, payload, headers = headerMap);
            xml batchResponse = check checkXmlPayloadAndSetErrors(response);
            BatchInfo binfo = check createBatchRecordFromXml(batchResponse);
            return binfo;
        } else {
            return error("Invalid Job Type!");
        }
    }

    # Gets information about a batch.
    #
    # + bulkJob - Bulk job 
    # + batchId - ID of the batch of which info is required 
    # + return - Batch info or error
    isolated remote function getBatchInfo(BulkJob bulkJob, string batchId) returns error|BatchInfo {
        string path = utils:prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, bulkJob.jobId, BATCH, batchId]);
        map<string> headerMap = check getBulkApiHeaders(self.clientHandler);
        http:Response response = check self.salesforceClient->get(path, headerMap);
        if JSON == bulkJob.jobDataType {
            json batchResponse = check checkJsonPayloadAndSetErrors(response);
            BatchInfo binfo = check batchResponse.cloneWithType(BatchInfo);
            return binfo;
        } else {
            xml batchResponse = check checkXmlPayloadAndSetErrors(response);
            BatchInfo binfo = check createBatchRecordFromXml(batchResponse);
            return binfo;
        }
    }

    # Gets all batches of the job.
    #
    # + bulkJob - `BulkJob` record
    # + return - `BatchInfo[]` if success, else `error`
    isolated remote function getAllBatches(BulkJob bulkJob) returns error|BatchInfo[] {
        string path = utils:prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, bulkJob.jobId, BATCH]);
        map<string> headerMap = check getBulkApiHeaders(self.clientHandler);
        http:Response response = check self.salesforceClient->get(path, headerMap);
        BatchInfo[] batchInfoList = [];
        if JSON == bulkJob.jobDataType {
            json batchResponse = check checkJsonPayloadAndSetErrors(response);
            json batchInfoRes = check batchResponse.batchInfo;
            json[] batchInfoArr = <json[]>batchInfoRes;
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

    # Gets the request payload of a batch.
    #
    # + bulkJob - `BulkJob` record
    # + batchId - ID of the batch of which the request is required
    # + return - Batch content
    isolated remote function getBatchRequest(BulkJob bulkJob, string batchId) returns error|json|xml|string {
        string path = utils:prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, bulkJob.jobId, BATCH, batchId, REQUEST]);
        map<string> headerMap = check getBulkApiHeaders(self.clientHandler);
        http:Response response = check self.salesforceClient->get(path, headerMap);
        if QUERY == bulkJob.operation {
            return getQueryRequest(response, bulkJob.jobDataType);
        } else {
            match bulkJob.jobDataType {
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

    # Gets result of the records processed in a batch.
    #
    # + bulkJob - `BulkJob` record
    # + batchId - Batch ID
    # + return - Result list
    isolated remote function getBatchResult(BulkJob bulkJob, string batchId)
                                            returns error|json|xml|string|Result[] {
        string path = utils:prepareUrl([SERVICES, ASYNC, BULK_API_VERSION, JOB, bulkJob.jobId, BATCH, batchId, RESULT]);
        map<string> headerMap = check getBulkApiHeaders(self.clientHandler);
        http:Response response = check self.salesforceClient->get(path, headerMap);
        match bulkJob.jobDataType {
            JSON => {
                json resultResponse = check checkJsonPayloadAndSetErrors(response);
                if QUERY == bulkJob.operation {
                    return getJsonQueryResult(resultResponse, path, self.salesforceClient,
                        self.clientHandler);
                }
                return createBatchResultRecordFromJson(resultResponse);
            }
            XML => {
                xml resultResponse = check checkXmlPayloadAndSetErrors(response);
                if QUERY == bulkJob.operation {
                    return getXmlQueryResult(resultResponse, path, self.salesforceClient,
                        self.clientHandler);
                }
                return createBatchResultRecordFromXml(resultResponse);
            }
            CSV => {
                if QUERY == bulkJob.operation {
                    xml resultResponse = check checkXmlPayloadAndSetErrors(response);
                    return getCsvQueryResult(resultResponse, path, self.salesforceClient,
                        self.clientHandler);
                }
                string resultResponse = check checkTextPayloadAndSetErrors(response);
                return createBatchResultRecordFromCsv(resultResponse);
            }
            _ => {
                return error("Invalid Job Type!");
            }
        }
    }
}
