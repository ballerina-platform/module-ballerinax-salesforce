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
    oauth2:OAuth2Connector oauth2;
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
    oauth2:OAuth2Configuration oAuth2Configuration = salesforceConfig.oauth2Config;
    oauth2:OAuth2Connector oAuth2Connector = {accessToken:oAuth2Configuration.accessToken,
                                          refreshToken:oAuth2Configuration.refreshToken,
                                          clientId:oAuth2Configuration.clientId,
                                          clientSecret:oAuth2Configuration.clientSecret,
                                          refreshTokenEP:oAuth2Configuration.refreshTokenEP,
                                          refreshTokenPath:oAuth2Configuration.refreshTokenPath,
                                          useUriParams:oAuth2Configuration.useUriParams,
                                          httpClient:http:createHttpClient(oAuth2Configuration.baseUrl, oAuth2Configuration.clientConfig)};
    ep.salesforceConnector = {oauth2:oAuth2Connector};
}
```
#### Running the tests
Go to `ballerina.conf` file in `package-salesforce`, replace  Endpoint, Client Id, Client Secret, Access Token, Refresh Token, Refresh Token Endpoint and Refresh Token Path string values with your data. 

Go inside `package-salesforce` using terminal and run test.bal file using following command `ballerina test tests`.
