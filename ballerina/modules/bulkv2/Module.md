## Overview

Salesforce Bulk API 2.0 enables you to handle large data sets asynchronously, optimizing performance for high-volume data operations. This module provides operations for executing bulk jobs and batches, allowing you to perform various data operations efficiently.

## Setup guide

1. Create a Salesforce Account with the Bulk API 2.0 Capability.

2. Go to Setup --> Apps --> App Manager

   <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-salesforce/master/docs/setup/resources/side-panel.png alt="Setup Side Panel" width="40%" style="border:1px solid #000000">

3. Create a New Connected App.

   <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-salesforce/master/docs/setup/resources/create-connected-apps.png alt="Create Connected Apps" width="50%" style="border:1px solid #000000">

    - Here we will be using https://test.salesforce.com as we are using sandbox environment. Users can use https://login.salesforce.com for normal usage.

    <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-salesforce/master/docs/setup/resources/create_connected%20_app.png alt="Create Connected Apps" width="100%" style="border:1px solid #000000">

4. After the creation user can get consumer key and secret through clicking on the `Manage Consumer Details` button.

   <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-salesforce/master/docs/setup/resources/crdentials.png alt="Consumer Secrets" width="100%" style="border:1px solid #000000">

5. The next step is to get the token.

    - Log in to Salesforce in your preferred browser and enter the following URL:
      `https://<YOUR_INSTANCE>.salesforce.com/services/oauth2/authorize?response_type=code&client_id=<CONSUMER_KEY>&redirect_uri=<REDIRECT_URL>`
    - Allow access if an alert pops up, and the browser will be redirected to a URL like the following:
      `https://login.salesforce.com/?code=<ENCODED_CODE>`

    - The code can be obtained after decoding the encoded code

6. Get Access and Refresh tokens

    - The following request can be sent to obtain the tokens.
      ```curl -X POST https://<YOUR_INSTANCE>.salesforce.com/services/oauth2/token?code=<CODE>&grant_type=authorization_code&client_id=<CONSUMER_KEY>&client_secret=<CONSUMER_SECRET>&redirect_uri=https://test.salesforce.com/```
    - Tokens can be obtained from the response.

## Quickstart

To use the Salesforce Bulk API client in your Ballerina application, update the .bal file as follows:

#### Step 1: Import connector

Import the `ballerinax/salesforce.bulkv2` package into the Ballerina project.

```ballerina
import ballerinax/salesforce.bulkv2;
```

#### Step 2: Create a new connector instance

Create a `salesforce:ConnectionConfig` with the obtained OAuth2 tokens and initialize the connector with it.
```ballerina
bulkv2:ConnectionConfig config = {
    baseUrl: baseUrl,
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
    }
};

bulkv2:Client bulkv2Client = check new (config);
```

#### Step 3: Invoke connector operation

1. Now you can use the operations available within the connector. Note that they are in the form of remote operations.

Following is an example of how to create a bulk job using the connector.

```ballerina
bulkv2:BulkCreatePayload payload = {
    'object: "Contact",
    contentType: "CSV",
    operation: "insert",
    lineEnding: "LF"
};
bulkv2:BulkJob insertJob = check baseClient->createIngestJob(payload);
```

2. Use following command to compile and run the Ballerina program.

```
bal run
````

## Examples

1. [Salesforce Bulk v2 API use cases](https://github.com/ballerina-platform/module-ballerinax-salesforce/tree/master/examples/bulkv2_api_usecases) - How to employ Bulk v2 API to execute an ingest job.
