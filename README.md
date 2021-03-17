# Salesforce Ballerina Connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-sfdc/workflows/CI/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-sfdc/actions?query=workflow%3ACI)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-sfdc.svg)](https://github.com/ballerina-platformmodule-ballerinax-sfdc/commits/master)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Connects to Salesforce from Ballerina.

# Introduction

## Salesforce Data APIs

Salesforce has a vast landscape of APIs since they follow an API-first approach to building features on the Salesforce Platform. This approach gives users flexibility to manipulate their data however they want. The most commonly used Salesforce Data APIs are REST API, SOAP API, Bulk API and Streaming API and together they make up the Salesforce Data API. 

## Connector Overview

Ballerina Salesforce connector currently utilizes the Salesforce REST API and Bulk API for convenient data manipulation. 

The Salesforce connector allows users to perform CRUD operations for SObjects, query using SOQL, search using SOSL, and describe SObjects and organizational data through the Salesforce REST API. Also, it supports adding bulk data jobs and batches of types JSON, XML, and CSV via the Salesforce Bulk API. Apart from these functionalities Ballerina Salesforce Connector includes a listener module to capture events. This connector follows OAuth 2.0 authentication for secure access. 


![Ballerina Salesforce Connector Overview](./docs/images/connector_overview.png)


### REST API Operations

REST API provides a powerful, convenient, and simple Web services API for interacting with Salesforce Lightning Platform providing access to all the Salesforce functionalities through REST resources and HTTP methods. Ballerina Salesforce Connector utilizes the REST API for Salesforce Object (SObject) operations and for searching and querying data. At the same time, the connector provides users to get SObject details and organizational data using the REST API. 

#### SObject Operations

The `ballerinax/sfdc` module contains operations related to standard and customized SObjects such as Account, Contact, Opportunity, Lead etc. It facilitates users to create SObjects and get, update and delete records by SObject Id. 

#### SOQL & SOSL Operations

The `ballerinax/sfdc` module contains operations, which query using Salesforce Object Query Language (SOQL) and search using Salesforce Object Search Language (SOSL). This allows complex operations using SObjects relationships.

### Bulk API Operations

Salesforce Bulk API is a specialized asynchronous RESTful API for loading and querying bulk of data at once.  The `ballerinax/sfdc` module supports bulk data operations for CSV, JSON, and XML data types. 

### Event Listener

The Salesforce Streaming API let users push a stream of notification from Salesforce to client apps based push topics. Push topics are SObjects that contain criterias for the events that users want to listen to such as data changes for a particular SObject.  

The `ballerinax/sfdc` module includes a Listener that would capture events on PushTopics defined in a Salesforce instance. PushTopic events provide a way to receive notifications for changes to Salesforce data that match an SOQL query.


# Prerequisites

