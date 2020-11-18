[![Build Status](https://travis-ci.org/ballerina-platform/module-ballerinax-sfdc.svg?branch=master)](https://travis-ci.org/ballerina-platform/module-ballerinax-sfdc)

# Module Salesforce

Connects to Salesforce from Ballerina. 

The Salesforce connector allows you to perform CRUD operations for SObjects, query using SOQL, search using SOSL, and
describe SObjects and organizational data through the Salesforce REST API. Also, it supports adding bulk data jobs and batches of types JSON, XML, and CSV via the Salesforce Bulk API. It handles OAuth 2.0 authentication.

**Base Client Operations**

The base client of the Salesforce connector takes the Salesforce configurations in and creates other clients such as the SObject client, Query client, and Bulk client. This also has some operations to retrieve available API versions and resources from Salesforce.

**SObject Operations**

The `ballerinax/sfdc` module contains operations related to standard and customized SObjects. It can get, create, update, and delete SObjects via SObject IDs.


**SOQL & SOSL Operations**

The `ballerinax/sfdc` module contains operations that query using SOQL and search using SOSL. This allows complex 
operations using SObjects relationships.

**Bulk Operations**

The `ballerinax/sfdc` module support bulk data operations for CSV, JSON, and XML data types.

**Event Listner**

The module includes a Listener that would capture events on PushTopics defined in a Salesforce instance. PushTopic
 events provide a way to receive notifications for changes to Salesforce data that match an SOQL query.

## Compatibility
|                     |    Version         |
|:-------------------:|:------------------:|
| Ballerina Language  | swan-lake-preview5 |
| Salesforce API      | v48.0              |

## Sample
First, import the `ballerinax/sfdc` module into the Ballerina project.
```ballerina
import ballerinax/sfdc;
```
Instantiate the connector by giving authentication details in the HTTP client config, which has built-in support for 
BasicAuth and OAuth 2.0. Salesforce uses OAuth 2.0 to authenticate and authorize requests. The Salesforce connector can 
be instantiated in the HTTP client config using the access token or using the client ID, client secret, and refresh 
token.

**Obtaining Tokens**

1. Visit [Salesforce](https://www.salesforce.com) and create a Salesforce Account.
2. Create a connected app and obtain the following credentials: 
    * Base URL (Endpoint)
    * Access Token
    * Client ID
    * Client Secret
    * Refresh Token
    * Refresh Token URL
    
3.  When you are setting up the connected app, select the following scopes under Selected OAuth Scopes:

    * Access and manage your data (api)
    * Perform requests on your behalf at any time (refresh_token, offline_access)
    * Provide access to your data via the Web (web)

4. Provide the client ID and client secret to obtain the refresh token and access token. For more information on 
   obtaining OAuth2 credentials, go to 
   [Salesforce documentation](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).

**Create the Salesforce Base client**

You can define the Salesforce configuration and create Salesforce base client as mentioned below. 
```ballerina
// Create Salesforce client configuration by reading from config file.
sfdc:SalesforceConfiguration sfConfig = {
    baseUrl: "<EP_URL>",
    clientConfig: {
        accessToken: "<ACCESS_TOKEN>",
        refreshConfig: {
            clientId: "<CLIENT_ID>",
            clientSecret: "<CLIENT_SECRET>",
            refreshToken: "<REFRESH_TOKEN>",
            refreshUrl: "<REFRESH_URL>"
        }
    }
};

// Create the Salesforce base client.
sfdc:BaseClient baseClient = new(sfConfig);
```

If you want to add your own key store to define the `secureSocketConfig`, change the Salesforce configuration as
mentioned below.
```ballerina
// Create Salesforce client configuration by reading from config file.
sfdc:SalesforceConfiguration sfConfig = {
    baseUrl: "<EP_URL>",
    clientConfig: {
        accessToken: "<ACCESS_TOKEN>",
        refreshConfig: {
            clientId: "<CLIENT_ID>",
            clientSecret: "<CLIENT_SECRET>",
            refreshToken: "<REFRESH_TOKEN>",
            refreshUrl: "<REFRESH_URL>"
        }
    },
    secureSocketConfig: {
        trustStore: {
            path: "<TRUSTSTORE_PATH>",
            password: "<TRUSTSTORE_PASSWORD>"
        }
    }
};
```

Using the base client, we can obtain the other clients.

```ballerina
sfdc:SObjectClient sobjectClient = baseClient->getSobjectClient();

sfdc:QueryClient queryClient = baseClient->getQueryClient();

sfdc:BulkClient bulkClient = baseClient->getBulkClient();
```

**SObject Client Operations**

The `createRecord` remote function of the SObject client creates an SObject record. Pass a JSON object with the relevant fields needed for 
the SObject and the SObject type.

```ballerina
json account = { Name: "ABC Inc", BillingCity: "New York" };

string|sfdc:Error createReponse = sobjectClient->createAccount(account);
```

The response from `createRecord` is either the string ID of the created record (if the record was created 
successfully) or `Error` (if the record creation was unsuccessful).

```ballerina
if (createReponse is string) {
    io:println("Account id: " + createReponse);
} else {
    io:println(createReponse.message());
}
```

**Query Client Operations**

The `getQueryResult` remote function of the Query client executes a SOQL query that returns all the results in a single response or if it 
exceeds the maximum record limit, it returns part of the results and an identifier that can be used to retrieve the 
remaining results.

```ballerina
string sampleQuery = "SELECT name FROM Account";

sfdc:SoqlResult|sfdc:Error response = queryClient->getQueryResult(sampleQuery);
```

The response from `getQueryResult` is either a SoqlResult record with total size, execution status, resulting records, 
and URL to get next record set (if query execution was successful) or `Error` (if the query execution 
was unsuccessful).

```ballerina
if (response is sfdc:SoqlResult) {
    io:println("TotalSize:  ", response.totalSize.toString());
    io:println("Done:  ", response.done.toString());
    io:println("Records: ", response.records.toString());
} else {
    io:println("Error: ", response.message());
}
```

**Bulk Client Operations**

Using the `createJob` remote function of the bulk client, we can create any type of job and of the data type JSON, XML and CSV. 

```ballerina
error|sfdc:BulkJob insertJob = bulkClient->creatJob("insert", "Contact", "JSON");
```
Using the created job object, we can add batch to it, get information about the batch and get all the batches of the job.

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

    //Add json content.
    error|sfdc:BatchInfo batch = insertJob->addBatch(contacts); 
```   

```ballerina
    //Get batch info.
    error|sfdc:BatchInfo batchInfo = insertJob->getBatchInfo(batch.id
``` 

```ballerina
    //Get all batches.
    error|sfdc:BatchInfo[] batchInfoList = insertJob->getAllBatches();
```

```ballerina
    //Get the batch request.
    var batchRequest = insertJob->getBatchRequest(batchId);
```

```ballerina
    //Get the batch result.
    error|sdfc:Result[] batchResult = insertJob->getBatchResult(batchId);
```

The `getJobInfo` remote function of the bulk client retrieves all details of an existing job.

```ballerina
    error|sfdc:JobInfo jobInfo = bulkClient->getJobInfo(insertJob);
```

The `closeJob` and the `abortJob` remote functions close and abort CSV insert job respectively. When a job is closed, no more 
batches can be added. When a job is aborted, no more records are processed. If changes to data have already been 
committed, they aren’t rolled back.

```ballerina
    error|sfdc:JobInfo closedJob = bulkClient->closeJob(insertJob);
```

**Listening to PushTopic Events**

The Listener is configured as below.

```ballerina
    sfdc:ListenerConfiguration listenerConfig = {
        username: config:getAsString("SF_USERNAME"),
        password: config:getAsString("SF_PASSWORD")
    };

    listener sfdc:Listener eventListener = new (listenerConfig);
```

In the above configuration, the password should be the concatenation of the user's Salesforce password and his secret
 key.
 
 Now, a service has to be defined on the `eventListener` like the following.
 
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

```
    PushTopic pushTopic = new PushTopic();
    pushTopic.Name = 'QuoteUpdate';
    pushTopic.Query = 'SELECT Id, Name, AccountId, OpportunityId, Status,GrandTotal  FROM Quote';
    pushTopic.ApiVersion = 48.0;
    pushTopic.NotifyForOperationUpdate = true;
    pushTopic.NotifyForFields = 'Referenced';
    insert pushTopic;
```
