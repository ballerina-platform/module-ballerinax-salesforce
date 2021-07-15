## Overview
The Salesforce connector allows users to perform CRUD operations for SObjects, query using SOQL, search using SOSL, and describe SObjects and organizational data through the Salesforce REST API. Apart from these functionalities Ballerina Salesforce Connector includes a listener module to capture events.

## Prerequisites
Before using this connector in your Ballerina application, complete the following:
- Create [Salesforce account](https://developer.salesforce.com/signup)
- Obtain tokens  
   - For client - Follow [this link](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm) to get tokens.
   - For listener - Follow [this link](https://help.salesforce.com/articleView?id=sf.user_security_token.htm&type=5) generate secret key and follow [this link](https://developer.salesforce.com/docs/atlas.en-us.224.0.change_data_capture.meta/change_data_capture/cdc_subscribe_channels.htm) to subscribe channels. 

## Quickstart
To use the Salesforce connector in your Ballerina application, update the .bal file as follows:

### Step 1: Import connector
First, import the `ballerinax/sfdc` module into the Ballerina project.

```ballerina
import ballerinax/sfdc;
```

### Step 2: Create a new connector instance
Create a `sfdc:SalesforceConfiguration` with the OAuth2 tokens obtained, and initialize the connector with it.
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

sfdc:Client baseClient = new(sfConfig);
```

### Step 3: Invoke connector operation
1. Now you can use the operations available within the connector. Note that they are in the form of remote operations.  
Following is an example on how to create record using the connector.

    ```ballerina
    json accountRecord = {
      Name: "John Keells Holdings",
      BillingCity: "Colombo 3"
    };

    string recordId = check baseClient->createRecord("Account", accountRecord);
    ```
2. Use `bal run` command to compile and run the Ballerina program.

## Quick reference
Code snippets of some frequently used functions: 

- Create record  
The `createRecord` remote function of the baseClient can be used to create SObject records for a given SObject type. Users need to pass SObject name and the SObject record in json format to the `createRecord` function and it will return newly created record Id as a string at the success and will return an error at the failure. 

  ```ballerina
  json accountRecord = {
    Name: "John Keells Holdings",
    BillingCity: "Colombo 3"
  };

  string|sfdc:Error recordId = baseClient->createRecord("Account", accountRecord);
  ```

- Get record  
The `getRecord` remote function of the baseClient can be used to get SObject record by SObject Id. Users need to pass the path to the SObject including the SObject Id to the `getRecord` function and it will return the record in json at the success and will return an error at the failure. 

  ```ballerina
  string testRecordId = "001xa000003DIlo";
  string path = "/services/data/v48.0/sobjects/Account/" + testRecordId;
  json|Error response = baseClient->getRecord(path);
  ```

- Update record  
The `updateRecord` remote function of the baseClient can be used to update SObject records for a given SObject type. Users need to pass SObject name, SObject Id and the SObject record in json format to the updateRecord’ function and it will return `true` at the success and will return an error at the failure. 

  ```ballerina
  json account = {
        Name: "WSO2 Inc",
        BillingCity: "Jaffna",
        Phone: "+94110000000"
    };
  sfdc:Error? isSuccess = baseClient->updateRecord("Account", testRecordId, account);
  ```

- Delete record  
The Ballerina Salesforce connector facilitates users to delete SObject records by the SObject ID. Users need to pass SObject Name and the SObject record id as parameters and the function will return true at successful completion. 

  ```ballerina
  string testRecordId = "001xa000003DIlo";
  sfdc:Error? isDeleted = baseClient->deleteRecord("Account", testRecordId);
  ```
Convenient CRUD operations for common SObjects  
Apart from the common CRUD operations that can be used with any SObject, the Ballerina Salesforce connector provides customized CRUD operations for pre-identified, most commonly used SObjects. They are **Account**, **Lead**, **Contact**, **Opportunity** and **Product**.   
Following are the sample codes for Account’s CRUD operations and the other above mentioned SObjects follow the same implementation and only the Id should be changed according to the SObject type. 

- Create account  
`createAccount` remote function accepts an account record in json as an argument and returns Id of the account created at success. 

  ```ballerina
  json accountRecord = {
    Name: "John Keells Holdings",
    BillingCity: "Colombo 3"
  };

  string|sfdc:Error accountId = baseClient->createAccount(accountRecord);
  ```

- Get account by ID  
User needs to pass the Id of the account and the names of the fields needed parameters for the `getAccountById` remote function. Function will return the record in json format at success. 

  ```ballerina
  string accountId = "001xa000003DIlo";

  json|sfdc:Error account = baseClient->getAccountById(accountId, Name, BillingCity);
  ```

- Update account  
`updateAccount` remote function accepts account id and the account record needed to update in json as arguments and returns true at success. 

  ```ballerina
  string accountId = "001xa000003DIlo";
  json account = {
        Name: "WSO2 Inc",
        BillingCity: "Jaffna",
        Phone: "+94110000000"
    };
  sfdc:Error? isSuccess = baseClient->updateRecord(accountId, account);
  ```

- Delete account  
User needs to pass the Id of the account he needs to delete for the `deleteAccount` remote function. Function will return true at success. 

  ```ballerina
  string accountId = "001xa000003DIlo";
  sfdc:Error? isDeleted = baseClient->deleteAccount(accountId);
  ```

- Query operations  
The `getQueryResult` remote function executes a SOQL query that returns all the results in a single response or if it exceeds the maximum record limit, it returns part of the results and an identifier that can be used to retrieve the remaining results.

  ```ballerina
  string sampleQuery = "SELECT name FROM Account";
  SoqlResult|Error res = baseClient->getQueryResult(sampleQuery);
  ```

  The response from `getQueryResult` is either a `SoqlResult` record with total size, execution status, resulting records, and URL to get the next record set (if query execution was successful) or Error (if the query execution was unsuccessful).

  ```ballerina
  if (response is sfdc:SoqlResult) {
      io:println("TotalSize:  ", response.totalSize.toString());
      io:println("Done:  ", response.done.toString());
      io:println("Records: ", response.records.toString());
  } else {
      io:println("Error: ", response.message());
  }
  ```

  If response has exceeded the maximum record limit, response will contain a key named ‘nextRecordsUrl’ and then the user can call `getNextQueryResult` remote function to get the next record set. 

  ```ballerina
  sfdc:SoqlResult|sfdc:Error resp = baseClient->getNextQueryResult(nextRecordsUrl);
  ```

- Search operations  
The `searchSOSLString` remote function allows users to search using a string and returns all the occurrences of the string back to the user. SOSL searches are faster and can return more relevant results.

  ```
  string searchString = "FIND {WSO2 Inc}";
  sfdc:SoslResult|Error res = baseClient->searchSOSLString(searchString);
  ```

- Operations to get SObject metadata  
Ballerina Salesforce Connector facilitates users to retrieve SObject related information and metadata through Salesforce REST API. Following are the remote functions available for retrieving SObject metadata. 

  <table>
  <tr>
   <td><strong>Remote Function</strong>
   </td>
   <td><strong>Description</strong>
   </td>
  </tr>
  <tr>
   <td>describeAvailableObjects
   </td>
   <td>Lists the available objects and their metadata for your organization and available to the logged-in user
   </td>
  </tr>
  <tr>
   <td>getSObjectBasicInfo
   </td>
   <td>Returns metadata of the specified SObject
   </td>
  </tr>
  <tr>
   <td>describeSObject
   </td>
   <td>Returns  metadata at all levels for the specified object including the fields, URLs, and child relationships
   </td>
  </tr>
  <tr>
   <td>sObjectPlatformAction
   </td>
   <td>Query for actions displayed in the UI, given a user, a context, device format, and a record ID
   </td>
  </tr>
  </table>


- Operations to get organizational data  
Apart from the main SObject related functions Ballerina Salesforce Connector facilitates users to get information about their organization. Following are the remote functions available for retrieving organizational data. 

  <table>
  <tr>
   <td><strong>Remote Function</strong>
   </td>
   <td><strong>Description</strong>
   </td>
  </tr>
  <tr>
   <td>getAvailableApiVersions
   </td>
   <td>Use the <a href="https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_versions.htm">Versions</a> 
   resource to list summary information about each REST API version currently available, including the version, label, 
   and a link to each version's root
   </td>
  </tr>
  <tr>
   <td>getResourcesByApiVersion
   </td>
   <td>Use the <a href="https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_discoveryresource.htm">Resources by Version</a> 
   resource to list the resources available for the specified API version. This provides the name and URI of each additional resource. 
   Users need to provide API Version as a parameter to the function. 
   </td>
  </tr>
  <tr>
   <td>getOrganizationLimits
   </td>
   <td>Use the <a href="https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_limits.htm">Limits resource</a> 
   to list your org limits. 
   </td>
  </tr>
  </table>

- Event Listener  
The Listener which can be used to capture events defined in a Salesforce instance is configured as below.

  ```ballerina
  sfdc:ListenerConfiguration listenerConfig = {
    username: config:getAsString("SF_USERNAME"),
    password: config:getAsString("SF_PASSWORD")
  };
  listener sfdc:Listener eventListener = new (listenerConfig);
  ```

  In the above configuration, the password should be the concatenation of the user's Salesforce password and his secret key.

  Now, a service has to be defined on the ‘eventListener’ like the following.

  ```ballerina
  @sfdc:ServiceConfig {
      channelName:"/data/ChangeEvents"
  }
  service quoteUpdate on eventListener {
      resource function onUpdate (sfdc:EventData quoteUpdate) { 
          json quote = op.changedData.get("Status");
          if (quote is json) {
              io:println("Quote Status : ", quote);
          }
      }
  }
  ```

  The above service is listening to events in the Salesforce and we can capture any data that comes with it.

**[You can find a list of samples here](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/master/sfdc/samples/rest_api_usecases)**
