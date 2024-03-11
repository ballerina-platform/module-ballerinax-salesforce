## Overview
Salesforce SOAP API provides CRUD operations for SObjects and allows you to maintain passwords, perform searches, and much more.

This module supports [Salesforce v48.0 SOAP API Enterprise WDSL](https://developer.salesforce.com/docs/atlas.en-us.224.0.api.meta/api/sforce_api_quickstart_intro.htm).
 
## Setup guide

1. Create a Salesforce account with the REST capability.

2. Go to Setup --> Apps --> App Manager 

   <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-salesforce/master/docs/setup/resources/side-panel.png alt="Setup Side Panel" width="40%" style="border:1px solid #000000">

3. Create a New Connected App.

   <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-salesforce/master/docs/setup/resources/create-connected-apps.png alt="Create Connected Apps" width="50%" style="border:1px solid #000000">

    - Here we will be using https://test.salesforce.com as we are using sandbox enviorenment. Users can use https://login.salesforce.com for normal usage.

    <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-salesforce/master/docs/setup/resources/create_connected%20_app.png alt="Create Connected Apps" width="100%" style="border:1px solid #000000">

4. After the creation user can get consumer key and secret through clicking on the `Manage Consume Details` button.

   <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-salesforce/master/docs/setup/resources/crdentials.png alt="Consumer Secrets" width="100%" style="border:1px solid #000000">

5. Next step would be to get the token.
    - Log in to salesforce in your prefered browser and enter the following url.
  `https://<YOUR_INSTANCE>.salesforce.com/services/oauth2/authorize?response_type=code&client_id=<CONSUMER_KEY>&redirect_uri=<REDIRECT_URL>`
   - Allow access if an alert pops up and the browser will be redirected to a Url like follows.
  `https://login.salesforce.com/?code=<ENCODED_CODE>`
  
   - The code can be obtained after decoding the encoded code

6. Get Access and Refresh tokens
   - Following request can be sent to obtain the tokens
 ```curl -X POST https://<YOUR_INSTANCE>.salesforce.com/services/oauth2/token?code=<CODE>&grant_type=authorization_code&client_id=<CONSUMER_KEY>&client_secret=<CONSUMER_SECRET>&redirect_uri=https://test.salesforce.com/``` 
   - Tokens can be obtained from the response.

## Quickstart
To use the Salesforce connector in your Ballerina application, update the .bal file as follows:

### Step 1: Import connector
Import the `ballerinax/salesforce.soap` module into the Ballerina project.

```ballerina
import ballerinax/salesforce.soap;
```

### Step 2: Create a new connector instance
Create a `soap:ConnectionConfig` with the OAuth2 tokens obtained, and initialize the connector with it.

```ballerina

soap:ConnectionConfig config = {
    baseUrl: baseUrl,
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
    }
};

soap:Client salesforce = new(sfConfig);
```

### Step 3: Invoke connector operation
1. Now you can use the operations available within the connector. Note that they are in the form of remote operations.  
Following is an example on how to convert lead using the connector.
  ```ballerina
  public function main() returns error? {
    soap:ConvertedLead response = check soapClient->convertLead({leadId = "xxx", convertedStatus: "Closed - Converted"});
  }
  ```
2. Use `bal run` command to compile and run the Ballerina program. 

**[You can find a sample here](https://github.com/ballerina-platform/module-ballerinax-salesforce/tree/master/examples/soap_api_usecases)**