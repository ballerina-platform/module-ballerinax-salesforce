// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
import ballerina/lang.runtime;
import ballerinax/'client.config;
import ballerinax/salesforce.utils;

# Ballerina Salesforce Bulk v2 Client provides the capability to access Salesforce Bulk API v2.
# This client allows you to perform bulk data operations such as creating, querying, updating, and deleting large volumes of data. 
# You can create and manage bulk jobs, upload data, check job status, and retrieve job results efficiently.
public isolated client class Client {

    private final http:Client salesforceClient;
    private final string apiBasePath;
    private map<string> sfLocators = {};

    # Initializes the Bulk V2 client. During initialization you can pass either http:BearerTokenConfig if you have a bearer
    # token or http:OAuth2RefreshTokenGrantConfig if you have Oauth tokens.
    # Create a Salesforce account and obtain tokens following 
    # [this guide](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm). 
    #
    # + salesforceConfig - Salesforce Connector configuration
    # + return - `salesforce:Error` on failure of initialization or else `()`
    public isolated function init(ConnectionConfig config) returns error? {
        http:Client|http:ClientError|error httpClientResult;
        http:ClientConfiguration httpClientConfig = check config:constructHTTPClientConfig(config);
        httpClientResult = trap new (config.baseUrl, httpClientConfig);

        if httpClientResult is http:Client {
            self.salesforceClient = httpClientResult;
        } else {
            return error(INVALID_CLIENT_CONFIG);
        }
        self.apiBasePath = string `${BASE_PATH}/v${config.apiVersion}`;
    }

    # Creates a bulkv2 ingest job.
    #
    # + payload - The payload for the bulk job
    # + return - `BulkJob` if successful or else `error`
    isolated remote function createIngestJob(BulkCreatePayload payload) returns BulkJob|error {
        string path = utils:prepareUrl([self.apiBasePath, JOBS, INGEST]);
        return check self.salesforceClient->post(path, payload);
    }

    # Creates a bulkv2 query job.
    #
    # + payload - The payload for the bulk job
    # + return - `BulkJob` if successful or else `error`
    isolated remote function createQueryJob(BulkCreatePayload payload) returns BulkJob|error {
        string path = utils:prepareUrl([self.apiBasePath, JOBS, QUERY]);
        return check self.salesforceClient->post(path, payload);
    }

    # Creates a bulkv2 query job and provide future value.
    #
    # + payload - The payload for the bulk job
    # + return - `future<BulkJobInfo>` if successful else `error`
    isolated remote function createQueryJobAndWait(BulkCreatePayload payload) returns future<BulkJobInfo|error>|error {
        string path = utils:prepareUrl([self.apiBasePath, JOBS, QUERY]);
        http:Response response = check self.salesforceClient->post(path, payload);
        if response.statusCode != 200 {
            return error("Error occurred while closing the bulk job. ", httpCode = response.statusCode);
        }
        BulkJob bulkJob = check (check response.getJsonPayload()).fromJsonWithType();
        final string jobPath = utils:prepareUrl([self.apiBasePath, JOBS, QUERY, bulkJob.id]);
        worker A returns BulkJobInfo|error {
            while true {
                runtime:sleep(2);
                http:Response jobStatus = check self.salesforceClient->get(jobPath);
                if jobStatus.statusCode != 200 {
                    return error("Error occurred while checking the status of the bulk job. ",
                        httpCode = jobStatus.statusCode);
                } else {
                    json responsePayload = check jobStatus.getJsonPayload();
                    BulkJobInfo jobInfo = check responsePayload.cloneWithType(BulkJobInfo);
                    if jobInfo.state == JOB_COMPLETE || jobInfo.state == FAILED || jobInfo.state == ABORTED {
                        return jobInfo;
                    }
                }
            }
        }
        return A;
    }

    # Retrieves detailed information about a job.
    #
    # + bulkJobId - Id of the bulk job
    # + bulkOperation - The processing operation for the job
    # + return - `BulkJobInfo` if successful or else `error`
    isolated remote function getJobInfo(string bulkJobId, BulkOperation bulkOperation) returns BulkJobInfo|error {
        string path = utils:prepareUrl([self.apiBasePath, JOBS, bulkOperation, bulkJobId]);
        return check self.salesforceClient->get(path);
    };

    # Uploads data for a job using CSV data.
    #
    # + bulkJobId - Id of the bulk job
    # + content - CSV data to be uploaded
    # + return - `()` if successful or else `error`
    isolated remote function addBatch(string bulkJobId, string|string[][]|stream<string[], error?>|io:ReadableByteChannel content) returns error? {
        string payload = "";
        string path = utils:prepareUrl([self.apiBasePath, JOBS, INGEST, bulkJobId, BATCHES]);
        if content is io:ReadableByteChannel {
            payload = check convertToString(content);
        } else if content is string[][]|stream<string[], error?> {
            payload = check convertStringListToString(content);
        } else {
            payload = content;
        }
        http:Response response = check self.salesforceClient->put(path, payload, mediaType = "text/csv");
        if response.statusCode != 201 {
            return error("Error occurred while adding the batch. ", httpCode = response.statusCode);
        }
    };

    # Get details of all the jobs.
    #
    # + jobType - Type of the job
    # + return - `AllJobs` record if successful or else `error`
    isolated remote function getAllJobs(JobType? jobType = ()) returns error|AllJobs {
        string path = utils:prepareUrl([self.apiBasePath, JOBS, INGEST]) +
            ((jobType is ()) ? "" : string `?jobType=${jobType}`);
        return check self.salesforceClient->get(path);
    }

    # Get details of all query jobs.
    #
    # + jobType - Type of the job
    # + return - `AllJobs` if successful or else `error`
    isolated remote function getAllQueryJobs(JobType? jobType = ()) returns error|AllJobs {
        string path = utils:prepareUrl([self.apiBasePath, JOBS, QUERY]) +
            ((jobType is ()) ? "" : string `?jobType=${jobType}`);
        return check self.salesforceClient->get(path);
    }

    # Get job status information.
    #
    # + status - Status of the job
    # + bulkJobId - Id of the bulk job
    # + return - `string[][]` if successful or else `error`
    isolated remote function getJobStatus(string bulkJobId, Status status)
            returns string[][]|error {
        string path = utils:prepareUrl([self.apiBasePath, JOBS, INGEST, bulkJobId, status]);
        http:Response response = check self.salesforceClient->get(path);
        if response.statusCode == 200 {
            string textPayload = check response.getTextPayload();
            if textPayload == "" {
                return [];
            }
            string[][] result = check parseCsvString(textPayload);
            return result;
        } else {
            json responsePayload = check response.getJsonPayload();
            return error("Error occurred while retrieving the bulk job status. ",
                httpCode = response.statusCode, details = responsePayload);
        }

    }

    # Get bulk query job results.
    # 
    # + bulkJobId - Id of the bulk job
    # + maxRecords - The maximum number of records to retrieve per set of results for the query
    # + return - The resulting string[][] if successful or else `error`
    isolated remote function getQueryResult(string bulkJobId, int? maxRecords = ()) returns string[][]|error {
                
        string path = "";
        string batchingParams = "";

        if maxRecords != () {
            lock {
                if self.sfLocators.hasKey(bulkJobId) {
                    string locator = self.sfLocators.get(bulkJobId);
                    if locator is "null" {
                        return [];
                    } 
                    batchingParams = string `results?maxRecords=${maxRecords}&locator=${locator}`;
                } else {
                    batchingParams = string `results?maxRecords=${maxRecords}`;
                }
            }
            path = utils:prepareUrl([self.apiBasePath, JOBS, QUERY, bulkJobId, batchingParams]);
            // Max records value default, we might not know when the locator comes
        } else {
            lock {
                if self.sfLocators.hasKey(bulkJobId) {
                    string locator = self.sfLocators.get(bulkJobId);
                    if locator is "null" {
                        return [];
                    } 
                    batchingParams = string `results?locator=${locator}`;
                    path = utils:prepareUrl([self.apiBasePath, JOBS, QUERY, bulkJobId, batchingParams]);
                } else {
                    path = utils:prepareUrl([self.apiBasePath, JOBS, QUERY, bulkJobId, RESULT]);
                }
            }
        } 
        
        http:Response response = check self.salesforceClient->get(path);
        if response.statusCode == 200 {
            string textPayload = check response.getTextPayload();
            if textPayload == "" {
                return [];
            }
            lock {
                string|http:HeaderNotFoundError locatorValue = response.getHeader("sforce-locator");
                if locatorValue is string {
                    self.sfLocators[bulkJobId] = locatorValue;
                } // header not found error ignored 
            }
            string[][] result = check parseCsvString(textPayload);
            return result;
        } else {
            json responsePayload = check response.getJsonPayload();
            return error("Error occurred while retrieving the query job results. ",
                httpCode = response.statusCode, details = responsePayload);
        }

    }

    # Abort the bulkv2 job.
    #
    # + bulkJobId - Id of the bulk job
    # + bulkOperation - The processing operation for the job
    # + return - `()` if successful or else `error`
    isolated remote function abortJob(string bulkJobId, BulkOperation bulkOperation) returns BulkJobInfo|error {
        string path = utils:prepareUrl([self.apiBasePath, JOBS, bulkOperation, bulkJobId]);
        record {} payload = {"state": "Aborted"};
        return check self.salesforceClient->patch(path, payload);
    }

    # Delete a bulkv2 job.
    #
    # + bulkJobId - Id of the bulk job
    # + bulkOperation - The processing operation for the job
    # + return - `()` if successful or else `error`
    isolated remote function deleteJob(string bulkJobId, BulkOperation bulkOperation) returns error? {
        string path = utils:prepareUrl([self.apiBasePath, JOBS, bulkOperation, bulkJobId]);
        return check self.salesforceClient->delete(path);
    }

    # Notifies Salesforce servers that the upload of job data is complete.
    #
    # + bulkJobId - Id of the bulk job
    # + return - future<BulkJobInfo> if successful or else `error`
    isolated remote function closeIngestJobAndWait(string bulkJobId) returns error|future<BulkJobInfo|error> {
        final string path = utils:prepareUrl([self.apiBasePath, JOBS, INGEST, bulkJobId]);
        record {} payload = {"state": "UploadComplete"};
        http:Response response = check self.salesforceClient->patch(path, payload);
        if response.statusCode != 200 {
            return error("Error occurred while closing the bulk job. ", httpCode = response.statusCode);
        }
        worker A returns BulkJobInfo|error {
            while true {
                runtime:sleep(2);
                http:Response jobStatus = check self.salesforceClient->get(path);
                if jobStatus.statusCode != 200 {
                    return error("Error occurred while checking the status of the bulk job. ",
                        httpCode = jobStatus.statusCode);
                } else {
                    json responsePayload = check jobStatus.getJsonPayload();
                    BulkJobInfo jobInfo = check responsePayload.cloneWithType(BulkJobInfo);
                    if jobInfo.state == JOB_COMPLETE || jobInfo.state == FAILED || jobInfo.state == ABORTED {
                        return jobInfo;
                    }
                }
            }
        }
        return A;
    }

    # Notifies Salesforce servers that the upload of job data is complete.
    #
    # + bulkJobId - Id of the bulk job
    # + return - BulkJobInfo if successful or else `error`
    isolated remote function closeIngestJob(string bulkJobId) returns error|BulkJobCloseInfo {
        final string path = utils:prepareUrl([self.apiBasePath, JOBS, INGEST, bulkJobId]);
        record {} payload = {"state": "UploadComplete"};
        return check self.salesforceClient->patch(path, payload);
    }
}