1. Salesforce Organization  

    You can simply setup the Salesforce Developer Edition Organization for testing purposes through the following link [developer.salesforce.com/signup](https://developer.salesforce.com/signup). 

2. Verify API Enabled permission in your Salesforce Organization
3. Download and install [Ballerina](https://ballerina.io/downloads/). 
4. Install java and set up environment 

# Supported Versions & Limitations

## Supported Versions

<table>
  <tr>
   <td>Ballerina Language Version
   </td>
   <td>Swan Lake Alpha2
   </td>
  </tr>
  <tr>
   <td>Java Development Kit (JDK) 
   </td>
   <td>11
   </td>
  </tr>
  <tr>
   <td>Salesforce API 
   </td>
   <td>v48.0
   </td>
  </tr>
  <tr>
   <td>Salesforce Bulk API 
   </td>
   <td>v1
   </td>
  </tr>
</table>


# Quickstart(s)

## Step 1: Import Ballerina Salesforce module

First, import the `ballerinax/sfdc` module into the Ballerina project.

```ballerina
import ballerinax/sfdc;
```

Instantiate the connector by giving authentication details in the HTTP client config, which has built-in support for OAuth 2.0 to authenticate and authorize requests. The Salesforce connector can be instantiated in the HTTP client config using the access token or using the client ID, client secret, and refresh token.


## Step 2: Obtain Tokens for authentication

1. Visit [Salesforce](https://www.salesforce.com/) and create a Salesforce Account.
2. Create a connected app and obtain the following credentials:
    *   Base URL (Endpoint)
    *   Access Token
    *   Client ID
    *   Client Secret
    *   Refresh Token
    *   Refresh Token URL
3. When you are setting up the connected app, select the following scopes under Selected OAuth Scopes:
    *   Access and manage your data (api)
    *   Perform requests on your behalf at any time (refresh_token, offline_access)
    *   Provide access to your data via the Web (web)
4. Provide the client ID and client secret to obtain the refresh token and access token. For more information on obtaining OAuth2 credentials, go to [Salesforce documentation](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).


## Step 3: Create the Salesforce client

The Ballerina Salesforce connector has allowed users to create the client using the [direct token configuration](https://ballerina.io/learn/by-example/secured-client-with-oauth2-direct-token-type.html) and as well as [bearer token configuration](https://ballerina.io/learn/by-example/secured-client-with-bearer-token-auth.html). 

Users are recommended to use direct-token config when initializing the Salesforce client for continuous access by providing the Salesfoce account's domain URL as the `baseURL` and the `client id`, `client secret`, `refresh token` obtained in the step two and `https://login.salesforce.com/services/oauth2/token` as `refreshUrl` in general scenarios. 

```ballerina
// Create Salesforce client configuration by reading from config file.

sfdc:SalesforceConfiguration sfConfig = {
   baseUrl: <"EP_URL">,
   clientConfig: {
     clientId: <"CLIENT_ID">,
     clientSecret: <"CLIENT_SECRET">,
     refreshToken: <"REFRESH_TOKEN">,
     refreshUrl: <"REFRESH_URL"> 
   }
};

sfdc:Client baseClient = new (sfConfig);
```

If the user already owns a valid access token he can initialize the client using bearer-token configuration providing the access token as a bearer token for quick API calls. 

```ballerina
sfdc:SalesforceConfiguration sfConfig = {
   baseUrl: <"EP_URL">,
   clientConfig: {
     token: <"ACCESS_TOKEN">
   }
};

sfdc:Client baseClient = new (sfConfig);
```

This access token will expire in 7200 seconds in general scenarios and the expiration time of the access token can be different from organization to organization. In such cases users have to get the new access token and update the configuration. 


If you want to add your own key store to define the `secureSocketConfig`, change the Salesforce configuration as mentioned below.


```ballerina
// Create Salesforce client configuration by reading from config file.

sfdc:SalesforceConfiguration sfConfig = {
   baseUrl: <"EP_URL">,
   clientConfig: {
     clientId: <"CLIENT_ID">,
     clientSecret: <"CLIENT_SECRET">,
     refreshToken: <"REFRESH_TOKEN">,
     refreshUrl: <"REFRESH_URL"> 
   },
   secureSocketConfig: {
     trustStore: {
       path: <"TRUSTSTORE_PATH"">,
       password: <"TRUSTSTORE_PASSWORD">
      }
    }
};

sfdc:Client baseClient = new (sfConfig);
```


## Step 4: Implement Operations


### SObject Operations

As described earlier Ballerina Salesforce connector facilitates users to perform CRUD operations on SObject through remote method invocations. 


#### Create Record

The `createRecord` remote function of the baseclient can be used to create SObject records for a given SObject type. Users need to pass SObject name and the SObject record in json format to the `createRecord` function and it will return newly created record Id as a string at the success and will return an error at the failure. 


```ballerina
json accountRecord = {
   Name: "John Keells Holdings",
   BillingCity: "Colombo 3"
 };

string|sdfc:Error recordId = baseClient->createRecord(ACCOUNT, accountRecord);
```

#### Get Record

The `getRecord` remote function of the baseclient can be used to get SObject record by SObject Id. Users need to pass the path to the SObject including the SObject Id to the `getRecord` function and it will return the record in json at the success and will return an error at the failure. 


```ballerina
string testRecordId = "001xa000003DIlo";
string path = "/services/data/v48.0/sobjects/Account/" + testRecordId;
json|Error response = baseClient->getRecord(path);
```

#### Update Record

The `updateRecord` remote function of the baseclient can be used to update SObject records for a given SObject type. Users need to pass SObject name, SObject Id and the SObject record in json format to the updateRecord’ function and it will return `true` at the success and will return an error at the failure. 


```ballerina
json account = {
       Name: "WSO2 Inc",
       BillingCity: "Jaffna",
       Phone: "+94110000000"
   };
boolean|sfdc:Error isSuccess = baseClient->updateRecord(ACCOUNT, testRecordId, account);
```

#### Delete Record

The Ballerina Salesforce connector facilitates users to delete SObject records by the SObject Id. Users need to pass SObject Name and the SObject record id as parameters and the function will return true at successful completion. 


```ballerina
string testRecordId = "001xa000003DIlo";
boolean|sfdc:Error isDeleted = baseClient->deleteRecord(ACCOUNT, testRecordId);
```

### Convenient CRUD Operations for Common SObjects

Apart from the common CRUD operations that can be used with any SObject, the Ballerina Salesforce Connector provides customized CRUD operations for pre-identified, most commonly used SObjects. They are **Account**, **Lead**, **Contact**, **Opportunity** and **Product**. 

Following are the sample codes for Account’s CRUD operations and the other above mentioned SObjects follow the same implementation and only the Id should be changed according to the SObject type. 


#### Create Account

`createAccount` remote function accepts an account record in json as an argument and returns Id of the account created at success. 


```ballerina
json accountRecord = {
   Name: "John Keells Holdings",
   BillingCity: "Colombo 3"
 };

string|sdfc:Error accountId = baseClient->createAccount(accountRecord);
```


#### Get Account by Id

User needs to pass the Id of the account and the names of the fields needed parameters for the `getAccountById` remote function. Function will return the record in json format at success. 


```ballerina
string accountId = "001xa000003DIlo";

json|sfdc:Error account = baseClient->getAccountById(accountId, Name, BillingCity);
```


#### Update Account

`updateAccount` remote function accepts account id and the account record needed to update in json as arguments and returns true at success. 


```ballerina
string accountId = "001xa000003DIlo";
json account = {
       Name: "WSO2 Inc",
       BillingCity: "Jaffna",
       Phone: "+94110000000"
   };
boolean|sfdc:Error isSuccess = baseClient->updateRecord(accountId, account);
```

#### Delete Account

User needs to pass the Id of the account he needs to delete for the `deleteAccount` remote function. Function will return true at success. 

```ballerina
string accountId = "001xa000003DIlo";
boolean|sfdc:Error isDeleted = baseClient->deleteAccount(accountId);
```

## Query Operations

The `getQueryResult` remote function executes a SOQL query that returns all the results in a single response or if it exceeds the maximum record limit, it returns part of the results and an identifier that can be used to retrieve the remaining results.


```ballerina
string sampleQuery = "SELECT name FROM Account";
SoqlResult|Error res = baseClient->getQueryResult(sampleQuery);
```


The response from `getQueryResult` is either a `SoqlResult` record with total size, execution status, resulting records, and URL to get the next record set (if query execution was successful) or Error (if the query execution was unsuccessful).


```ballerina
if (response is sfdc:SoqlResult) {
    io:println("TotalSize:  ", response.totalSize.toString());
    io:println("Done:  ", response.done.toString());
    io:println("Records: ", response.records.toString());
} else {
    io:println("Error: ", response.message());
}
```

If response has exceeded the maximum record limit, response will contain a key named ‘nextRecordsUrl’ and then the user can call `getNextQueryResult` remote function to get the next record set. 


```ballerina
sfdc:SoqlResult|sfdc:Error resp = baseClient->getNextQueryResult(<@untainted>nextRecordsUrl);
```

## Search Operations

The `searchSOSLString` remote function allows users to search using a string and returns all the occurrences of the string back to the user. SOSL searches are faster and can return more relevant results.


```
string searchString = "FIND {WSO2 Inc}";
sfdc:SoslResult|Error res = baseClient->searchSOSLString(searchString);
```
## Operations to get SObject Metadata

Ballerina Salesforce Connector facilitates users to retrieve SObject related information and metadata through Salesforce REST API. Following are the remote functions available for retrieving SObject metadata. 


<table>
  <tr>
   <td><strong>Remote Function</strong>
   </td>
   <td><strong>Description</strong>
   </td>
  </tr>
  <tr>
   <td>describeAvailableObjects
   </td>
   <td>Lists the available objects and their metadata for your organization and available to the logged-in user
   </td>
  </tr>
  <tr>
   <td>getSObjectBasicInfo
   </td>
   <td>Returns metadata of the specified SObject
   </td>
  </tr>
  <tr>
   <td>describeSObject
   </td>
   <td>Returns  metadata at all levels for the specified object including the fields, URLs, and child relationships
   </td>
  </tr>
  <tr>
   <td>sObjectPlatformAction
   </td>
   <td>Query for actions displayed in the UI, given a user, a context, device format, and a record ID
   </td>
  </tr>
</table>


## Operations to get Organizational Data

Apart from the main SObject related functions Ballerina Salesforce Connector facilitates users to get information about their organization. Following are the remote functions available for retrieving organizational data. 


<table>
  <tr>
   <td><strong>Remote Function</strong>
   </td>
   <td><strong>Description</strong>
   </td>
  </tr>
  <tr>
   <td>getAvailableApiVersions
   </td>
   <td>Use the <a href="https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_versions.htm">Versions</a> resource to list summary information about each REST API version currently available, including the version, label, and a link to each version's root
   </td>
  </tr>
  <tr>
   <td>getResourcesByApiVersion
   </td>
   <td>Use the <a href="https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_discoveryresource.htm">Resources by Version</a> resource to list the resources available for the specified API version. This provides the name and URI of each additional resource. Users need to provide API Version as a parameter to the function. 
   </td>
  </tr>
  <tr>
   <td>getOrganizationLimits
   </td>
   <td>Use the <a href="https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_limits.htm">Limits resource</a> to list your org limits. 
   </td>
  </tr>
</table>



## Bulk Operations 

Using the `createJob` remote function of the base client, we can create any type of job and of the data type JSON, XML and CSV. `createJob` remote function has four parameters.


1. Operation - INSERT, UPDATE, DELETE, UPSERT or QUERY
2. SObject type - Account, Contact, Opportunity etc.
3. Content Type - JSON, XML or CSV
4. ExternalIdFieldName (optional) - Field name of the external ID incase of an Upsert operation

Step by step implementation of an `insert` bulk operation has described below. Follow the same process for other operation types too. 

```ballerina
error|sfdc:BulkJob insertJob = baseClient->creatJob("insert", "Contact", "JSON");
```

Using the created job object, we can add a batch to it, get information about the batch and get all the batches of the job.


```ballerina
   json contacts = [
        {
            description: "Created_from_Ballerina_Sf_Bulk_API",
            FirstName: "Morne",
            LastName: "Morkel",
            Title: "Professor Grade 03",
            Phone: "0442226670",
            Email: "morne89@gmail.com"
        }
    ];
```

```ballerina
    //Add json content.
    error|sfdc:BatchInfo batch = baseClient->addBatch(insertJob, contacts);
```

```ballerina
    //Get batch info.
    error|sfdc:BatchInfo batchInfo = baseClient->getBatchInfo(insertJob, batch.id);
```

```ballerina
    //Get all batches.
    error|sfdc:BatchInfo[] batchInfoList = baseClient->getAllBatches(insertJob);
```

```ballerina
    //Get the batch request.
    var batchRequest = baseClient->getBatchRequest(insertJob, batchId);
```

```ballerina
    //Get the batch result.
    error|sdfc:Result[] batchResult = baseClient->getBatchResult(insertJob, batchId);
```


The `getJobInfo` remote function retrieves all details of an existing job.


```ballerina
   error|sfdc:JobInfo jobInfo = baseClient->getJobInfo(insertJob);
```


The `closeJob` and the `abortJob` remote functions close and abort the bulk job respectively. When a job is closed, no more batches can be added. When a job is aborted, no more records are processed. If changes to data have already been committed, they aren’t rolled back.


```ballerina
  error|sfdc:JobInfo closedJob = baseClient->closeJob(insertJob);
```


## Event Listener

The Listener which can be used to capture events on PushTopics defined in a Salesforce instance is configured as below.


```ballerina
sfdc:ListenerConfiguration listenerConfig = {
   username: config:getAsString("SF_USERNAME"),
   password: config:getAsString("SF_PASSWORD")
};
listener sfdc:Listener eventListener = new (listenerConfig);
```

In the above configuration, the password should be the concatenation of the user's Salesforce password and his secret key.

Now, a service has to be defined on the ‘eventListener’ like the following.


```ballerina
  @sfdc:ServiceConfig {
      topic:"/topic/QuoteUpdate"
  }
  service quoteUpdate on eventListener {
      resource function onEvent(json quoteUpdate) { 
          //convert JSON string to JSON     
          io:StringReader sr = new(quoteUpdate.toJsonString());
          json|error quote = sr.readJson();
          if (quote is json) {
              io:println("Quote Status : ", quote.sobject.Status);
          }
      }
  }
```


The above service is listening to the PushTopic `QuoteUpdate` defined in the Salesforce like the following.


```ballerina
   PushTopic pushTopic = new PushTopic();
   pushTopic.Name = 'QuoteUpdate';
   pushTopic.Query = 'SELECT Id, Name, AccountId, OpportunityId, Status,GrandTotal  FROM Quote';
   pushTopic.ApiVersion = 48.0;
   pushTopic.NotifyForOperationUpdate = true;
   pushTopic.NotifyForFields = 'Referenced';
   insert pushTopic;
```
# Samples

Please find the samples for above mentioned use cases through following links.

## [Samples for Salesforce REST API use cases](sfdc/samples/rest_api_usecases)  

These samples demonstrate the employment of Ballerina Salesforce Connector in Salesforce REST API related operations. The samples can be further divided as following
* Samples that can be used with any SObject's CRUD operations
* Samples for convenient access of Account, Contact, Product, Opportunity and Target SObjects's CRUD operations
* Samples for SOSL and SOQL related operations
* Samples for retrieving Organization and SObject metadata


## [Samples for Salesforce Bulk API use cases](sfdc/samples/bulk_api_usecases)

These samples demonstrate the employment of Ballerina Salesforce Connector in Salesforce BULK API related operations. Examples for bulk insert, bulk insert through files, bulk update, bulk upsert and bulk delete using json, csv or xml data sets are given here.

## [Samples for Event Listener](sfdc/samples/event_listener_usecases)

This sample demonstrates on capturing events using the Event Listener of Ballerina Salesforce Connector. As mentioned above to listen to a certin event users need to publish a pushtopic related to that event in his/her Salesforce instance. 


# Building from the Source


## Setting up the prerequisites


*   Download and install Java SE Development Kit (JDK) version 11 (from one of the following locations).
	[Oracle](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html),
	[OpenJDK](https://adoptopenjdk.net/)  

    **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed JDK.

*   Download and install[ Ballerina SL Alpha2](https://ballerina.io/).
*   Install Apache Maven  


## Building the Source

Execute the commands below to build from the source after installing the Ballerina SL Alpha2 version.


### To install the emp-wrapper :

```ballerina
   mvn clean install -pl emp-wrapper
```


### To build the library:

```ballerina
   bal build ./sfdc
```


### To build the module without the tests:

```
   bal build --skip-tests ./sfdc
```

## Contribution to Ballerina

As an open source project, Ballerina welcomes contributions from the community.  

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).  

## Code of Conduct

All the contributors are encouraged to read the Ballerina [Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful Links

* Discuss the code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Slack channel](https://ballerina.io/community/slack/).
* Post all technical questions on Stack Overflow with the [#ballerina tag](https://stackoverflow.com/questions/tagged/ballerina).


# References

Trailhead Salesforce Documentation -

[https://trailhead.salesforce.com/en/content/learn/modules/api_basics/api_basics_overview](https://trailhead.salesforce.com/en/content/learn/modules/api_basics/api_basics_overview)

Salesforce REST API Documentation -

[https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest)
