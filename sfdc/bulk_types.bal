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

# Define the job type.
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
public type JobInfo record {|
    string id;
    string operation;
    string 'object;
    string createdById;
    string createdDate;
    string systemModstamp;
    string state;
    string concurrencyMode;
    string contentType;
    int numberBatchesQueued;
    int numberBatchesInProgress;
    int numberBatchesCompleted;
    int numberBatchesFailed;
    int numberBatchesTotal;
    int numberRecordsProcessed;
    int numberRetries;
    float apiVersion;
    int numberRecordsFailed;
    int totalProcessingTime;
    int apiActiveProcessingTime;
    int apexProcessingTime;
    json...;
|};

# Define the batch type.
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
public type BatchInfo record {|
    string id;
    string jobId;
    string state;
    string createdDate;
    string systemModstamp;
    int numberRecordsProcessed;
    int numberRecordsFailed;
    int totalProcessingTime;
    int apiActiveProcessingTime;
    int apexProcessingTime;
    json...;
|};

# Define the result type.
#
# + id - The ID of the result, May be globally unique, but does not have to be
# + success - The result is a success or not
# + created - New record created or not
# + errors - Errors occurred
public type Result record {|
    string id?;
    boolean success;
    boolean created;
    string errors?;
|};

# Operation type of the bulk job.
public type OPERATION INSERT|UPDATE|DELETE|UPSERT|QUERY;

# Data type of the bulk job.
public type JOBTYPE JSON|XML|CSV;

public type BulkJob record {|
    string jobId;
    JOBTYPE jobDataType;
    OPERATION operation;
|};
