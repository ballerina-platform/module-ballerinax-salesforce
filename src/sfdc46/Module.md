Connects to Salesforce from Ballerina. 

## Module Overview

The Salesforce connector allows you to perform CRUD operations for SObjects, query using SOQL, search using SOSL, and
describe SObjects and organizational data through the Salesforce REST API. Also it supports insert, upsert, update, 
query and delete operations for CSV, JSON and XML data types which provides in Salesforce bulk API. 
It handles OAuth 2.0 authentication.

## Compatibility
|                     |    Version     |
|:-------------------:|:--------------:|
| Ballerina Language  | 1.0.1          |
| Salesforce REST API | v46.0          |

## Supported Operations

**SObject Operations**

The `wso2/sfdc46` module contains operations to do CRUD operations for standard and customized SObjects. It can create, 
get, update, and delete SObjects via SObject IDs, and upsert via external IDs.

**SOQL & SOSL Operations**

The `wso2/sfdc46` module contains operations that query using SOQL and search using SOSL. This allows for complex 
operations using SObjects relationships.

**Describe Operations**

The `wso2/sfdc46` module contains operations that describe SObjects, organizational data, available resources, APIs, and 
limitations for organizations.

**Bulk Operations**

The `wso2/sfdc46` module contains insert, upsert, update, query and delete asynchronous bulk operations for CSV, JSON
and XML data types.

## Configuration

Instantiate the connector by giving authentication details in the HTTP client config, which has built-in support for 
BasicAuth and OAuth 2.0. Salesforce uses OAuth 2.0 to authenticate and authorize requests. The Salesforce connector can 
be instantiated in the HTTP client config using the access token or using the client ID, client secret, and refresh 
token.

**Obtaining Tokens**

1. Visit [Salesforce](https://www.salesforce.com) and create a Salesforce Account.
2. Create a connected app and obtain the following credentials: 
    * Base URL (Endpoint)
    * Access Token
    * Client ID
    * Client Secret
    * Refresh Token
    * Refresh Token URL
    
3.  When you are setting up the connected app, select the following scopes under Selected OAuth Scopes:

    * Access and manage your data (api)
    * Perform requests on your behalf at any time (refresh_token, offline_access)
    * Provide access to your data via the Web (web)

4. Provide the client ID and client secret to obtain the refresh token and access token. For more information on 
   obtaining OAuth2 credentials, go to 
   [Salesforce documentation](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).


## Sample

 
```ballerina
import ballerina/config;
import ballerina/http;
import ballerina/log;
import wso2/sfdc46;

// Create Salesforce client configuration by reading from config file.
sfdc46:SalesforceConfiguration sfConfig = {
    baseUrl: config:getAsString("EP_URL"),
    clientConfig: {
        accessToken: config:getAsString("ACCESS_TOKEN"),
        refreshConfig: {
            clientId: config:getAsString("CLIENT_ID"),
            clientSecret: config:getAsString("CLIENT_SECRET"),
            refreshToken: config:getAsString("REFRESH_TOKEN"),
            refreshUrl: config:getAsString("REFRESH_URL")
        }
    }
};

// Create salesforce client.
sfdc46:Client sfClient = new (sfConfig);

@http:ServiceConfig {
    basePath: "/salesforce"
}
service salesforceService on new http:Listener(9090) {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/account"
    }
    // Function to create a Account record.
    resource function createAccount(http:Caller caller, http:Request request) returns error? {
        // Define new response.
        http:Response backendResponse = new ();
        json payload = check request.getJsonPayload();
        // Get `Account` record.
        json account = {
            Name: payload.Name.toString(),
            BillingCity: payload.BillingCity.toString(),
            Website: payload.Website.toString()
        };

        // Invoke createAccount remote function from salesforce client.
        string response = check sfClient->createAccount(<@untainted>account);

        json resPayload = { accountId: response };
        respondAndHandleError(caller, http:STATUS_OK, <@untainted> resPayload);
    }
}

// Send the response back to the client and handle responding errors.
function respondAndHandleError(http:Caller caller, int resCode, json | xml | string payload) {
    http:Response res = new;
    res.statusCode = resCode;
    res.setPayload(payload);
    var respond = caller->respond(res);
    if (respond is error) {
        log:printError("Error occurred while responding", err = respond);
    }
}
```
