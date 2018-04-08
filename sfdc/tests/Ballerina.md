## Compatibility

| Ballerina Version         | Connector Version         | API Version |
| ------------------------- | ------------------------- | ------------|
|  0.970.0-alpha1-SNAPSHOT  | 0.970.0-alpha1-SNAPSHOT   |   v37.0     |

### Prerequisites
Create a Salesforce developer account and create a connected app by visiting Salesforce (https://www.salesforce.com) and obtain the following parameters:
* Base URl (Endpoint)
* Client Id
* Client Secret
* Access Token
* Refresh Token
* Refresh Token Endpoint
* Refresh Token Path

IMPORTANT: This access token and refresh token can be used to make API requests on your own account's behalf. Do not share your access token, client secret with anyone.

Visit [here](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm) for more information on obtaining OAuth2 credentials.

### Working with Salesforce REST connector.

In order to use the Salesforce connector, first you need to create a SalesforceConnector endpoint by passing above mentioned parameters.

Visit `test.bal` file to find the way of creating Salesforce endpoint.
#### Salesforce struct
```ballerina
public struct SalesforceConnector {
    oauth2:OAuth2Endpoint oauth2EP;
}
```
#### Salesforce Endpoint
```ballerina
public struct SalesforceEndpoint {
    SalesforceConfiguration salesforceConfig;
    SalesforceConnector salesforceConnector;
}
```

#### init() function
```ballerina
public function <SalesforceEndpoint ep> init (SalesforceConfiguration salesforceConfig) {
    endpoint oauth2:OAuth2Endpoint oauth2Endpoint {
        baseUrl:salesforceConfig.oauth2Config.baseUrl,
        accessToken:salesforceConfig.oauth2Config.accessToken,
        clientConfig:{},
        refreshToken:salesforceConfig.oauth2Config.refreshToken,
        clientId:salesforceConfig.oauth2Config.clientId,
        clientSecret:salesforceConfig.oauth2Config.clientSecret,
        refreshTokenEP:salesforceConfig.oauth2Config.refreshTokenEP,
        refreshTokenPath:salesforceConfig.oauth2Config.refreshTokenPath,
        useUriParams:true
    };

    ep.salesforceConnector = {
                                 oauth2EP:oauth2Endpoint
                             };
}
```
#### Running salesforce tests
Create `ballerina.conf` file in `package-salesforce`, with following keys:
* ENDPOINT
* ACCESS_TOKEN
* CLIENT_ID
* CLIENT_SECRET
* REFRESH_TOKEN
* REFRESH_TOKEN_ENDPOINT
* REFRESH_TOKEN_PATH

Assign relevant string values generated for Salesforce app. 

Go inside `package-salesforce` using terminal and run test.bal file using following command `ballerina test salesforce`.
