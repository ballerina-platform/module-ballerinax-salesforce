## Overview
The Salesforce connector allows users to perform CRUD operations for SObjects, query using SOQL, search using SOSL, and describe SObjects and organizational data through the Salesforce REST API. Apart from these functionalities, Ballerina Salesforce Connector includes a listener to capture events.

This module supports [Salesforce v48.0 REST API](https://developer.salesforce.com/docs/atlas.en-us.224.0.api_rest.meta/api_rest/intro_what_is_rest_api.htm).


## Prerequisites
Before using this connector in your Ballerina application, complete the following:
1. Create [Salesforce account](https://developer.salesforce.com/signup)
2. Obtain tokens  
   - Client tokens - Follow the steps listed under [OAuth 2.0 Web Server Flow for Web App Integration](https://help.salesforce.com/articleView?id=sf.remoteaccess_oauth_web_server_flow.htm&type=5).
   - Listener tokens - Follow the steps listed under [Reset Your Security Token](https://help.salesforce.com/articleView?id=sf.user_security_token.htm&type=5) generate secret key and follow the steps listed under [Subscription Channels](https://developer.salesforce.com/docs/atlas.en-us.224.0.change_data_capture.meta/change_data_capture/cdc_subscribe_channels.htm) to subscribe channels. 

## Quickstart
To use the Salesforce connector in your Ballerina application, update the .bal file as follows:

### Client
#### Step 1: Import connector
Import the `ballerinax/sfdc` module into the Ballerina project.

```ballerina
import ballerinax/sfdc;
```

#### Step 2: Create a new connector instance
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

sfdc:Client baseClient = new(sfConfig);
```

#### Step 3: Invoke connector operation
1. Now you can use the operations available within the connector. Note that they are in the form of remote operations.  
Following is an example on how to create a record using the connector.

    ```ballerina
    json accountRecord = {
      Name: "John Keells Holdings",
      BillingCity: "Colombo 3"
    };

    public function main() returns error? {
      string recordId = check baseClient->createRecord("Account", accountRecord);
    }
    ```
2. Use `bal run` command to compile and run the Ballerina program.

### Listener
#### Step 1: Import connector
Import the `ballerinax/sfdc` module into the Ballerina project.

```ballerina
import ballerinax/sfdc;
```
#### Step 2: Create a new connector listener instance
Create a `sfdc:ListenerConfiguration` with the basic credentials obtained, and initialize the connector with it.
The password should be the concatenation of the user's Salesforce password and secret key.

  ```ballerina
  sfdc:ListenerConfiguration listenerConfig = {
    username: config:getAsString("SF_USERNAME"),
    password: config:getAsString("SF_PASSWORD")
  };
  listener sfdc:Listener eventListener = new (listenerConfig);
  ```
#### Step 3: Invoke listener service
1. Now you can use the channel available in the Salesforce and capture the events occurred.  
Following is an example on how to capture all events using the connector.

    ```ballerina
    @sfdc:ServiceConfig {
        channelName:"/data/ChangeEvents"
    }
    service /quoteUpdate on eventListener {
        remote function onUpdate (sfdc:EventData quoteUpdate) { 
            json quote = quoteUpdate.changedData.get("Status");
        }
    }
    ```
  2. Use `bal run` command to compile and run the Ballerina program.


**[You can find a list of samples here](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/master/sfdc/samples/rest_api_usecases)**
