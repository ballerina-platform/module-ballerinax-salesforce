# Salesforce Endpoint

## Salesforce
[Salesforce](https://www.salesforce.com) is the world’s #1 CRM platform 
that employees can access entirely over the Internet

The Salesforce endpoint which is implemented in ballerina allows you to access the Salesforce REST API. 
Salesforce Endpoint covers the basic functionality as well as the high level functionality 
of the [REST API](https://developer.salesforce.com/page/REST_API).

Ballerina is a strong and flexible language. Also it is JSON friendly. 
It provides an integration tool which can be used to integrate the Salesforce API with other endpoints. 
It is easy to write programs for the Salesforce API by having an endpoint for Salesforce. 
Therefor it allows you to access the Salesforce REST API through Ballerina easily. 

Salesforce endpoint actions are being invoked by a ballerina main function. 
The following section provides you the details on how to use Ballerina Salesforce endpoint.


![alt text](resources/salesforce.png)


## Compatibility

| Ballerina Version         | Endpoint Version          | API Version |
| ------------------------- | ------------------------- | ------------|
|  0.970.0-alpha4           |          0.9.0            |   v37.0     |


## Getting started

1. Download the Ballerina tools distribution by navigating to https://ballerinalang.org/downloads/ and setup the SDK
2. Clone the repository by running the following command,
  `git clone https://github.com/wso2-ballerina/package-salesforce.git` and
   Import the package to your ballerina project.

### Working with Salesforce REST endpoint actions

In order to use the Salesforce endpoint, first you need to create a Salesforce Client endpoint 
by passing above mentioned parameters.

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
