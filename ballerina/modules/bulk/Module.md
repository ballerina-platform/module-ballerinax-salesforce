## Overview
Salesforce Bulk API is a specialized asynchronous RESTful API for loading and querying bulk of data at once. This module provides bulk data operations for CSV, JSON, and XML data types.

This module supports [Salesforce Bulk API v1](https://developer.salesforce.com/docs/atlas.en-us.224.0.api_asynch.meta/api_asynch/asynch_api_reference.htm).
 
## Prerequisites
 
Before using this connector in your Ballerina application, complete the following:
1. Create [Salesforce account](https://developer.salesforce.com/signup)
2. Obtain tokens - Follow the steps listed under [OAuth 2.0 Web Server Flow for Web App Integration](https://help.salesforce.com/articleView?id=sf.remoteaccess_oauth_web_server_flow.htm&type=5).

## Quickstart
To use the Salesforce connector in your Ballerina application, update the .bal file as follows:
### Step 1: Import connector
Import the `ballerinax/salesforce.bulk` module into the Ballerina project.

```ballerina
import ballerinax/salesforce.bulk;
```

### Step 2: Create a new connector instance
Create a `ConnectionConfig` with the OAuth2 tokens obtained, and initialize the connector with it.
```ballerina

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;
configurable string refreshUrl = ?;
configurable string baseUrl = ?;

bulk:ConnectionConfig sfConfig = {
    baseUrl: baseUrl,
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
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

**[You can find a list of samples here](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/master/examples/bulk_api_usecases)**
