[![Build Status](https://travis-ci.org/wso2-ballerina/module-salesforce.svg?branch=master)](https://travis-ci.org/wso2-ballerina/module-salesforce)

# Module Salesforce

Connects to Salesforce from Ballerina. 

The Salesforce connector allows you to perform CRUD operations for SObjects, query using SOQL, search using SOSL, and
describe SObjects and organizational data through the Salesforce REST API. Also it supports insert, upsert, update, 
query and delete operations for CSV, JSON and XML data types which provides in Salesforce bulk API. 
It handles OAuth 2.0 authentication.

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

## Compatibility
|                     |    Version     |
|:-------------------:|:--------------:|
| Ballerina Language  | 1.0            |
| Salesforce REST API | v46.0          |

## Sample
First, import the `wso2/sfdc46` module into the Ballerina project.
```ballerina
import wso2/sfdc46;
```
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

Note:- When you are setting up the connected app, select the following scopes under Selected OAuth Scopes:

* Access and manage your data (api)
* Perform requests on your behalf at any time (refresh_token, offline_access)
* Provide access to your data via the Web (web)

3. Provide the client ID and client secret to obtain the refresh token and access token. For more information on 
   obtaining OAuth2 credentials, go to 
   [Salesforce documentation](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).

**Create Salesforce client**

You can define the Salesforce configuration and create Salesforce client as mentioned below. 
```ballerina
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

// Create the Salesforce client.
sfdc46:Client salesforceClient = new(sfConfig);
```

After the create a `ballerina.conf` file and enter your credentials as mentioned below. These configs will be used in
the above Salesforce configuration.
```ballerina
EP_URL = ""
ACCESS_TOKEN = ""
CLIENT_ID = ""
CLIENT_SECRET = ""
REFRESH_TOKEN = ""
REFRESH_URL = ""
```

**Salesforce CRUD Operations**

The `createAccount` remote function creates an Account SObject. Pass a JSON object with the relevant fields needed for 
the SObject Account.

```ballerina
json account = {Name:"ABC Inc", BillingCity:"New York"};
var createReponse = salesforceClient->createAccount(account);
```

The response from `createAccount` is either the string ID of the created account (if the account was created 
successfully) or `SalesforceConnectorError` (if the account creation was unsuccessful).

```ballerina
if (createReponse is string) {
    io:println("Account id: " + createReponse);
} else {
    io:println(createReponse.message);
}
```

The `getQueryResult` remote function executes a SOQL query that returns all the results in a single response or if it 
exceeds the maximum record limit, it returns part of the results and an identifier that can be used to retrieve the 
remaining results.

```ballerina
string sampleQuery = "SELECT name FROM Account";
var response = salesforceClient->getQueryResult(sampleQuery);
```

The response from `getQueryResult` is either a JSON object with total size, execution status, resulting records, and 
URL to get next record set (if query execution was successful) or `SalesforceConnectorError` (if the query execution 
was unsuccessful).

```ballerina
if (response is json) {
    io:println("TotalSize:  ", response["totalSize"]);
    io:println("Done:  ", response["done"]);
    io:println("Records: ", response["records"]);
    io:println("Next response url: ", response["nextRecordsUrl"]);
} else {
    io:println("Error: ", response.message);
}
```
The `createLead` remote function creates a Lead SObject. It returns the lead ID if successful or 
`SalesforceConnectorError` if unsuccessful.

```ballerina
json lead = {LastName:"Carmen", Company:"WSO2", City:"New York"};
var createResponse = salesforceClient->createLead(lead);
if (createResponse is string) {
    io:println("Lead id: " + createResponse);
} else {
    io:println("Error: ", createResponse.message);
}
```

**Salesforce Bulk Operations**

The `createSalesforceBulkClient` remote function creates the salesforce bulk client which facilitates bulk operations.
Bulk client can create appropiate operator Corresponding to the data type. The `createCsvInsertOperator` remote function
creates Insert operator for CSV content type.

```ballerina
// Create salesforce bulk client.
sfdc46:SalesforceBulkClient sfBulkClient = salesforceClient->createSalesforceBulkClient();

// Create CSV insert operator for object type `Contact`.
sfdc46:CsvInsertOperator|sfdc:46SalesforceError csvInsertOperator = sfBulkClient->createCsvInsertOperator("Contact");
```

`upload` remote function creates a insert batch using string CSV content. `uploadFile` remote function creates a insert
batch using a CSV file. File path of the CSv file should be passed as the parameter to the `uploadFile` function.

```ballerina
// Upload the csv contacts.
string contacts = "description,FirstName,LastName,Title,Phone,Email,My_External_Id__c
Created_from_Ballerina_Sf_Bulk_API,John,Michael,Professor Grade 04,0332236677,john434@gmail.com,301
Created_from_Ballerina_Sf_Bulk_API,Peter,Shane,Professor Grade 04,0332211777,peter77@gmail.com,302";
sfdc46:Batch|sfdc46:SalesforceError batchUsingCsv = csvInsertOperator->upload(contacts);

// Upload csv contacts as a file.
string csvContactsFilePath = "src/sfdc46/tests/resources/contacts.csv";
sfdc46:Batch|sfdc46:SalesforceError batchUsingJsonFile = csvInsertOperator->uploadFile(csvContactsFilePath);
```

`closeJob` and `abortJob` remote functions close and abort CSV insert job respectively. When a job is closed, no more 
batches can be added. When a job is aborted, no more records are processed. If changes to data have already been 
committed, they aren’t rolled back.

```ballerina
// Close job.
Job|SalesforceError closedJob = csvInsertOperator->closeJob();

// Abort job.
Job|SalesforceError abortedJob = csvInsertOperator->abortJob();
```

`getJobInfo` remote function get all details for an existing job. `getBatchInfo` remote function get information about 
an existing batch. `getAllBatches` remote function get information about all batches in a job.

```ballerina
// Get job information.
Job|SalesforceError job = csvInsertOperator->getJobInfo();

// Get batch information.
Batch|SalesforceError batchInfo = csvInsertOperator->getBatchInfo(batchId);

// Get informations of all batches of this csv insert job.
BatchInfo|SalesforceError allBatchInfo = csvInsertOperator->getAllBatches();
```

`getBatchRequest` remote function gets the batch request uploaded to the csv insert job. `getBatchResults` remote 
function get results of a batch that has completed processing.

```ballerina
// Retrieve the csv batch request.
string|SalesforceError batchRequest = csvInsertOperator->getBatchRequest(batchId;
// Get batch result as csv.
string|SalesforceError batchResult = csvInsertOperator->getBatchResults(batchId);
```

Likewise Salesforce bulk client provides following operations:

- CSV 
  - insert operator
  - upsert operator
  - update operator
  - query operator
  - delete operator
- JSON 
  - insert operator
  - upsert operator
  - update operator
  - query operator
  - delete operator
- XML
  - insert operator
  - upsert operator
  - update operator
  - query operator
  - delete operator
