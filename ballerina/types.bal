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

# Represents the Salesforce client configuration.
#
@display {label: "Connection Config"}
public type ConnectionConfig record {|
    *config:ConnectionConfig;
    # The Salesforce endpoint URL
    string baseUrl;
    # Configurations related to client authentication
    http:BearerTokenConfig|config:OAuth2RefreshTokenGrantConfig|config:OAuth2PasswordGrantConfig auth;
|};

# Defines the Salesforce version type.
#
# + label - Label of the Salesforce version
# + url - URL of the Salesforce version
# + version - Salesforce version number
@display{label: "Version"}
public type Version record {|
    @display{label: "Label"}
    string label;
    @display{label: "URL"}
    string url;
    @display{label: "Version"}
    string 'version;
|};

# Defines the Limit type to list limits information for your org.
#
# + Max - The limit total for the org
# + Remaining - The total number of calls or events left for the org
public type Limit record {|
    int Max;
    int Remaining;
    json...;
|};

# Define the SOQL result type.
#
# + done - Query is completed or not
# + totalSize - The total number result records
# + records - Result records
@display{label: "SOQL Result"}
public type SoqlResult record {|
    @display{label: "Completed"}
    boolean done;
    @display{label: "No of result records"}
    int totalSize;
    @display{label: "Records retreived"}
    SoqlRecord[] records;
    json...;
|};

# Defines the SOQL query result record type. 
#
# + attributes - Attribute record
@display{label: "SOQL record"}
public type SoqlRecord record {|
    @display{label: "Attributes"}
    Attribute attributes;
    json...;
|};

# Defines SOSL query result.
#
# + searchRecords - Matching records for the given search string
@display{label: "SOSL Result"}
public type SoslResult record {|
    @display{label: "Records retrieved"}
    SoslRecord[] searchRecords;
    json...;
|};

# Defines SOSL query result.
#
# + attributes - Attribute record
# + Id - ID of the matching object
@display{label: "SOSL record"}
public type SoslRecord record {|
    @display{label: "Attributes"}
    Attribute attributes;
    @display{label: "Id"}
    string Id;
    json...;
|};

# Defines the Attribute type.
# Contains the attribute information of the resultant record.
#
# + type - Type of the resultant record
# + url - URL of the resultant record
@display{label: "Attribute"}
public type Attribute record {|
    @display{label: "Type"}
    string 'type;
    @display{label: "URL"}
    string url?;
|};

# Metadata for your organization and available to the logged-in user.
#
# + encoding - Encoding
# + maxBatchSize - Maximum batch size
# + sobjects - Available SObjects
@display{label: "Organizational meta data"}
public type OrganizationMetadata record {|
    @display{label: "Encoding"}
    string encoding;
    @display{label: "Maximum batch size"}
    int maxBatchSize;
    @display{label: "SObject meta data"}
    SObjectMetaData[] sobjects;
    json...;
|};

# Metadata for your organization and available to the logged-in user.
#
# + encoding - Encoding
# + maxBatchSize - Maximum batch size
# + sobjects - Available SObjects
# 
# # Deprecated
# This record is deprecated as the name is changed.
@deprecated
@display{label: "Organizational meta data"}
public type OrgMetadata record {|
    @display{label: "Encoding"}
    string encoding;
    @display{label: "Maximum batch size"}
    int maxBatchSize;
    @display{label: "SObject meta data"}
    SObjectMetaData[] sobjects;
    json...;
|};

# Metadata for an SObject, including information about each field, URLs, and child relationships.
#
# + name - SObject name
# + createable - Is createable
# + deletable - Is deletable
# + updateable - Is updateable
# + queryable - Is queryable
# + label - SObject label
# + urls - SObject URLs
@display{label: "SObject meta data"}
public type SObjectMetaData record {|
    @display{label: "Name"}
    string name;
    @display{label: "Creatable"}
    boolean createable;
    @display{label: "Deletable"}
    boolean deletable;
    @display{label: "Updatable"}
    boolean updateable;
    @display{label: "Queryable"}
    boolean queryable;
    @display{label: "Label"}
    string label;
    @display{label: "URLs"}
    map<string> urls;
    json...;
|};

# Basic info of a SObject.
#
# + objectDescribe - Metadata related to the SObject
@display{label: "SObject basic info"}
public type SObjectBasicInfo record {|
    @display{label: "SObject meta data"}
    SObjectMetaData objectDescribe;
    json...;
|};

# Response of object creation.
#
# + id - Created object ID  
# + errors - Array of errors
# + success - Success flag
public type CreationResponse record {
    string id;
    anydata[] errors;
    boolean success;
};

# Represents a Report
#
# + id - Unique report ID  
# + name - Report display name  
# + url - URL that returns report data  
# + describeUrl - URL that retrieves report metadata  
# + instancesUrl - Information for each instance of the report that was run asynchronously.
public type Report record {
    string id;
    string name;
    string url;
    string describeUrl;
    string instancesUrl;
};

# Represents an instance of a Report
#
# + id - Unique ID for a report instance
# + status - Status of the report run
# + requestDate - Date and time when an instance of the report run was requested
# + completionDate - Date, time when the instance of the report run finished
# + url - URL where results of the report run for that instance are stored
# + ownerId - API name of the user that created the instance
# + queryable - Indicates if it is queryable
# + hasDetailRows - Indicates if it has detailed data
public type ReportInstance record {
    string id;
    string status;
    string requestDate;
    string? completionDate;
    string url;
    string ownerId;
    boolean queryable;
    boolean hasDetailRows;
};

# Represents attributes of instance of an asynchronous report run
#
# + id - Unique ID for an instance of a report that was run  
# + reportId - Unique report ID
# + reportName - Display name of the report
# + status - Status of the report run
# + ownerId - API name of the user that created the instance
# + requestDate - Date and time when an instance of the report run was requested 
# + 'type - Format of the resource
# + completionDate - Date, time when the instance of the report run finished
# + errorMessage - Error message if the instance run failed
# + queryable - Indicates if it is queryable
public type AsyncReportAttributes record {
    string id;
    string reportId;
    string reportName;
    string status;
    string ownerId;
    string requestDate;
    string 'type;
    string? completionDate;
    string? errorMessage;
    boolean queryable;
};

# Represents attributes of instance of synchronous report run
#
# + reportId - Unique report ID  
# + reportName - Display name of the report  
# + 'type - API resource format  
# + describeUrl - Resource URL to get report metadata  
# + instancesUrl - Resource URL to run a report asynchronously
public type SyncReportAttributes record {
    string reportId;
    string reportName;
    string 'type;
    string describeUrl;
    string instancesUrl;
};

# Represents result of an asynchronous report run
#
# + attributes - Attributes for the instance of the report run
# + allData - Indicates if all report results are returned
# + factMap - Collection of summary level data or both detailed and summary level data
# + groupingsAcross - Collection of column groupings
# + groupingsDown - Collection of row groupings
# + reportMetadata - Information about the fields used to build the report
# + hasDetailRows - Indicates if it has detailed data
# + reportExtendedMetadata - Information on report groupings, summary fields, and detailed data columns
public type ReportInstanceResult record {
    AsyncReportAttributes|SyncReportAttributes attributes;
    boolean allData;
    map<json> factMap;
    map<json> groupingsAcross;
    map<json> groupingsDown;
    map<json> reportMetadata;
    boolean hasDetailRows;
    map<json>? reportExtendedMetadata;
};
