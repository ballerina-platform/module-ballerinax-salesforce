//
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
//

# Define the Salesforce version type.
# 
# + label - label of the salesforce version
# + url - url of the salesforce version
# + version - salesforce version number
public type Version record {|
    string label;
    string url;
    string 'version;
|};

# Define the Limit type to list limits information for your org.
# 
# + Max - the limit total for the org
# + Remaining - the total number of calls or events left for the org
public type Limit record {|
    int Max;
    int Remaining;
    json...;
|};

# Define the SOQL result type.
# 
# + done - query is completed or not
# + totalSize - the total number result records
# + records - result records
public type SoqlResult record {|
    boolean done;
    int totalSize;
    SoqlRecord[] records;
    json...;
|};

# Define the SOQL query result record type. 
# 
# + attributes - Attribute record
public type SoqlRecord record {|
    Attribute attributes;
    json...;
|};

# SOSL query result.
# 
# + searchRecords - matching records for the given search string
public type SoslResult record {|
    SoslRecord[] searchRecords;
    json...;
|};

# SOSL query result record.
# 
# + attributes - Attribute record
# + Id - ID od the matching object
public type SoslRecord record {|
    Attribute attributes;
    string Id;
    json...;
|};

# Define the Attribute type.
# Contains the attribute information of the resultant record.
# 
# + type - type of the resultant record
# + url - url of the resultant record
public type Attribute record {|
    string 'type;
    string url;
|};

# Performance feedback on a query, report or listview.
# 
# + plans - execution plans
public type ExecutionFeedback record {|
    ExecutionPlan[] plans;
    json...;
|};

# Possible execution plans in salesforce for a query, report or listview.
# 
# + cardinality - cardinality of the query, report or listview
# + fields - fields used to improve the performance
# + leadingOperationType - main operation type
# + notes - notes about the execution
# + relativeCost - relative cost of the execution plan
# + sobjectCardinality - sobject cardinality
# + sobjectType - sobject type involved
public type ExecutionPlan record {|
    int cardinality;
    string[] fields;
    string leadingOperationType;
    json[] notes;
    float relativeCost;
    int sobjectCardinality;
    string sobjectType;
    json...;
|};

# Salesforce object.
# 
# + attributes - Attribute record
# + Id - ID of the SObject
# + Name - Name of the SObject
public type SObject record {|
    Attribute attributes;
    string Id;
    string Name;
    json...;
|};

# SObject tree response.
# 
# + hasErrors - has any errors in the response
# + results - individual SObject manipulation results
public type SObjectTreeResponse record {|
    boolean hasErrors;
    SObjectTreeResponseResult[] results;
    json...;
|};

# SObject tree response result.
# 
# + id - ID of the SObject
# + referenceId - reference ID of the SObject
public type SObjectTreeResponseResult record {|
    string id;
    string referenceId;
    json...;
|};

# SObject operation result.
# 
# + id - record ID
# + success - operation success
# + created - record created
# + errors - errors occurred
public type SObjectResult record {|
    string id;
    boolean success;
    boolean created;
    string[] errors;
|};

# Deleted records info.
# 
# + deletedRecords - deleted records
# + earliestDateAvailable - earliest date
# + latestDateCovered - lastest date
public type DeletedRecordsInfo record {|
    DeletedRecord[] deletedRecords;
    string earliestDateAvailable;
    string latestDateCovered;
|};

# Updated records info.
# 
# + ids - updated record IDs
# + latestDateCovered - latest date
public type UpdatedRecordsInfo record {|
    string[] ids;
    string latestDateCovered;
|};

# Deleted record.
# 
# + id - record ID
# + deletedDate - deleted date
public type DeletedRecord record {|
    string id;
    string deletedDate;
|};

# Metadata for your organization and available to the logged-in user.
# 
# + encoding - encoding
# + maxBatchSize - maximum batch size
# + sobjects - available SObjects
public type OrgMetadata record {|
    string encoding;
    int maxBatchSize;
    SObjectMetaData[] sobjects;
    json...;
|};

# Metadata for an SObject, including information about each field, URLs, and child relationships.
# 
# + name - SObject name
# + createable - is createable
# + deletable - is deletable
# + updateable - is updateable
# + queryable - is queryable
# + label - SObject label
# + urls - SObject urls
public type SObjectMetaData record {|
    string name;
    boolean createable;
    boolean deletable;
    boolean updateable;
    boolean queryable;
    string label;
    map<string> urls;
    json...;
|};

public type SObjectBasicInfo record {|
    SObjectMetaData objectDescribe;
    json...;
|};
