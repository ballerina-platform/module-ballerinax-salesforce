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
    http:BearerTokenConfig|config:OAuth2RefreshTokenGrantConfig auth;
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
    string url;
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
