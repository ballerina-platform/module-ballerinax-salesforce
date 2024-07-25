## Overview

Salesforce Apex REST API enables you to expose your Apex classes and methods as RESTful web services. This module provides operations for executing custom Apex REST endpoints, allowing you to perform various HTTP operations on these endpoints and handle responses accordingly.

Ballerina Salesforce Apex REST API client supports the [Salesforce v59.0 APEX REST API](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_rest_intro.htm).

## Setup guide

1. Create a Salesforce account with the REST capability.

2. Go to Setup --> Apps --> App Manager 

   <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sfdc/master/docs/setup/resources/side-panel.png alt="Setup Side Panel" width="40%" style="border:1px solid #000000">

3. Create a New Connected App.

   <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sfdc/master/docs/setup/resources/create-connected-apps.png alt="Create Connected Apps" width="50%" style="border:1px solid #000000">

    - Here we will be using https://test.salesforce.com as we are using sandbox environment. Users can use https://login.salesforce.com for normal usage.

    <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sfdc/master/docs/setup/resources/create_connected%20_app.png alt="Create Connected Apps" width="100%" style="border:1px solid #000000">

4. After the creation user can get consumer key and secret through clicking on the `Manage Consumer Details` button.

   <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sfdc/master/docs/setup/resources/crdentials.png alt="Consumer Secrets" width="100%" style="border:1px solid #000000">

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

To use the Salesforce Apex client in your Ballerina application, update the .bal file as follows:

### Step 1: Import connector

Import the `ballerinax/salesforce.apex` module into the Ballerina project.

```ballerina
import ballerinax/salesforce.apex;
```

### Step 2: Create a new connector instance

Create a `ConnectionConfig` with the OAuth2 tokens obtained, and initialize the connector with it.
```ballerina
apex:ConnectionConfig sfConfig = {
    baseUrl: baseUrl,
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
    }
};

apex:Client apexClient = check new (sfConfig);
```

### Step 3: Invoke connector operation

1. Now you can use the operations available within the connector. Note that they are in the form of remote operations.
Following is an example of how to execute a custom Apex REST endpoint using the connector.

```ballerina
public function main() returns error? {
    string caseId = check apexClient->apexRestExecute("Cases", "POST",
        {
        "subject": "Item Fault!",
        "status": "New",
        "priority": "High"
    });
    return;
}
```

2. Use `bal run` command to compile and run the Ballerina program. 

## Examples

1. [Salesforce APEX REST API use cases](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/master/examples/apex_rest_api_usecases) - How to employ APEX REST API to create a case in Salesforce.
