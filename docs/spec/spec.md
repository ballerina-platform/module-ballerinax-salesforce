# Specification: Ballerina Salesforce package
_Owners_: @sahanHe \
_Reviewers_: @daneshk \
_Updated_: 2024/01/31 \
_Edition_: Swan Lake  

## Introduction

This is the specification for the `Salesforce` package of the [Ballerina language](https://ballerina.io). This package provides client functionalities to interact with the Salesforce [REST API](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/intro_rest.htm), [SOAP API](https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_quickstart_intro.htm), [APEX REST API](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_rest_intro.htm), [Bulk API](https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/api_asynch_introduction_how_bulk_api_works.htm), and [Bulk V2 API](https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/api_asynch_introduction_how_bulk_api_works.htm).

The `Salesforce` package specification has evolved and may continue to evolve in the future. The released versions of the specification can be found under the relevant GitHub tag.

If you have any feedback or suggestions about the package, start a discussion via a [GitHub issue](https://github.com/ballerina-platform/ballerina-standard-library/issues) or in the [Discord server](https://discord.gg/ballerinalang). Based on the outcome of the discussion, the specification and implementation can be updated. Community feedback is always welcome. Any accepted proposal, which affects the specification, is stored under `/docs/proposals`. Proposals under discussion can be found with the label `type/proposal` on GitHub.

The conforming implementation of the specification is released and included in the distribution. Any deviation from the specification is considered a bug.

## Contents
1. [Overview](#1-overview)
2. [REST Client](#2-restclient)
    1. [Client Configurations](#21-client-configurations)
    2. [Initialization](#22-initialization)
    3. [REST APIs](#restapis)
        1. [getOrganizationMetaData](#getOrganizationMetaData)
        2. [describe](#describe)
        3. [getPlatformAction](#getPlatformAction)
        4. [getApiVersions](#getApiVersions)
        5. [getResources](#getResources)
        6. [getLimits](#getLimits)
        7. [getById](#getById)
        8. [getByExternalId](#getByExternalId)
        9. [create](#create)
        10. [update](#update)
        11. [upsert](#upsert)
        12. [delete](#delete)
        13. [listReports](#listReports)
        14. [deleteReport](#deleteReport)
        15. [runReportSync](#runReportSync)
        16. [runReportAsync](#runReportAsync)
        17. [getReportInstanceResult](#getReportInstanceResult)
        18. [query](#query)
        19. [search](#search)
        20. [getDeletedRecords](#getDeletedRecords)
        21. [getUpdatedRecords](#getUpdatedRecords)
        22. [isPasswordExpired](#isPasswordExpired)
        23. [resetPassword](#resetPassword)
        24. [changePassword](#changePassword)
        25. [getQuickActions](#getQuickActions)
        26. [batch](#batch)
        27. [getNamedLayouts](#getNamedLayouts)
        28. [getInvocableActions](#getInvocableActions)
        29. [invokeActions](#invokeActions)
        30. [deleteRecordsUsingExtId](#deleteRecordsUsingExtId)
        31. [createIngestJob](#createIngestJob)
        32. [createQueryJob](#createQueryJob)
        33. [createQueryJobAndWait](#createQueryJobAndWait)
        34. [getJobInfo](#getJobInfo)
        35. [addBatch](#addBatch)
        36. [getAllJobs](#getAllJobs)
        37. [getAllQueryJobs](#getAllQueryJobs)
        38. [getJobStatus](#getJobStatus)
        39. [getQueryResult](#getQueryResult)
        40. [abortJob](#abortJob)
        41. [deleteJob](#deleteJob)
        42. [closeIngestJobAndWait](#closeIngestJobAndWait)
        43. [closeIngestJob](#closeIngestJob)
3. [Bulk Client](#3-bulkclient)
    1. [Client Configurations](#31-client-configurations)
    2. [Initialization](#32-initialization)
    3. [Bulk APIs](#33-bulkapis)
        1. [getJobInfo](#getJobInfoV1)
        2. [closeJob](#closeJobV1)
        3. [abortJob](#abortJobV1)
        4. [addBatch](#addBatchV1)
        5. [getBatchInfo](#getBatchInfoV1)
        6. [getAllBatches](#getAllBatchesV1)
        7. [getBatchRequest](#getBatchRequestV1)
        8. [getBatchRequest](#getBatchRequestV1)
4. [Soap Client](#4-soapclient)
    1. [Client Configurations](#41-client-configurations)
    2. [Initialization](#42-initialization)
    3. [Soap APIs](#43-bulkapis)
        1. [convertLead](#convertLead)


## 1. [Overview](#1-overview)
The Ballerina language offers first-class support for writing network-oriented programs. The `Salesforce` package leverages these language features to create a programming model for consuming the Salesforce APIs.

It offers intuitive resource methods to interact with the Salesforce API v59.

## 2. [REST Client](#2-restclient)

`salesforce:Client` can be used to access the Salesforce REST API. 

### 2.1. [Client Configurations](#21-client-configurations)

When initializing the client, following configurations can be provided,

```ballerina
public type ConnectionConfig record {|
    *config:ConnectionConfig;
    # The Salesforce endpoint URL
    string baseUrl;
    # Configurations related to client authentication
    http:BearerTokenConfig|
        config:OAuth2RefreshTokenGrantConfig | config:OAuth2PasswordGrantConfig | config:OAuth2ClientCredentialsGrantConfig auth;
    |}
```

### 2.2. [Initialization](#22-initialization)

A client can be initialized by providing the Salesforce and optionally the other configurations in `ClientConfiguration`.

```ballerina
ConnectionConfig config = {
    baseUrl: salesforceBaseUrl,
    auth: {
        token: salesforceAccessToken
    }
};

Client salesforceClient = check new (config);
```

### 2.3 [APIs](#restapis)

#### [getOrganizationMetaData](#getOrganizationMetaData)

Used to describe SObjects in the Salesforce

``` ballerina
# Gets metadata of your organization.
#
# + return - `OrganizationMetadata` record if successful or else `error`.
isolated remote function getOrganizationMetaData() returns OrganizationMetadata|error
```

#### [describe](#describe)

Used to completely describes the individual metadata at all levels of the specified object.

``` ballerina
# Completely describes the individual metadata at all levels of the specified object. Can be used to retrieve.
# the fields, URLs, and child relationships.
#
# + sObjectName - sObject name value.
# + return - `SObjectMetaData` record if successful or else`error`.
isolated remote function describe(string sObjectName) returns SObjectMetaData|error
```

#### [getPlatformAction](#getPlatformAction)

Used to query for actions displayed in the UI, given a user, a context, device format, and a record ID.

``` ballerina
# Query for actions displayed in the UI, given a user, a context, device format, and a record ID.
#
# + return - `SObjectBasicInfo` record if successful or else `error`.
isolated remote function getPlatformAction() returns SObjectBasicInfo|error.
```

#### [getApiVersions](#getApiVersions)

Used to list summary details about each REST API version available.

``` ballerina
# Lists summary details about each REST API version available.
#
# + return - List of `Version` if successful. Else, the occured `error`.
isolated remote function getApiVersions() returns Version[]|error
```

#### [getResources](#getResources)

Used to list the resources available for the specified API version.

``` ballerina
# Lists the resources available for the specified API version.
#
# + apiVersion - API version (v37).
# + return - `Resources` as a map of string if successful. Else, the occurred `error`.
isolated remote function getResources(string apiVersion) returns map<string>|error 
```

#### [getLimits](#getLimits)

Used to list the Limits information for your organization.

``` ballerina
# Lists the Limits information for your organization.
#
# + return - `OrganizationLimits` as a map of `Limit` if successful. Else, the occurred `error`.
isolated remote function getLimits() returns map<Limit>|error
```

#### [getById](#getById)

Used to get an object record by ID.

``` ballerina
# Gets an object record by ID.
#
# + sobjectName - sObject name.
# + id - sObject ID.
# + returnType - The payload, which is expected to be returned after data binding.
# + return - `record` if successful or else `error`.
isolated remote function getById(string sobjectName, string id, typedesc<record {}> returnType = <>)
                                    returns returnType|error
```
    
#### [getByExternalId](#getByExternalId)

Used to get an object record by external ID.

``` ballerina
# Gets an object record by external ID.
#
# + sobjectName - sObject name .
# + extIdField - External ID field name.
# + extId - External ID value.
# + returnType - The payload, which is expected to be returned after data binding.
# + return - `record` if successful or else `error`.
isolated remote function getByExternalId(string sobjectName, string extIdField, string extId,
            typedesc<record {}> returnType = <>) returns returnType|error
```

#### [create](#create)

Used to create records based on relevant object type sent with json record.

``` ballerina
# Creates records based on relevant object type sent with json record.
#
# + sObjectName - sObject name value.
# + sObject - Record to be inserted.
# + return - `CreationResponse` if successful or else `error`.
isolated remote function create(string sObjectName, record {} sObject)
                                    returns CreationResponse|error 
```

#### [update](#update)

Used to update records based on relevant object ID.

``` ballerina
# Updates records based on relevant object ID.
#
# + sObjectName - sObject name value.
# + id - sObject ID.
# + sObject - Record to be updated.
# + return - `Nil` on success, else returns an error.
isolated remote function update(string sObjectName, string id, record {} sObject)
                                    returns error?
```

#### [upsert](#upsert)

Used to upsert a record based on the value of a specified external ID field.

``` ballerina
# Upsert a record based on the value of a specified external ID field.
#
# + sObjectName - sObject name value.
# + externalIdField - External ID field of an object.
# + externalId - External ID.
# + sObject - Record to be upserted.
# + return - `Nil` if successful or else `error`.
isolated remote function upsert(string sObjectName, string externalIdField, string externalId,
            record {} sObject) returns error?
```

#### [delete](#delete)

Used to delete existing records based on relevant object ID.

``` ballerina
# Delete existing records based on relevant object ID.
#
# + sObjectName - SObject name value.
# + id - SObject ID.
# + return - Empty response if successful or else `error`.
isolated remote function delete(string sObjectName, string id) returns error?
```

#### [listReports](#listReports)

Used to list reports

``` ballerina
# Lists reports.
#
# + return - Array of `Report` if successful or else `error`.
isolated remote function listReports() returns Report[]|error
```

#### [deleteReport](#deleteReport)

Used to delete existing report based on relevant report ID.

``` ballerina
# Deletes a report.
#
# + reportId - Report Id.
# + return - `Nil` if the report deletion is successful or else an error.
isolated remote function deleteReport(string reportId) returns error?
```

#### [runReportSync](#runReportSync)

Used to run an instance of a report synchronously.

``` ballerina
# Runs an instance of a report synchronously.
#
# + reportId - Report Id.
# + return - ReportInstanceResult if successful or else `error`.
isolated remote function runReportSync(string reportId) returns ReportInstanceResult|error
```

#### [runReportAsync](#runReportAsync)

Used to run an instance of a report asynchronously.

``` ballerina
# Runs an instance of a report asynchronously.
#
# + reportId - Report Id.
# + return - ReportInstance if successful or else `error`.
isolated remote function runReportAsync(string reportId) returns ReportInstance|error 
```

#### [getReportInstanceResult](#getReportInstanceResult)

Used to get report instance result.

``` ballerina
# Get report instance result.
#
# + reportId - Report Id.
# + instanceId - Instance Id.
# + return - ReportInstanceResult if successful or else `error`.
isolated remote function getReportInstanceResult(string reportId, string instanceId) returns
            ReportInstanceResult|error
```

#### [query](#query)

Used to executes the specified SOQL query.

``` ballerina
# Executes the specified SOQL query.
#
# + soql - SOQL query.
# + returnType - The payload, which is expected to be returned after data binding.
# + return - `stream<{returnType}, error?>` if successful. Else, the occurred `error`.
isolated remote function query(string soql, typedesc<record {}> returnType = <>)
                                    returns stream<returnType, error?>|error
```

#### [search](#search)

Used to execute the specified SOSL query.

``` ballerina
# Executes the specified SOSL search.
#
# + sosl - SOSL search query.
# + returnType - The payload, which is expected to be returned after data binding.
# + return - `stream<{returnType}, error?>` record if successful. Else, the occurred `error`.
isolated remote function search(string sosl, typedesc<record {}> returnType = <>)
                                    returns stream<returnType, error?>|error
```
    
#### [getDeletedRecords](#getDeletedRecords)

Used to retrieve the list of individual records that have been deleted within the given timespan.

``` ballerina
# Retrieves the list of individual records that have been deleted within the given timespan.
#
# + sObjectName - SObject reference.
# + startDate - Start date of the timespan.
# + endDate - End date of the timespan.
# + return - `DeletedRecordsResult` record if successful or else `error`.
isolated remote function getDeletedRecords(string sObjectName, time:Civil startDate, time:Civil endDate)
        returns DeletedRecordsResult|error
```

#### [getUpdatedRecords](#getUpdatedRecords)

Used to retrieve the list of individual records that have been updated within the given timespan.

``` ballerina
# Retrieves the list of individual records that have been updated within the given timespan.
#
# + sObjectName - SObject reference.
# + startDate - Start date of the timespan.
# + endDate - End date of the timespan.
# + return - `UpdatedRecordsResults` record if successful or else `error`.
isolated remote function getUpdatedRecords(string sObjectName, time:Civil startDate, time:Civil endDate)
        returns UpdatedRecordsResults|error
```

#### [isPasswordExpired](#isPasswordExpired)

Used to retrieve the password information.

``` ballerina
# Get the password information
#
# + userId - User ID.
# + return - `boolean` if successful or else `error`.
isolated remote function isPasswordExpired(string userId) returns boolean|error
```

#### [resetPassword](#resetPassword)

Used to reset the user password.

``` ballerina
# Reset user password
#
# + userId - User ID.
# + return - `byte[]` if successful or else `error`.
isolated remote function resetPassword(string userId) returns byte[]|error
```

#### [changePassword](#changePassword)

Used to change the user password.

``` ballerina
# Change user password
#
# + userId - User ID.
# + newPassword - New user password as a string.
# + return - `Nil` if successful or else `error`.
isolated remote function changePassword(string userId, string newPassword) returns error?
```

#### [getQuickActions](#getQuickActions)

Used to return a list of actions and their details.

``` ballerina
# Returns a list of actions and their details
#
# + sObjectName - SObject reference.
# + return - `QuickAction[]` if successful or else `error`.
isolated remote function getQuickActions(string sObjectName) returns QuickAction[]|error
```

#### [batch](#batch)

Used to execute up to 25 subrequests in a single request.

``` ballerina
# Executes up to 25 subrequests in a single request.
#
# + batchRequests - A record containing all the requests.
# + haltOnError - If true, the request halts when an error occurs on an individual subrequest.
# + return - `BatchResult` if successful or else `error`.
isolated remote function batch(Subrequest[] batchRequests, boolean haltOnError = false) returns BatchResult|error
```

#### [getNamedLayouts](#getNamedLayouts)

Used to retrieve information about alternate named layouts for a given object.

``` ballerina
# Retrieves information about alternate named layouts for a given object.
#
# + sObjectName - SObject reference.
# + layoutName - Name of the layout.
# + returnType - The payload type, which is expected to be returned after data binding.
# + return - Record of `returnType` if successful or else `error`.
isolated remote function getNamedLayouts(@display {label: "Name of the sObject"} string sObjectName,
            @display {label: "Name of the layout"} string layoutName, typedesc<record {}> returnType = <>)
                                    returns returnType|error
```

#### [getInvocableActions](#getInvocableActions)

Used to retrieve a list of general action types for the current organization.

``` ballerina
# Retrieve a list of general action types for the current organization.
#
# + subContext - Sub context.
# + returnType - The payload type, which is expected to be returned after data binding.
# + return - Record of `returnType` if successful or else `error`.
isolated remote function getInvocableActions(string subContext,
            typedesc<record {}> returnType = <>) returns returnType|error
```

#### [invokeActions](#invokeActions)

Used to invoke actions.

``` ballerina
# Invoke Actions.
#
# + subContext - Sub context.
# + payload - Payload for the action.
# + returnType - The type of the returned variable.
# + return - Record of `returnType` if successful or else `error`.
isolated remote function invokeActions(string subContext, record {} payload,
            typedesc<record {}> returnType = <>) returns returnType|error
```

#### [deleteRecordsUsingExtId](#deleteRecordsUsingExtId)

Used to delete record using external Id.

``` ballerina
# Delete record using external Id.
#
# + sObjectName - Name of the sObject.
# + externalId - Name of the external id field.
# + value - value of the external id field.
# + return - `Nil` if successful or else `error`.
isolated remote function deleteRecordsUsingExtId(string sObjectName, string externalId, string value) returns error?
```

#### [apexRestExecute](#apexRestExecute)

Used to access Salesforce APEX resources.

``` ballerina
# Access Salesforce APEX resources.
#
# + urlPath - URI path.
# + methodType - HTTP method type.
# + payload - Payload.
# + returnType - The payload type, which is expected to be returned after data binding.
# + return - `string|int|record{}` type if successful or else `error`.
isolated remote function apexRestExecute(string urlPath, http:Method methodType,
            record {} payload = {}, typedesc<record {}|string|int?> returnType = <>)
            returns returnType|error
```

#### [createIngestJob](#createIngestJob)

Used to create a bulkv2 ingest job.

``` ballerina
# Creates a bulkv2 ingest job.
#
# + payload - The payload for the bulk job.
# + return - `BulkJob` if successful or else `error`.
isolated remote function createIngestJob(BulkCreatePayload payload) returns BulkJob|error
```

#### [createQueryJob](#createQueryJob)

Used to create a bulkv2 query job.

``` ballerina
# Creates a bulkv2 query job.
#
# + payload - The payload for the bulk job.
# + return - `BulkJob` if successful or else `error`.
isolated remote function createQueryJob(BulkCreatePayload payload) returns BulkJob|error
```

#### [createQueryJobAndWait](#createQueryJobAndWait)

Used to create a bulkv2 query job and provide a future value.

``` ballerina
# Creates a bulkv2 query job and provide a future value.
#
# + payload - The payload for the bulk job.
# + return - `future<BulkJobInfo>` if successful else `error`.
isolated remote function createQueryJobAndWait(BulkCreatePayload payload) returns future<BulkJobInfo|error>|error
```

#### [getJobInfo](#getJobInfo)

Used to retrieve detailed information about a job.

``` ballerina
# Retrieves detailed information about a job.
#
# + bulkJobId - Id of the bulk job.
# + bulkOperation - The processing operation for the job.
# + return - `BulkJobInfo` if successful or else `error`.
isolated remote function getJobInfo(string bulkJobId, BulkOperation bulkOperation) returns BulkJobInfo|error
```

#### [addBatch](#addBatch)

Used to upload data for a job using CSV data.

``` ballerina
# Uploads data for a job using CSV data.
#
# + bulkJobId - Id of the bulk job.
# + content - CSV data to be added.
# + return - `Nil` if successful or `error` if unsuccessful.
isolated remote function addBatch(string bulkJobId, string|string[][]|stream<string[], error?>|io:ReadableByteChannel content) returns error?
```

#### [getAllJobs](#getAllJobs)

Used to get details of all the jobs.

``` ballerina
# Get details of all the jobs.
#
# + jobType - Type of the job.
# + return - `AllJobs` record if successful or `error` if unsuccessful.
isolated remote function getAllJobs(JobType? jobType = ()) returns AllJobs|error
```

#### [getAllQueryJobs](#getAllQueryJobs)

Used to get details of all the query jobs.

``` ballerina
# Get details of all query jobs.
#
# + jobType - Type of the job.
# + return - `AllJobs` if successful else `error`.
isolated remote function getAllQueryJobs(JobType? jobType = ()) returns error|AllJobs
```

#### [getJobStatus](#getJobStatus)

Used to get job status information.

``` ballerina
# Get job status information
#
# + status - Status of the job.
# + bulkJobId - Id of the bulk job.
# + return - `string[][]` if successful else `error`.
isolated remote function getJobStatus(string bulkJobId, Status status)
            returns string[][]|error
```

#### [getQueryResult](#getQueryResult)

Used to get query job results.

``` ballerina
# Get query job results.
# + bulkJobId - Id of the bulk job.
# + return - `string[][]` if successful else `error`
isolated remote function getQueryResult(string bulkJobId)
            returns string[][]|error
```

#### [abortJob](#abortJob)

Used to abort the bulkv2 job.

``` ballerina
# Abort the bulkv2 job
#
# + bulkJobId - Id of the bulk job.
# + bulkOperation - The processing operation for the job.
# + return - `Nil` if successful else `error`.
isolated remote function abortJob(string bulkJobId, BulkOperation bulkOperation) returns BulkJobInfo|error
```

#### [deleteJob](#deleteJob)

Used to delete a bulkv2 job.

``` ballerina
# Delete a bulkv2 job.
#
# + bulkJobId - Id of the bulk job.
# + bulkOperation - The processing operation for the job.
# + return - `Nil` if successful else `error`.
isolated remote function deleteJob(string bulkJobId, BulkOperation bulkOperation) returns error?
```

#### [closeIngestJobAndWait](#closeIngestJobAndWait)

Used to notify Salesforce servers that the upload of job data is complete.

``` ballerina
# Notifies Salesforce servers that the upload of job data is complete.
# 
# + bulkJobId - Id of the bulk job.
# + return - `future<BulkJobInfo>` if successful else `error`.
isolated remote function closeIngestJobAndWait(string bulkJobId) returns error|future<BulkJobInfo|error>
```

#### [closeIngestJob](#closeIngestJob)

Used to notify Salesforce servers that the upload of job data is complete.

``` ballerina
# Notifies Salesforce servers that the upload of job data is complete
# 
# + bulkJobId - Id of the bulk job.
# + return - `BulkJobInfo` if successful else `error`.
isolated remote function closeIngestJob(string bulkJobId) returns error|BulkJobCloseInfo
```

## 3. [Bulk Client](#3-bulkclient)

`salesforce.bulk:Client` can be used to access the Salesforce Bulk API. 

### 3.1. [Client Configurations](#31-client-configurations)

When initializing the client, following configurations can be provided,

```ballerina
public type ConnectionConfig record {|
    *config:ConnectionConfig;
    # The Salesforce endpoint URL
    string baseUrl;
    # Configurations related to client authentication
    http:BearerTokenConfig|config:OAuth2RefreshTokenGrantConfig auth;
|};
```

### 3.2. [Initialization](#32-initialization)

A client can be initialized by providing the Salesforce and optionally the other configurations in `ClientConfiguration`.

```ballerina
ConnectionConfig config = {
    baseUrl: salesforceBaseUrl,
    auth: {
        token: salesforceAccessToken
    }
};

Client salesforceClient = check new (config);
```

### 3.3. [Bulk APIs](#33-bulkapis)

#### [createJob](#createJobV1)

Used to creates a bulk job.

``` ballerina
# Creates a bulk job.
#
# + operation - Type of operation like insert, delete, etc.
# + sobj - Type of sobject 
# + contentType - Content type of the job 
# + extIdFieldName - Field name of the external ID incase of an Upsert operation
# + return - returns `BulkJob` record or `error`
isolated remote function createJob(Operation operation, string sobj, JobType contentType, 
                                            string extIdFieldName = "") returns error|BulkJob
```

#### [getJobInfo](#getJobInfoV1)

Used to get information about a job.

``` ballerina
# Gets information about a job.
#
# + bulkJob - `BulkJob` record of which the info is required.
# + return - `JobInfo` record or `error`.
isolated remote function getJobInfo(BulkJob bulkJob)
                                        returns error|JobInfo
```

#### [closeJob](#closeJobV1)

Used to close a job.

``` ballerina
# Closes a job.
#
# + bulkJob - `BulkJob` record.
# + return - `JobInfo` after the state change of the job or `error`.
remote function closeJob(BulkJob bulkJob) returns error|JobInfo
```

#### [abortJob](#abortJobV1)

Used to abort a job.

``` ballerina
# Aborts a job.
#
# + bulkJob - `BulkJob` record.
# + return - `JobInfo` after the state change of the job or `error`.
remote function abortJob(BulkJob bulkJob) returns error|JobInfo
```

#### [addBatch](#addBatchV1)

Used to add a batch to the job.

``` ballerina
# Adds batch to the job.
#
# + bulkJob - `BulkJob` record.
# + content - Batch content.
# + return - Batch info or error.
isolated remote function addBatch(BulkJob bulkJob, json|string|xml|string[][]|stream<string[], error?>|io:ReadableByteChannel content)
                                    returns error|BatchInfo
```

#### [getBatchInfo](#getBatchInfoV1)

Used to get information about a batch.

``` ballerina
# Gets information about a batch.
#
# + bulkJob - `BulkJob` record.
# + batchId - ID of the batch of which info is required. 
# + return - `BatchInfo` or `error`.
isolated remote function getBatchInfo(BulkJob bulkJob, string batchId) returns error|BatchInfo
```

#### [getAllBatches](#getAllBatchesV1)

Used to get all batches of the job.

``` ballerina
# Gets all batches of the job.
#
# + bulkJob - `Bulkjob` record.
# + return - Array of `BatchInfo`.
isolated remote function getAllBatches(BulkJob bulkJob) returns error|BatchInfo[]
```

#### [getBatchRequest](#getBatchRequestV1)

Used to get the request payload of a batch.

``` ballerina
# Gets the request payload of a batch.
#
# + bulkJob - `BulkJob` record.
# + batchId - ID of the batch of which the request is required .
# + return - Batch content.
isolated remote function getBatchRequest(BulkJob bulkJob, string batchId) returns error|json|xml|string
```

#### [getBatchRequest](#getBatchRequestV1)

Used to get the request payload of a batch.

``` ballerina
# Gets result of the records processed in a batch.
#
# + bulkJob - `BulkJob` record.
# + batchId - Batch ID.
# + return - `json|xml|string|Result[]` if success, else `error`.
isolated remote function getBatchResult(BulkJob bulkJob, string batchId) returns error|json|xml|string|Result[]
```

## 4. [SOAP Client](#4-soapclient)

`salesforce.soap:Client` can be used to access the Salesforce SOAP API. 

### 4.1. [Client Configurations](#41-client-configurations)

When initializing the client, following configurations can be provided,

```ballerina
public type ConnectionConfig record {|
    *config:ConnectionConfig;
    # The Salesforce endpoint URL
    string baseUrl;
    # Configurations related to client authentication
    http:BearerTokenConfig|config:OAuth2RefreshTokenGrantConfig auth;
|};
```

### 4.2. [Initialization](#42-initialization)

A client can be initialized by providing the Salesforce and optionally the other configurations in `ClientConfiguration`.

```ballerina
ConnectionConfig config = {
    baseUrl: salesforceBaseUrl,
    auth: {
        token: salesforceAccessToken
    }
};

Client salesforceClient = check new (config);
```

### 4.3. [Soap APIs](#43-bulkapis)

#### [convertLead](#convertLead)

Used to convert lead to to account and contact.

``` ballerina
# Convert lead to to account and contact.
#
# + payload - Record represent convertLead paramaters.
# + return - `ConvertedLead` or `error`.
isolated remote function convertLead(LeadConvert payload) returns ConvertedLead|error
```
