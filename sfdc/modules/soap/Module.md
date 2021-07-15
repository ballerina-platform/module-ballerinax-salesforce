## Overview
Ballerina Salesforce [SOAP](https://developer.salesforce.com/docs/atlas.en-us.224.0.api.meta/api/sforce_api_quickstart_intro.html) connector is connecting Salesforce SOAP API and performs operations like create, retrieve, update or delete records, such as accounts, leads, and custom objects with more than 20 different calls, SOAP API also allows you to maintain passwords, perform searches, and much more.`
This module supports Salesforce 48.0 version Enterprise WDSL.
 
## Prerequisites

Before using this connector in your Ballerina application, complete the following:
- Create [Salesforce account](https://developer.salesforce.com/signup)
- Obtain tokens - Follow [this link](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm)

## Quickstart
To use the Salesforce connector in your Ballerina application, update the .bal file as follows:

### Step 1: Import connector
First, import the `ballerinax/sfdc` and `ballerinax/sfdc.soap` modules into the Ballerina project.

```ballerina
import ballerinax/sfdc;
import ballerinax/sfdc.soap;
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

soap:Client soapClient = new(sfConfig);
```

### Step 3: Invoke connector operation
1. Now you can use the operations available within the connector. Note that they are in the form of remote operations.  
Following is an example on how to convert lead using the connector.
    ```ballerina
    public function main() returns error? {
      ConvertedLead response = check soapClient->convertLead(leadId);
    }
    ```
2. Use `bal run` command to compile and run the Ballerina program. 
