## Overview
Salesforce REST API provides CRUD operations for SObjects, query using SOQL, search using SOSL, and describe SObjects and organizational data.

This module supports [Salesforce v48.0 REST API](https://developer.salesforce.com/docs/atlas.en-us.224.0.api_rest.meta/api_rest/intro_what_is_rest_api.htm).

## Prerequisites
Before using this connector in your Ballerina application, complete the following:
1. Create [Salesforce account](https://developer.salesforce.com/signup)
2. Obtain tokens  
   - Client tokens - Follow the steps listed under [OAuth 2.0 Web Server Flow for Web App Integration](https://help.salesforce.com/articleView?id=sf.remoteaccess_oauth_web_server_flow.htm&type=5).
   - Listener tokens - Follow the steps listed under [Reset Your Security Token](https://help.salesforce.com/articleView?id=sf.user_security_token.htm&type=5) generate secret key and follow the steps listed under [Subscription Channels](https://developer.salesforce.com/docs/atlas.en-us.224.0.change_data_capture.meta/change_data_capture/cdc_subscribe_channels.htm) to subscribe channels. 

## Quickstart
To use the Salesforce connector in your Ballerina application, update the .bal file as follows:

#### Step 1: Import connector
Import the `ballerinax/salesforce` module into the Ballerina project.

```ballerina
import ballerinax/salesforce;
```

#### Step 2: Create a new connector instance
Create a `salesforce:ConnectionConfig` with the OAuth2 tokens obtained, and initialize the connector with it.
```ballerina
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;
configurable string refreshUrl = ?;
configurable string baseUrl = ?;

salesforce:ConnectionConfig sfConfig = {
    baseUrl: baseUrl,
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
    }
};

salesforce:Client baseClient = new(sfConfig);
```

#### Step 3: Invoke connector operation
1. Now you can use the operations available within the connector. Note that they are in the form of remote operations.  
Following is an example on how to create a record using the connector.

  ```ballerina
  record{} accountRecord = {
      "Name": "IT World",
      "BillingCity": "Colombo 1"
  };

  public function main() returns error? {
    salesforce:CreationResponse res = check baseClient->create("Account", accountRecord);
  }
  ```
2. Use `bal run` command to compile and run the Ballerina program.


**[You can find a list of samples here](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/master/examples/rest_api_usecases)**
