## Compatibility

| Ballerina Version  | API Version  |
| ------------------ | ------------ |
| 0.990.0            |   v37.0      |

### Prerequisites

Create a Salesforce developer account and create a connected app by visiting [Salesforce](https://www.salesforce.com) and obtain the following parameters:
* Base URl (Endpoint)
* Client Id
* Client Secret
* Access Token
* Refresh Token
* Refresh URL

IMPORTANT: This access token and refresh token can be used to make API requests on your own account's behalf. 
Do not share your access token, client secret with anyone.

Create an external id field under "Account" SObject, named with `"SF_ExternalID__c"` in your connected app. 
This field will be used in the test cases related with external id. 

Visit [here](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm) for more information on obtaining OAuth2 credentials.

### Working with Salesforce REST endpoint.

In order to use the Salesforce endpoint, first you need to create a 
Salesforce Client endpoint by passing above mentioned parameters.

Find the way of creating Salesforce endpoint as following. 

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

#### Running salesforce tests
Create `ballerina.conf` file in `module-salesforce`, with following keys:
* ENDPOINT
* ACCESS_TOKEN
* CLIENT_ID
* CLIENT_SECRET
* REFRESH_TOKEN
* REFRESH_URL

Assign relevant string values generated for Salesforce app. 

Go inside `module-salesforce` and give the command `ballerina init`using terminal and run test.bal file 
using `ballerina test sfdc37 --config ballerina.conf` command.

* Sample Test Function

```ballerina
@test:Config
function testGetResourcesByApiVersion() {
    log:printInfo("salesforceClient -> getResourcesByApiVersion()");
    string apiVersion = "v37.0";
    json|SalesforceConnectorError response = salesforceClient -> getResourcesByApiVersion(apiVersion);

    if (response is json) {
        test:assertNotEquals(response, null, msg = "Found null JSON response!");
        test:assertNotEquals(response["sobjects"], null);
        test:assertNotEquals(response["search"], null);
        test:assertNotEquals(response["query"], null);
        test:assertNotEquals(response["licensing"], null);
        test:assertNotEquals(response["connect"], null);
        test:assertNotEquals(response["tooling"], null);
        test:assertNotEquals(response["chatter"], null);
        test:assertNotEquals(response["recent"], null);
    } else {
        test:assertFail(msg = response.message);
    }
}

```

* Sample Result 

```ballerina
---------------------------------------------------------------------------
    T E S T S
---------------------------------------------------------------------------
---------------------------------------------------------------------------
Running Tests of module: sfdc37
---------------------------------------------------------------------------
...
2018-04-13 13:35:19,154 INFO  [sfdc37] - salesforceClient -> getResourcesByApiVersion() 
...
sfdc37............................................................. SUCCESS
---------------------------------------------------------------------------
```
