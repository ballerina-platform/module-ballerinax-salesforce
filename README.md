# Salesforce Endpoint

## Salesforce
[Salesforce](https://www.salesforce.com) is the world’s #1 CRM platform 
that employees can access entirely over the Internet.

The Salesforce Endpoint which is implemented in ballerina allows you to access the Salesforce REST API. 
Salesforce Endpoint covers the basic functionality as well as the high level functionality of the [REST API](https://developer.salesforce.com/page/REST_API). 

Ballerina is a strong and flexible language. Also it is JSON friendly. It provides an integration tool which can be 
used to integrate the Salesforce API with other endpoints.  
It is easy to write programs for the Salesforce API by having an endpoint for Salesforce. 
Therefor this allows you to access the Salesforce REST API through Ballerina easily. 

Salesforce endpoint actions are being invoked by a ballerina main function. 
The following section provides you the details on how to use Ballerina Salesforce endpoint.


![alt text](sfdc37/resources/salesforce.png)


## Compatibility

| Ballerina Version         | Endpoint Version          | API Version |
| ------------------------- | ------------------------- | ------------|
|  0.970.0-alpha4           |          0.9.0            |   v37.0     |


## Getting started

1. Download the Ballerina tools distribution by navigating to https://ballerinalang.org/downloads/ and setup the SDK
2. Clone the repository by running the following command,
  `git clone https://github.com/wso2-ballerina/package-salesforce.git` and
   Import the package to your ballerina project.

### Prerequisites
Create a Salesforce account and create a connected app by visiting Salesforce (https://www.salesforce.com) 
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

### Working with Salesforce REST endpoint.

In order to use the Salesforce endpoint, first you need to create a Salesforce Client endpoint by passing 
above mentioned parameters.
(Visit `test.bal` file to find the way of creating Salesforce Client endpoint.)

#### Salesforce Client Object

```ballerina
public type Client object {
    public {
            SalesforceConfiguration salesforceConfig = {};
            SalesforceConnector salesforceConnector = new();
        }
    
    new () {}

    public function init (SalesforceConfiguration salesforceConfig);
    public function register (typedesc serviceType);
    public function start();
    public function getClient () returns SalesforceConnector;
    public function stop ();
};

```

#### SalesforceConfiguration record
```ballerina
public type SalesforceConfiguration {
    string baseUrl;
    http:ClientEndpointConfig clientConfig;
};

```
#### Running salesforce tests
Create `ballerina.conf` file in `package-salesforce`, with following keys:
* ENDPOINT
* ACCESS_TOKEN
* CLIENT_ID
* CLIENT_SECRET
* REFRESH_TOKEN
* REFRESH_URL

Assign relevant string values generated for Salesforce app. 

Go inside `package-sfdc37` using terminal and run test.bal file using following command `ballerina test sfdc37`.


##### Example
 * Request

 ```ballerina
 import wso2/sfdc37 as sf;
 import ballerina/io;
 
    public function main (string[] args) {
        endpoint Client salesforceClient {
            baseUrl:url,
            clientConfig:{
                auth:{
                    scheme:"oauth",
                    accessToken:accessToken,
                    refreshToken:refreshToken,
                    clientId:clientId,
                    clientSecret:clientSecret,
                    refreshUrl:refreshUrl
                }
            }
        };
    
        json|sf:SalesforceConnectorError response = salesforceClient -> getAvailableApiVersions();
            match response {
                json jsonRes => {
                    io:println(jsonRes);
                }
        
                sf:SalesforceConnectorError err => {
                    io:println(err);
                }
            }
```
* Response

JSON response or SalesforceConnectorError struct
