// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

# Defines the Attribute type.
# Contains the attribute information of the resultant record.
public type Attribute record {|
    # Type of the resultant record
    string 'type;
    # URL of the resultant record
    string url?;
|};

# Metadata for your organization and available to the logged-in user.
public type OrganizationMetadata record {|
    # Encoding
    string encoding;
    # Maximum batch size
    int maxBatchSize;
    # Available SObjects
    SObjectMetaData[] sobjects;
    json...;
|};

# Metadata for an SObject, including information about each field, URLs, and child relationships.
public type SObjectMetaData record {|
    # SObject name
    string name;
    # Is createable
    boolean createable;
    # Is deletable
    boolean deletable;
    # Is updateable
    boolean updateable;
    # Is queryable
    boolean queryable;
    # SObject label
    string label;
    # SObject URLs
    map<string> urls;
    json...;
|};

# Basic info of a SObject.
public type SObjectBasicInfo record {|
    # Metadata related to the SObject
    SObjectMetaData objectDescribe;
    json...;
|};

# Represent the Attributes at SObjectBasicInfo.
public type Attributes record {
    # Type of the resultant record
    string 'type;
    # URL of the resultant record
    string url;
};

# Response of object creation.
public type CreationResponse record {
    # Created object ID
    string id;
    # Array of errors
    anydata[] errors;
    # Success flag
    boolean success;
};

# Represents a Report.
public type Report record {
    # Unique report ID
    string id;
    # Report display name
    string name;
    # URL that returns report data
    string url;
    # URL that retrieves report metadata
    string describeUrl;
    # Information for each instance of the report that was run asynchronously.
    string instancesUrl;
};

# Represents an instance of a Report.
public type ReportInstance record {
    # Unique ID for a report instance
    string id;
    # Status of the report run
    string status;
    # Date and time when an instance of the report run was requested
    string requestDate;
    # Date, time when the instance of the report run finished
    string? completionDate;
    # URL where results of the report run for that instance are stored
    string url;
    # API name of the user that created the instance
    string ownerId;
    # Indicates if it is queryable
    boolean queryable;
    # Indicates if it has detailed data
    boolean hasDetailRows;
};

# Represents attributes of instance of an asynchronous report run.
public type AsyncReportAttributes record {
    # Unique ID for an instance of a report that was run
    string id;
    # Unique report ID
    string reportId;
    # Display name of the report
    string reportName;
    # Status of the report run
    string status;
    # API name of the user that created the instance
    string ownerId;
    # Date and time when an instance of the report run was requested
    string requestDate;
    # Format of the resource
    string 'type;
    # Date, time when the instance of the report run finished
    string? completionDate;
    # Error message if the instance run failed
    string? errorMessage;
    # Indicates if it is queryable
    boolean queryable;
};

# Represents attributes of instance of synchronous report run.
public type SyncReportAttributes record {
    # Unique report ID
    string reportId;
    # Display name of the report
    string reportName;
    # Format of the resource
    string 'type;
    # Resource URL to get report metadata
    string describeUrl;
    # Resource URL to run a report asynchronously
    string instancesUrl;
};

# Represents result of an asynchronous report run.
public type ReportInstanceResult record {
    # Attributes for the instance of the report run
    AsyncReportAttributes|SyncReportAttributes attributes;
    # Indicates if all report results are returned
    boolean allData;
    # Collection of summary level data or both detailed and summary level data
    map<json>? factMap;
    # Collection of column groupings
    map<json>? groupingsAcross;
    # Collection of row groupings
    map<json>? groupingsDown;
    # Information about the fields used to build the report
    map<json>? reportMetadata;
    # Indicates if it has detailed data
    boolean hasDetailRows;
    # Information on report groupings, summary fields, and detailed data columns
    map<json>? reportExtendedMetadata;
};

# Represent the metadata of deleted records.
public type DeletedRecordsResult record {
    # Array of deleted records
    record {|string deletedDate; string id;|}[] deletedRecords;
    # The earliest date covered by the results
    string earliestDateAvailable;
    # The latest date covered by the results
    string latestDateCovered;
};

# Represent the metadata of updated records.
public type UpdatedRecordsResults record {
    # Array of updated record IDs
    string[] ids;
    # The latest date covered by the results
    string latestDateCovered;
};

# Represent the password status.
public type PasswordStatus record{
    # Indicates whether the password is expired
    boolean isExpired;
};


# Represent the Error response for password access.
public type ErrorResponse record {
    # Error message
    string message;
    # Error code
    string errorCode;
};

# Represent a quick action.
public type QuickAction record {
    # Action enum or ID
    string actionEnumOrId;
    # Action label
    string label;
    # Action name
    string name;
    # Action type
    string 'type;
    # Action URLs
    record{string defaultValues?; string quickAction?; string describe?; string defaultValuesTemplate?;} urls;
};

# Represent a batch execution result.
public type SubRequestResult record {
    # Status code of the batch execution
    int statusCode;
    # Result of the batch execution
    json? result;
};

# Represent Subrequest of a batch.
public type Subrequest record {|
    # Subrequest of a batch
    string binaryPartName?;
    # Binary part name alias
    string binaryPartNameAlias?;
    # Method of the subrequest
    string method;
    # Rich input of the subrequest
    record{} richInput?;
    # URL of the subrequest
    string url;
|};

# Represent results of the batch request.
public type BatchResult record {
    # Indicates whether the batch request has errors
    boolean hasErrors;
    # Results of the batch request
    SubRequestResult[] results;
};

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
