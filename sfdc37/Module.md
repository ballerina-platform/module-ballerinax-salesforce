Connects to Salesforce from Ballerina. 

# Module Overview

The Salesforce connector allows you to perform CRUD operations for SObjects, query using SOQL, search using SOSL, and
describe SObjects and organizational data through the Salesforce REST API. It handles OAuth 2.0 authentication.

**SObject Operations**

The `wso2/sfdc37` module contains operations to do CRUD operations for standard and customized SObjects. It can create, 
get, update, and delete SObjects via SObject IDs, and upsert via external IDs.

**SOQL & SOSL Operations**

The `wso2/sfdc37` module contains operations that query using SOQL and search using SOSL. This allows for complex 
operations using SObjects relationships.

**Describe Operations**

The `wso2/sfdc37` module contains operations that describe SObjects, organizational data, available resources, APIs, and 
limitations for organizations.

## Compatibility
|                     |    Version     |
|:-------------------:|:--------------:|
| Ballerina Language  | 0.990.0        |
| Salesforce REST API | v37.0          |

## Sample
First, import the `wso2/sfdc37` module into the Ballerina project.
```ballerina
import wso2/sfdc37;
```
Instantiate the connector by giving authentication details in the HTTP client config, which has built-in support for 
BasicAuth and OAuth 2.0. Salesforce uses OAuth 2.0 to authenticate and authorize requests. The Salesforce connector can 
be instantiated in the HTTP client config using the access token or using the client ID, client secret, and refresh 
token. Give the scheme of the HTTP client config as “oauth” and provide the base URL and refresh token URL.

**Obtaining Tokens to Run the Sample**

1. Visit [Salesforce](https://www.salesforce.com) and create a Salesforce Account.
2. Create a connected app and obtain the following credentials: 
    * Base URL (Endpoint)
    * Client ID
    * Client Secret
    * Refresh Token URL

3. Provide the client ID and client secret to obtain the refresh token and access token. Visit 
[here](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm) for more information 
on obtaining OAuth2 credentials.

You can now enter the credentials in the HTTP client config. 
```ballerina
SalesforceConfiguration salesforceConfig = {
    baseUrl: endpointUrl,
    clientConfig: {
        auth: {
            scheme: http:OAUTH2,
            accessToken: accessToken,
            refreshToken: refreshToken,
            clientId: clientId,
            clientSecret: clientSecret,
            refreshUrl: refreshUrl
        }
    }
};

Client salesforceClient = new(salesforceConfig);

```
The `createAccount` function creates an Account SObject. Pass a JSON object with the relevant fields needed for the 
SObject Account.
```ballerina
json account = {Name:"ABC Inc", BillingCity:"New York"};
var createReponse = salesforceEP->createAccount(account);
```
The response from `createAccount` is either a string ID of the created account (if the account was created successfully) 
or a `SalesforceConnectorError` (if the account creation was unsuccessful). The `match` operation can be used to handle 
the response if an error occurs.
```ballerina
if (createReponse is string) {
    io:println("Account id:  " + createReponse);
} else {
    io:println(createReponse.message);
}
```
The `getQueryResult` function executes a SOQL query that returns all the results in a single response, or, if it exceeds 
the maximum record limit, it returns part of the results and an identifier used to retrieve the remaining results.
```ballerina
string sampleQuery = "SELECT name FROM Account";
response = salesforceEP->getQueryResult(sampleQuery);
```
The response from `getQueryResult` is either a JSON object with total size, execution status, resulting records, and 
URL to get next record set (if query execution was successful) or a `SalesforceConnectorError` 
(if the query execution was unsuccessful). The `match` operation can be used to handle the response if an error occurs.
```ballerina
if (response is json) {
    io:println(“TotalSize:  ” + response["totalSize"]);
    io:println(“Done:  ” + response["done"]);
    io:println(“Records:  ” + response["records"]);
    io:println(“Next response url:”  + response["nextRecordsUrl"]);
} else {
    io:println(response.message);
}
```
The `createLead` function creates a Lead SObject. It returns the lead ID if successful or `SalesforceConnectorError` if 
unsuccessful.
```ballerina
json lead = {LastName:"Carmen", Company:"WSO2", City:"New York"};
var createResponse = salesforceEP->createLead(lead);
if (createResponse is string) {
    io:println("Lead id: " + createResponse);
} else {
    io:println(createResponse.message);
}
```


