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

import ballerina/http;
import ballerinax/'client.config;

public type ConnectionConfig record {|
    # The Salesforce endpoint URL
    string baseUrl;
    # Configurations related to client authentication
    http:BearerTokenConfig|config:OAuth2RefreshTokenGrantConfig auth;
    # The HTTP version understood by the client
    http:HttpVersion httpVersion = http:HTTP_2_0;
    # Configurations related to HTTP/1.x protocol
    ClientHttp1Settings http1Settings?;
    # Configurations related to HTTP/2 protocol
    http:ClientHttp2Settings http2Settings?;
    # The maximum time to wait (in seconds) for a response before closing the connection
    decimal timeout = 60;
    # The choice of setting `forwarded`/`x-forwarded` header
    string forwarded = "disable";
    # Configurations associated with request pooling
    http:PoolConfiguration poolConfig?;
    # HTTP caching related configurations
    http:CacheConfig cache?;
    # Specifies the way of handling compression (`accept-encoding`) header
    http:Compression compression = http:COMPRESSION_AUTO;
    # Configurations associated with the behaviour of the Circuit Breaker
    http:CircuitBreakerConfig circuitBreaker?;
    # Configurations associated with retrying
    http:RetryConfig retryConfig?;
    # Configurations associated with inbound response size limits
    http:ResponseLimitConfigs responseLimits?;
    # SSL/TLS-related options
    http:ClientSecureSocket secureSocket?;
    # Proxy server related options
    http:ProxyConfig proxy?;
    # Enables the inbound payload validation functionality which provided by the constraint package. Enabled by default
    boolean validation = true;
|};

# Provides settings related to HTTP/1.x protocol.
public type ClientHttp1Settings record {|
    # Specifies whether to reuse a connection for multiple requests
    http:KeepAlive keepAlive = http:KEEPALIVE_AUTO;
    # The chunking behaviour of the request
    http:Chunking chunking = http:CHUNKING_AUTO;
    # Proxy server related options
    ProxyConfig proxy?;
|};

# Proxy server configurations to be used with the HTTP client endpoint.
public type ProxyConfig record {|
    # Host name of the proxy server
    string host = "";
    # Proxy server port
    int port = 0;
    # Proxy server username
    string userName = "";
    # Proxy server password
    @display {label: "", kind: "password"}
    string password = "";
|};

# Defines the job type.
#
# + id - Unique ID for this job
# + operation - The processing operation for all the batches in the job
# + object - The object type for the data being processed, All data in a job must be of a single object type
# + createdById - The ID of the user who created this job
# + createdDate - The date and time in the UTC time zone when the job was created
# + systemModstamp - Date and time in the UTC time zone when the job finished
# + state - The current state of processing for the job
# + concurrencyMode - The concurrency mode for the job
# + contentType - The content type for the job
# + numberBatchesQueued - The number of batches queued for this job
# + numberBatchesInProgress - The number of batches that are in progress for this job
# + numberBatchesCompleted - The number of batches that have been completed for this job
# + numberBatchesFailed - The number of batches that have failed for this job
# + numberBatchesTotal - The number of total batches currently in the job
# + numberRecordsProcessed - The number of records already processed
# + numberRetries - The number of times that Salesforce attempted to save the results of an operation
# + apiVersion - The API version of the job set in the URI when the job was created
# + numberRecordsFailed - The number of records that were not processed successfully in this job
# + totalProcessingTime - The number of milliseconds taken to process the job
# + apiActiveProcessingTime - The number of milliseconds taken to actively process the job and includes
#                             apexProcessingTime, but doesn't include the time the job waited in the queue to be 
#                             processed or the time required for serialization and deserialization
# + apexProcessingTime - The number of milliseconds taken to process triggers and other processes related to the job
@display{label: "Bulk Job Info"}
public type JobInfo record {|
    @display{label: "Job Id"}
    string id;
    @display{label: "Operation"}
    string operation;
    @display{label: "SObject"}
    string 'object;
    @display{label: "Created by"}
    string createdById;
    @display{label: "Created date"}
    string createdDate;
    @display{label: "Last modified timestamp"}
    string systemModstamp;
    @display{label: "State"}
    string state;
    @display{label: "Concurrency mode"}
    string concurrencyMode;
    @display{label: "Content type"}
    string contentType;
    @display{label: "No of queued batches"}
    int numberBatchesQueued;
    @display{label: "No of inprogress batches"}
    int numberBatchesInProgress;
    @display{label: "No of completed batches"}
    int numberBatchesCompleted;
    @display{label: "No of failed batches"}
    int numberBatchesFailed;
    @display{label: "Total batches"}
    int numberBatchesTotal;
    @display{label: "No of processed records"}
    int numberRecordsProcessed;
    @display{label: "No of retries"}
    int numberRetries;
    @display{label: "Api version"}
    float apiVersion;
    @display{label: "No of failed records"}
    int numberRecordsFailed;
    @display{label: "Total processing time"}
    int totalProcessingTime;
    @display{label: "Api active processing time"}
    int apiActiveProcessingTime;
    @display{label: "APEX processing time"}
    int apexProcessingTime;
    json...;
|};

