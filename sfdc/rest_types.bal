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
# 
# Contains the attribute information of the resultant record.
#
# + type - type of the resultant record
# + url - url of the resultant record
public type Attribute record {|
    string 'type;
    string url;
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
