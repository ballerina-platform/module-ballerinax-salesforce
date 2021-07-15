## Overview
Salesforce Bulk API is a specialized asynchronous RESTful API for loading and querying bulk of data at once. This module provides bulk data operations for CSV, JSON, and XML data types.

This module supports Salesforce Bulk API v1 version.
 
## Prerequisites
 
Before using this connector in your Ballerina application, complete the following:
- Create [Salesforce account](https://developer.salesforce.com/signup)
- Obtain tokens - Follow [this link](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm)

## Quickstart
To use the Salesforce connector in your Ballerina application, update the .bal file as follows:
### Step 1: Import connector
First, import the `ballerinax/sfdc` and `ballerinax/sfdc.bulk` modules into the Ballerina project.

```ballerina
import ballerinax/sfdc;
import ballerinax/sfdc.bulk;
```

### Step 2: Create a new connector instance
Create a `sfdc:SalesforceConfiguration` with the OAuth2 tokens obtained, and initialize the connector with it.
```ballerina

sfdc:SalesforceConfiguration sfConfig = {
   baseUrl: <"EP_URL">,
   clientConfig: {
     clientId: <"CLIENT_ID">,
     clientSecret: <"CLIENT_SECRET">,
     refreshToken: <"REFRESH_TOKEN">,
     refreshUrl: <"REFRESH_URL"> 
   }
};

bulk:Client bulkClient = new (sfConfig);
```

### Step 3: Invoke  connector operation

1. Now you can use the operations available within the connector. Note that they are in the form of remote operations.  
Following is an example on how to insert bulk contacts using the connector.
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

    public function main() returns error? {
        bulk:BulkJob insertJob = check bulkClient->createJob("insert", "Contact", "JSON");

        bulk:BatchInfo batch = check bulkClient->addBatch(insertJob, contacts);

    }
    ```

2. Use `bal run` command to compile and run the Ballerina program. 

## Quick reference
Code snippets of some frequently used functions: 

- Get batch information
    ```ballerina
    bulk:BatchInfo batchInfo = check bulkClient->getBatchInfo(insertJob, batch.id);
    ```

- Get all batches
    ```ballerina
    bulk:BatchInfo[] batchInfoList = check bulkClient->getAllBatches(insertJob);
    ```

- Get the batch request
    ```ballerina
    batchRequest = check bulkClient->getBatchRequest(insertJob, batchId);
    ```

- Get the batch result
    ```ballerina
    bulk:Result[] batchResult = check bulkClient->getBatchResult(insertJob, batchId);
    ```

- Retrieve all details of an existing job
    ```ballerina
   bulk:JobInfo jobInfo = check bulkClient->getJobInfo(insertJob);
    ```
- Close job  
    The `closeJob` and the `abortJob` remote functions close and abort the bulk job respectively. When a job is closed, no more batches can be added. When a job is aborted, no more records are processed. If changes to data have already been committed, they aren’t rolled back.

    ```ballerina
    bulk:JobInfo closedJob = check bulkClient->closeJob(insertJob);
    ```

**[You can find a list of samples here](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/master/sfdc/samples/bulk_api_usecases)**