# Defines the batch type.
#
# + id - The ID of the batch, May be globally unique, but does not have to be
# + jobId - The unique, 18–character ID for the job associated with this batch
# + state - The current state of processing for the batch
# + createdDate - The date and time in the UTC time zone when the batch was created
# + systemModstamp - The date and time in the UTC time zone that processing ended. This is only valid when the state
#                    is Completed.
# + numberRecordsProcessed - The number of records processed in this batch at the time the request was sent
# + numberRecordsFailed - The number of records that were not processed successfully in this batch
# + totalProcessingTime - The number of milliseconds taken to process the batch, This excludes the time the batch
#                         waited in the queue to be processed
# + apiActiveProcessingTime - The number of milliseconds taken to actively process the batch, and includes
#                             apexProcessingTime
# + apexProcessingTime - The number of milliseconds taken to process triggers and other processes related to the
#                        batch data
@display{label: "Batch Info"}
public type BatchInfo record {|
    @display{label: "Id"}
    string id;
    @display{label: "Bulk job Id"}
    string jobId;
    @display{label: "Current State"}
    string state;
    @display{label: "Created date"}
    string createdDate;
    @display{label: "Last modified timestamp"}
    string systemModstamp;
    @display{label: "No of processed records"}
    int numberRecordsProcessed;
    @display{label: "No of failed records"}
    int numberRecordsFailed;
    @display{label: "Total processing time"}
    int totalProcessingTime;
    @display{label: "Api active processing time"}
    int apiActiveProcessingTime;
    @display{label: "APEX processing time"}
    int apexProcessingTime;
    json...;
|};

# Defines the result type.
#
# + id - The ID of the result, May be globally unique, but does not have to be
# + success - The result is a success or not
# + created - New record created or not
# + errors - Errors occurred
@display{label: "Result"}
public type Result record {|
    @display{label: "Id"}
    string id?;
    @display{label: "Success"}
    boolean success;
    @display{label: "Created"}
    boolean created;
    @display{label: "Errors"}
    string errors?;
|};

# Data type of the bulk job.
public enum JobType {
    JSON,
    XML,
    CSV
}

# Operation type of the bulk job.
public enum Operation {
    INSERT = "insert",
    UPDATE = "update",
    DELETE = "delete",
    UPSERT = "upsert",
    QUERY = "query"
}

# Defines bulk job related information.
# 
# + jobId - Bulk job id
# + jobDataType - Data type of the job, Can be JSON, XML or CSV
# + operation - Bulk operation.Can be insert, update, delete, upsert, query   
@display{label: "Bulk job"}
public type BulkJob record {|
    @display{label: "Job id"}
    string jobId;
    @display{label: "Data type"}
    JobType jobDataType;
    @display{label: "Operation"}
    Operation operation;
|};
