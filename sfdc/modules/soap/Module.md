## Overview
Ballerina Connector for Salesforce [SOAP API](https://developer.salesforce.com/docs/atlas.en-us.224.0.api.meta/api/sforce_api_quickstart_intro.html) is connecting Salesforce SOAP API operations like create, retrieve, update or delete records, such as accounts, leads, and custom objects. With more than 20 different calls, SOAP API also allows you to maintain passwords, perform searches, and much more.`

This module supports Salesforce 48.0 version.
 
## Obtaining tokens
This is similar to default module. You can refer default module [documentation](https://docs.central.ballerina.io/ballerinax/sfdc/latest).

## Quickstart

### Step 1: Import Ballerina Salesforce SOAP module
First, import the `ballerinax/sfdc`, `ballerinax/sfdc.soap` module into the Ballerina project.

```ballerina
import ballerinax/sfdc;
import ballerinax/sfdc.soap;
```

### Step 2: Create the Salesforce client
Create Salesforce SOAP client configuration by reading from config file.

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

soap:Client soapClient = new (sfConfig);
```

### Step 3: Implement operations
```ballerina
ConvertedLead|error response = soapClient->convertLead(leadId);
// lead is converted.
```