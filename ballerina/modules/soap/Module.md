## Overview
Salesforce SOAP API provides CRUD operations for SObjects and allows you to maintain passwords, perform searches, and much more.

This module supports [Salesforce v48.0 SOAP API Enterprise WDSL](https://developer.salesforce.com/docs/atlas.en-us.224.0.api.meta/api/sforce_api_quickstart_intro.htm).
 
## Prerequisites

Before using this connector in your Ballerina application, complete the following:
1. Create [Salesforce account](https://developer.salesforce.com/signup)
2. Obtain tokens - Follow the steps listed under [OAuth 2.0 Web Server Flow for Web App Integration](https://help.salesforce.com/articleView?id=sf.remoteaccess_oauth_web_server_flow.htm&type=5).

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
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;
configurable string refreshUrl = ?;
configurable string baseUrl = ?;

soap:ConnectionConfig sfConfig = {
    baseUrl: baseUrl,
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
    }
};

soap:Client soapClient = new(sfConfig);
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

**[You can find a sample here](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/master/examples/soap_api_usecases)**