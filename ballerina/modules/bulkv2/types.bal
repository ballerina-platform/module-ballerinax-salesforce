// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

# Represents status of the bulk jobs
public enum Status {
    SUCCESSFUL_RESULTS = "successfulResults",
    FAILED_RESULTS = "failedResults"
};

public enum JobStateEnum {
    OPEN = "Open",
    UPLOAD_COMPLETE = "UploadComplete",
    IN_PROGRESS = "InProgress",
    JOB_COMPLETE = "JobComplete",
    ABORTED = "Aborted",
    FAILED = "Failed"
};

public enum JobType {
    BIG_OBJECT_INGEST = "BigObjectIngest",
    CLASSIC = "Classic",
    V2_INGEST = "V2Ingest"
};

public enum BulkOperation {
    QUERY = "query",
    INGEST = "ingest"
};

# Operation type of the bulk job.
public enum Operation {
    INSERT = "insert",
    UPDATE = "update",
    DELETE = "delete",
    UPSERT = "upsert",
    HARD_DELETE = "hardDelete",
    QUERY = "query"
}; 

public enum LineEndingEnum {
    LF = "LF",
    CRLF = "CRLF"
};

public enum ColumnDelimiterEnum {
    BACKQUOTE,
    CARET,
    COMMA,
    PIPE,
    SEMICOLON,
    TAB
};

# Represents the Salesforce client configuration.
public type ConnectionConfig record {|
    *config:ConnectionConfig;
    # The Salesforce endpoint URL
    string baseUrl;
    # Configurations related to client authentication
    http:BearerTokenConfig|config:OAuth2RefreshTokenGrantConfig|
        config:OAuth2PasswordGrantConfig|config:OAuth2ClientCredentialsGrantConfig auth;
|};

# Defines the Salesforce version type.
public type Version record {
    # Label of the Salesforce version
    string label;
    # URL of the Salesforce version
    string url;
    # Salesforce version number
    string 'version;
};

# Defines the Limit type to list limits information for your org.
public type Limit record {|
    # The limit total for the org
    int Max;
    # The total number of calls or events left for the org
    int Remaining;
    json...;
|};

# Represents the bulk job creation request payload. 
public type BulkCreatePayload record {
    # the sObject type of the bulk job
    string 'object?;
    # the operation type of the bulk job
    Operation operation;
    # the column delimiter of the payload
    ColumnDelimiterEnum columnDelimiter?;
    # the content type of the payload
    string contentType?;
    # the line ending of the payload
    LineEndingEnum lineEnding?;
    # the external ID field name for upsert operations
    string externalIdFieldName?;
    # the SOQL query for query operations
    string query?;
};

# Represents the bulk job creation response.
public type BulkJob record {
    *BulkJobCloseInfo;
    # The URL to use for uploading the CSV data for the job.
    string contentUrl?;
    # The line ending of the payload.
    string lineEnding?;
    # The column delimiter of the payload.
    string columnDelimiter?;
};

# Represents bulk job related information.
public type BulkJobInfo record {
    *BulkJob;
    # The number of times that Salesforce attempted to process the job.
    int retries?;
    # The total time spent processing the job.
    int totalProcessingTime?;
    # The total time spent processing the job by API.
    int apiActiveProcessingTime?;
    # The total time spent to process triggers and other processes related to the job data;
    int apexProcessingTime?;
    # The number of records already processed by the job.
    int numberRecordsProcessed?;
};


# Represents bulk job related information when Closed. 
public type BulkJobCloseInfo record {
    # The ID of the job.
    string id;
    # The operation type of the job.
    string operation;
    # The sObject type of the job.
    string 'object;
    # The ID of the user who created the job.
    string createdById;
    # The date and time when the job was created.
    string createdDate;
    # The date and time when the job was finished.
    string systemModstamp;
    # The state of the job.
    string state;
    # The concurrency mode of the job.
    string concurrencyMode;
    # The content type of the payload.
    string contentType;
    # The API version.
    float apiVersion;
};


# Represents output for get all jobs request
public type AllJobs record {
    # Indicates whether there are more records to retrieve.
    boolean done;
    # Array of job records.
    BulkJobInfo[] records;
    # URL to retrieve the next set of records.
    string nextRecordsUrl;
};
