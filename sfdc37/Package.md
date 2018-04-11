# Salesforce Connector

## Salesforce
Salesforce is the world’s #1 CRM platform that employees can access entirely over the Internet (https://www.salesforce.com)

The Salesforce connector which is implemented in ballerina allows you to access the Salesforce REST API. SalesforceConnector covers the basic functionalities as well as the high level functionalities of the REST API. (https://developer.salesforce.com/page/REST_API)

Ballerina is a strong and flexible language. Also it is JSON friendly. It provides an integration tool which can be used to integrate the Salesforce API with other endpoints.  It is easy to write programs for the Salesforce API by having a connector for Salesforce. Therefor the Salesforce connector allows you to access the Salesforce REST API through Ballerina easily. 

Salesforce connector actions are being invoked by a ballerina main function. The following section provides you the details on how to use Ballerina Salesforce connector.


![alt text](https://github.com/erandiganepola/package-salesforce/blob/master/salesforce.png)


## Compatibility

| Ballerina Version         | Connector Version         | API Version |
| ------------------------- | ------------------------- | ------------|
|  0.970.0-alpha3-SNAPSHOT  |          0.9.0            |   v37.0     |


## Getting started

1. Download the Ballerina tools distribution by navigating to https://ballerinalang.org/downloads/ and setup the SDK
2. Clone the repository by running the following command,
  `git clone https://github.com/wso2-ballerina/package-salesforce.git` and
   Import the package to your ballerina project.

### Working with Salesforce REST connector actions

In order to use the Salesforce connector, first you need to create a Salesforce Client endpoint by passing above mentioned parameters.

##### Example
 * Request

 ```ballerina
import wso2/salesforce as sf;
 import ballerina/io;
 
    public function main (string[] args) {
        endpoint Client salesforceClient {
            oauth2Config:{
                             accessToken:accessToken,
                             baseUrl:url,
                             clientId:clientId,
                             clientSecret:clientSecret,
                             refreshToken:refreshToken,
                             refreshTokenEP:refreshTokenEndpoint,
                             refreshTokenPath:refreshTokenPath,
                             clientConfig:{}
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
