## Package overview

Salesforce Sales Cloud is one of the leading Customer Relationship Management(CRM) software, provided by Salesforce.Inc. Salesforce enable users to efficiently manage sales and customer relationships through its APIs, robust and secure databases, and analytics services. Sales cloud provides serveral API packages to make operations on sObjects and metadata, execute queries and searches, and listen to change events through API calls using REST, SOAP, and CometD protocols. 

Ballerina Salesforce connector supports [Salesforce v59.0 REST API](https://developer.salesforce.com/docs/atlas.en-us.224.0.api_rest.meta/api_rest/intro_what_is_rest_api.htm), [Salesforce v59.0 SOAP API](https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_quickstart_intro.htm), [Salesforce v59.0 APEX REST API](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_rest_intro.htm), [Salesforce v59.0 BULK API](https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/api_asynch_introduction_bulk_api.htm), and [Salesforce v59.0 BULK V2 API](https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/bulk_api_2_0.htm).

## Setup guide

1. Create a Salesforce account with the REST capability.

2. Go to Setup --> Apps --> App Manager 
  ![Setup Side Panel](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sfdc/revamp-2023/docs/side-panel.png)

3. Create a New Connected App
![Create Connected Apps](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sfdc/revamp-2023/docs/create-connected-apps.png)
  - Here we will be using https://test.salesforce.com as we are using sandbox enviorenment. Users can use https://login.salesforce.com for normal usage
  ![Create Connected Apps](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sfdc/revamp-2023/docs/create_connected%20_app.png)

4. After the creation user can get consumer key and secret through clicking on the `Manage Consume Details` button.
![Consumer Secrets](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sfdc/revamp-2023/docs/crdentials.png)

5. Next step would be to get the token.
  - Log in to salesforce in your prefered browser and enter the following url 
  `https://<YOUR_INSTANCE>.salesforce.com/services/oauth2/authorize?response_type=code&client_id=<CONSUMER_KEY>&redirect_uri=<REDIRECT_URL>`
  - Allow access if an alert pops up and the browser will be redirected to a Url like follows.
  `https://login.salesforce.com/?code=<ENCODED_CODE>`
  - the code can be obtained after decoding the encoded code

6. Get Access and Refresh tokens
 - following request can be sent to obtain the tokens
 ```curl -X POST https://<YOUR_INSTANCE>.salesforce.com/services/oauth2/token?code=<CODE>&grant_type=authorization_code&client_id=<CONSUMER_KEY>&client_secret=<CONSUMER_SECRET>&redirect_uri=https://test.salesforce.com/``` 
 - tokens can be obtaind from the response

## Prerequisites

Before using this connector in your Ballerina application, complete the following:

1. Create [Salesforce account](https://developer.salesforce.com/signup)

2. Obtain tokens  
   - Client tokens - Follow the steps listed under [OAuth 2.0 Web Server Flow for Web App Integration](https://help.salesforce.com/articleView?id=sf.remoteaccess_oauth_web_server_flow.htm&type=5).
   - Listener tokens - Follow the steps listed under [Reset Your Security Token](https://help.salesforce.com/articleView?id=sf.user_security_token.htm&type=5) generate secret key and follow the steps listed under [Subscription Channels](https://developer.salesforce.com/docs/atlas.en-us.224.0.change_data_capture.meta/change_data_capture/cdc_subscribe_channels.htm) to subscribe channels. 

## Quickstart

To use the Salesforce connector in your Ballerina application, modify the .bal file as follows:

#### Step 1: Import connector

Import the `ballerinax/salesforce` package into the Ballerina project.

```ballerina
import ballerinax/salesforce;
```

#### Step 2: Create a new connector instance

Create a `salesforce:ConnectionConfig` with the obtained OAuth2 tokens and initialize the connector with it.
```ballerina
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

1. Now you can utilize the available operations. Note that they are in the form of remote operations.  

Following is an example on how to create a record using the connector.

  ```ballerina
  record{} accountRecord = {
      "Name": "IT World",
      "BillingCity": "Colombo 1"
  };

    salesforce:CreationResponse res = check 
      baseClient->create("Account", accountRecord);

  ```

2. Use `bal run` command to compile and run the Ballerina program.

## Examples

The `salesforce` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/master/examples), covering use cases like creation of  record, retrieving records, and managing describe sObjects.

1. [REST API examples](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/master/examples/rest_api_usecases) - Contains examples for the salesforce REST API usescases.

2. [SOAP API examples](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/master/examples/soap_api_usecases) - Contains examples for the salesforce SOAP API usescases.

3. [BULK API examples](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/master/examples/bulk_api_usecases) - Contains examples for the salesforce Bulk API usescases.

4. [BULKV2 API examples](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/master/examples/bulkv2_api_usecases) - Contains examples for the salesforce Bulk V2 API usescases.

5. [APEX REST API examples](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/master/examples/apex_rest_api_usecases) - Contains examples for the salesforce APEX REST API usescases.

## Report Issues

To report bugs, request new features, start new discussions, view project boards, etc., go to the [Ballerina library parent repository](https://github.com/ballerina-platform/ballerina-library).

## Useful Links

- Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
- Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
