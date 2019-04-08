[![Build Status](https://travis-ci.org/wso2-ballerina/module-salesforce.svg?branch=master)](https://travis-ci.org/wso2-ballerina/module-salesforce)

# Salesforce Connector

The Salesforce connector allows you to perform CRUD operations for SObjects, query using SOQL, search using SOSL, and
describe SObjects and organizational data through the Salesforce REST API. It handles OAuth 2.0 authentication.

## Compatibility

| Ballerina Version  | API Version  |
| ------------------ | ------------ |
| 0.991.0            |   v37.0      |
 

## Getting started

1. Refer to [Getting Started guide](https://ballerina.io/learn/getting-started/) to download and install Ballerina.

2. Create a Salesforce account and create a connected app by visiting [Salesforce](https://www.salesforce.com) 
and obtain the following parameters:
* Base URl (Endpoint)
* Client Id
* Client Secret
* Access Token
* Refresh Token
* Refresh URL

IMPORTANT: This access token and refresh token can be used to make API requests on your own account's behalf. 
Do not share your access token, client secret with anyone.

Visit [here](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm) 
for more information on obtaining OAuth2 credentials.

3. Create a new Ballerina project by executing the following command.

   ```shell
   <PROJECT_ROOT_DIRECTORY>$ ballerina init
   ```

4. Working with Salesforce REST connector.

All the actions return JSON or sfdc37:SalesforceConnectorError. If the action is a success, 
then result (non-empty) JSON will be returned while the sfdc37:SalesforceConnectorError will be null and vice-versa.

You can import the Salesforce module(sfdc37) to your Ballerina program as follows.

```ballerina
import wso2/sfdc37;
```

##### Example
 * Request

```ballerina
import ballerina/http;
import ballerina/io;
import wso2/sfdc37;

//User credentials to access Salesforce API
string url = "<base_url>";
string accessToken = "<access_token>";
string refreshToken = "<refresh_token>";
string clientId = "<client_id>";
string clientSecret = "<client_secret>";
string refreshUrl = "<refreshUrl>";
string endpointUrl = "<endpointUrl>";

sfdc37:SalesforceConfiguration salesforceConfig = {
    baseUrl: endpointUrl,
    clientConfig: {
       auth: {
           scheme: http:OAUTH2,
           config: {
               grantType: http:DIRECT_TOKEN,
               config: {
                   accessToken: accessToken,
                   refreshConfig: {
                       refreshUrl: refreshUrl,
                       refreshToken: refreshToken,
                       clientId: clientId,
                       clientSecret: clientSecret
                   }
               }
           }
       }
    }
};

sfdc37:Client salesforceClient = new(salesforceConfig);

public function main() {

    // Call the `getAvailableApiVersions()` remote function of the Salesforce connector.
    json|sfdc37:SalesforceConnectorError response = salesforceClient->getAvailableApiVersions();

    if (response is json) {
        // If successful, print the JSON result
        io:println("Available API versions: ", response);
    } else {
        // If unsuccessful, print the error of type `sfdc37:SalesforceConnectorError`
        io:println("Error: ", response.message);
    }
}
```

* Response

JSON response or SalesforceConnectorError
