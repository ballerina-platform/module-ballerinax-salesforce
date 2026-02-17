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
import ballerinax/'client.config;

# Represents the status of the bulk jobs.
#
# + SUCCESSFUL_RESULTS - Indicates successful results
# + FAILED_RESULTS - Indicates failed results
public enum Status {
    SUCCESSFUL_RESULTS = "successfulResults",
    FAILED_RESULTS = "failedResults"
};

# Represents the state of the job.
#
# + OPEN - The job is open
# + UPLOAD_COMPLETE - The upload is complete
# + IN_PROGRESS - The job is in progress
# + JOB_COMPLETE - The job is complete
# + ABORTED - The job is aborted
# + FAILED - The job has failed
public enum JobStateEnum {
    OPEN = "Open",
    UPLOAD_COMPLETE = "UploadComplete",
    IN_PROGRESS = "InProgress",
    JOB_COMPLETE = "JobComplete",
    ABORTED = "Aborted",
    FAILED = "Failed"
};

# Represents the type of job.
#
# + BIG_OBJECT_INGEST - Big object ingest job type
# + CLASSIC - Classic job type
# + V2_INGEST - V2 ingest job type
public enum JobType {
    BIG_OBJECT_INGEST = "BigObjectIngest",
    CLASSIC = "Classic",
    V2_INGEST = "V2Ingest"
};

# Represents the bulk operation type.
#
# + QUERY - Query operation
# + INGEST - Ingest operation
public enum BulkOperation {
    QUERY = "query",
    INGEST = "ingest"
};

# Represents the operation type of the bulk job.
#
# + INSERT - Insert operation
# + UPDATE - Update operation
# + DELETE - Delete operation
# + UPSERT - Upsert operation
# + HARD_DELETE - Hard delete operation
# + QUERY - Query operation
public enum Operation {
    INSERT = "insert",
    UPDATE = "update",
    DELETE = "delete",
    UPSERT = "upsert",
    HARD_DELETE = "hardDelete",
    QUERY = "query"
};

# Represents the line ending type.
#
# + LF - Line feed
# + CRLF - Carriage return and line feed
public enum LineEndingEnum {
    LF = "LF",
    CRLF = "CRLF"
};

# Represents the column delimiter type.
#
# + BACKQUOTE - Backquote delimiter
# + CARET - Caret delimiter
# + COMMA - Comma delimiter
# + PIPE - Pipe delimiter
# + SEMICOLON - Semicolon delimiter
# + TAB - Tab delimiter
public enum ColumnDelimiterEnum {
    BACKQUOTE,
    CARET,
    COMMA,
    PIPE,
    SEMICOLON,
    TAB
};

# Represents the Salesforce client configuration.
#
# + baseUrl - The Salesforce endpoint URL
# + auth - Configurations related to client authentication
# + apiVersion - The Salesforce REST API version
public type ConnectionConfig record {|
    *config:ConnectionConfig;
    string baseUrl;
    http:BearerTokenConfig|config:OAuth2RefreshTokenGrantConfig|
        config:OAuth2PasswordGrantConfig|config:OAuth2ClientCredentialsGrantConfig auth;
    string apiVersion = "59.0";
|};

# Defines the Salesforce version type.
#
# + label - Label of the Salesforce version
# + url - URL of the Salesforce version
# + version - Salesforce version number
public type Version record {
    string label;
    string url;
    string 'version;
};

# Defines the Limit type to list limits information for your org.
#
# + Max - The limit total for the org
# + Remaining - The total number of calls or events left for the org
public type Limit record {|
    int Max;
    int Remaining;
    json...;
|};

# Represents the bulk job creation request payload. 
#
# + object - The sObject type of the bulk job
# + operation - The operation type of the bulk job
# + columnDelimiter - The column delimiter of the payload
# + contentType - The content type of the payload
# + lineEnding - The line ending of the payload
# + externalIdFieldName - The external ID field name for upsert operations
# + query - The SOQL query for query operations
public type BulkCreatePayload record {
    string 'object?;
    Operation operation;
    ColumnDelimiterEnum columnDelimiter?;
    string contentType?;
    LineEndingEnum lineEnding?;
    string externalIdFieldName?;
    string query?;
};

# Represents the bulk job creation response.
#
# + contentUrl - The URL to use for uploading the CSV data for the job
# + lineEnding - The line ending of the payload
# + columnDelimiter - The column delimiter of the payload
public type BulkJob record {
    *BulkJobCloseInfo;
    string contentUrl?;
    string lineEnding?;
    string columnDelimiter?;
};

# Represents bulk job related information.
#
# + retries - The number of times that Salesforce attempted to process the job
# + totalProcessingTime - The total time spent processing the job
# + apiActiveProcessingTime - The total time spent processing the job by API
# + apexProcessingTime - The total time spent to process triggers and other processes related to the job data
# + numberRecordsProcessed - The number of records already processed by the job
public type BulkJobInfo record {
    *BulkJob;
    int retries?;
    int totalProcessingTime?;
    int apiActiveProcessingTime?;
    int apexProcessingTime?;
    int numberRecordsProcessed?;
};

# Represents bulk job related information when Closed. 
#
# + id - The ID of the job
# + operation - The operation type of the job
# + object - The sObject type of the job
# + createdById - The ID of the user who created the job 
# + createdDate - The date and time when the job was created
# + systemModstamp - The date and time when the job was finished 
# + state - The state of the job
# + concurrencyMode - The concurrency mode of the job
# + contentType - The content type of the payload
# + apiVersion - The API version
public type BulkJobCloseInfo record {
    string id;
    string operation;
    string 'object;
    string createdById;
    string createdDate;
    string systemModstamp;
    string state;
    string concurrencyMode;
};

# Represents the output of the get all jobs request.
#
# + done - Indicates whether there are more records to retrieve
# + records - Array of job records
# + nextRecordsUrl - URL to retrieve the next set of records
public type AllJobs record {
    boolean done;
    BulkJobInfo[] records;
    string nextRecordsUrl;
};
