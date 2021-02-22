# Ballerina Salesforce Connector Samples 

## Rest API Operations 

Ballerina Salesforce Connector facilitates users to perform CRUD operation on Salesforce Objects.

### Create Record 

Create records based on relevant object type sent with json record.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/sfdc;

public function main(){

    // Create Salesforce client configuration by reading from config file.
    sfdc:SalesforceConfiguration sfConfig = {
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

    // Create Salesforce client.
    sfdc:BaseClient baseClient = new(sfConfig);

    json accountRecord = {
        Name: "IT World",
        BillingCity: "Colombo 1"
    };

    string|sfdc:Error res = baseClient->createRecord("Account", accountRecord);

    if (res is string) {
        log:print("Account Created Successfully. Account ID : " + res);
    } else {
        log:printError(msg = res.message());
    }
}
```

### Get Record By Id

Accesses records based on the specified object ID, can be used with external objects.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/sfdc;

public function main(){

    // Create Salesforce client configuration by reading from config file.
    sfdc:SalesforceConfiguration sfConfig = {
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

    // Create Salesforce client.
    sfdc:BaseClient baseClient = new(sfConfig);

    json accountRecord = {
        Name: "IT World",
        BillingCity: "Colombo 1"
    };

    string|sfdc:Error res = baseClient->createRecord("Account", accountRecord);

    if (res is string) {
        log:print("Account Created Successfully. Account ID : " + res);
    } else {
        log:printError(msg = res.message());
    }
}

```

### Update Record

Update records based on relevant object id.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/sfdc;

public function main(){

    // Create Salesforce client configuration by reading from config file.
    sfdc:SalesforceConfiguration sfConfig = {
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

    // Create Salesforce client.
    sfdc:BaseClient baseClient = new(sfConfig);

    string accountId = "0015Y00002adeBWQAY";

    json accountRecord = {
        Name: "University of Kelaniya",
        BillingCity: "Kelaniya",
        Phone: "+94110000000"
    };

    boolean|sfdc:Error res = baseClient->updateRecord("Account", accountId, accountRecord);

    if res is boolean{
        string outputMessage = (res == true) ? "Record Updated Successfully!" : "Failed to Update the Record";
        log:print(outputMessage);
    }
    else{
        log:printError(res.message());
    }
}
```

### Delete Record

Delete existing records based on relevant object id.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/sfdc;

public function main(){

    // Create Salesforce client configuration by reading from config file.
    sfdc:SalesforceConfiguration sfConfig = {
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

    // Create Salesforce client.
    sfdc:BaseClient baseClient = new(sfConfig);

    string accountId = "0015Y00002adsuhQAA";

    boolean|sfdc:Error res = baseClient->deleteRecord("Account", accountId);

    if res is boolean{
        string outputMessage = (res == true) ? "Record Deleted Successfully!" : "Failed to Delete the Record";
        log:print(outputMessage);
    }
    else{
        log:printError(res.message());
    }
}

```

Other than the common CRUD functions that can be used with any SObject, ballerina Salesforce Connector provides a set of specific CRUD functions to most commonly use SObjects for convienient access. Those objects are `Account`, `Contact`, `Lead`, `Opportunity`, and `Product`. 

### Samples for Account

* [Create New Account](https://github.com/aneeshafedo/module-ballerinax-sfdc/blob/master/sfdc/samples/createAccount.bal)
* [Get Account by ID](https://github.com/aneeshafedo/module-ballerinax-sfdc/blob/master/sfdc/samples/getAccountById.bal)
* [Update Account](https://github.com/aneeshafedo/module-ballerinax-sfdc/blob/master/sfdc/samples/updateAccount.bal)
* [Delete Account](https://github.com/aneeshafedo/module-ballerinax-sfdc/blob/master/sfdc/samples/deleteAccount.bal)

### Samples for Contact

* [Create New Contact](https://github.com/aneeshafedo/module-ballerinax-sfdc/blob/master/sfdc/samples/createContact.bal)
* [Get Contact by ID](https://github.com/aneeshafedo/module-ballerinax-sfdc/blob/master/sfdc/samples/getContactById.bal)
* [Update Contact](https://github.com/aneeshafedo/module-ballerinax-sfdc/blob/master/sfdc/samples/updateContact.bal)
* [Delete Contact](https://github.com/aneeshafedo/module-ballerinax-sfdc/blob/master/sfdc/samples/deleteContact.bal)

## SOQL Operation

Executes the specified SOQL query.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/sfdc;

public function main(){

    // Create Salesforce client configuration by reading from config file.
    sfdc:SalesforceConfiguration sfConfig = {
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

    // Create Salesforce client.
    sfdc:BaseClient baseClient = new(sfConfig);

    int totalRecords = 0;
    string sampleQuery = "SELECT name FROM Account";
    sfdc:SoqlResult|sfdc:Error res = baseClient->getQueryResult(sampleQuery);

    if (res is sfdc:SoqlResult) {
        if (res.totalSize > 0){
            totalRecords = res.records.length() ;
            string|error nextRecordsUrl = res["nextRecordsUrl"].toString();
            while (nextRecordsUrl is string && nextRecordsUrl.trim() != "") {
                log:print("Found new query result set! nextRecordsUrl:" + nextRecordsUrl);
                sfdc:SoqlResult|sfdc:Error nextRes = baseClient->getNextQueryResult(<@untainted>nextRecordsUrl);
                
                if (nextRes is sfdc:SoqlResult) {
                    totalRecords = totalRecords + nextRes.records.length();
                    res = nextRes;
                } 
            }
            log:print(totalRecords.toString() + " Records Recieved");
        }
        else{
            log:print("No Results Found");
        }
        
    } else {
        log:printError(msg = res.message());
    }
}

```

## SOSL Operation

Executes the specified SOSL search.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/sfdc;

public function main(){

    // Create Salesforce client configuration by reading from config file.
    sfdc:SalesforceConfiguration sfConfig = {
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

    // Create Salesforce client.
    sfdc:BaseClient baseClient = new(sfConfig);

    int totalRecords = 0;
    string searchString = "FIND {WSO2 Inc}";
    sfdc:SoslResult|sfdc:Error res = baseClient->searchSOSLString(searchString);

    if (res is sfdc:SoslResult){
        log:print(res.searchRecords.length().toString() + " Record Received");
    }
    else{
        log:printError(res.message());
    }
}
```

## Bulk Operations

Ballerina Salesforce connector supports `insert`, `uodate`, `query` and `delete` operations on `CSV`, `Json`, or `xml` data through Salesforce Bulk API V1. Insert operations futher can be performed on inline data or data from a file in a given location. A sample code for each and every scenario is given in the repository. Following is the sample code for **Insert Data in Json Format **

### Insert Bulk Data in Json Format

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/sfdc;

public function main(){

    string batchId = "";

    // Create Salesforce client configuration by reading from config file.
    sfdc:SalesforceConfiguration sfConfig = {
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

    // Create Salesforce client.
    sfdc:BaseClient baseClient = new(sfConfig);

    json contacts = [
            {
                description: "Created_from_Ballerina_Sf_Bulk_API",
                FirstName: "Avenra",
                LastName: "Stanis",
                Title: "Software Engineer Level 1",
                Phone: "0475626670",
                Email: "remusArf@gmail.com",
                My_External_Id__c: "860"
            },
            {
                description: "Created_from_Ballerina_Sf_Bulk_API",
                FirstName: "Irma",
                LastName: "Martin",
                Title: "Software Engineer Level 1",
                Phone: "0465616170",
                Email: "irmaHel@gmail.com",
                My_External_Id__c: "861"
            }
        ];
    

    sfdc:BulkJob|error insertJob = baseClient->creatJob("insert", "Contact", "JSON");

    if (insertJob is sfdc:BulkJob){
        error|sfdc:BatchInfo batch = insertJob->addBatch(contacts);
        if (batch is sfdc:BatchInfo) {
           string message = batch.id.length() > 0 ? "Batch Added Successfully" :"Failed to add the Batch";
           batchId = batch.id;
           log:print(message + " : " + message + " " + batchId);
        } else {
           log:printError(batch.message());
        }

        //get job info
        error|sfdc:JobInfo jobInfo = baseClient->getJobInfo(insertJob);
        if (jobInfo is sfdc:JobInfo) {
            string message = jobInfo.id.length() > 0 ? "Jon Info Received Successfully" :"Failed Retrieve Job Info";
            log:print(message);
        } else {
            log:printError(jobInfo.message());
        }

        //get batch info
        error|sfdc:BatchInfo batchInfo = insertJob->getBatchInfo(batchId);
        if (batchInfo is sfdc:BatchInfo) {
            string message = batchInfo.id == batchId ? "Batch Info Received Successfully" :"Failed to Retrieve Batch Info";
            log:print(message);
        } else {
            log:printError(batchInfo.message());
        }

        //get all batches
        error|sfdc:BatchInfo[] batchInfoList = insertJob->getAllBatches();
        if (batchInfoList is sfdc:BatchInfo[]) {
            string message = batchInfoList.length() == 1 ? "All Batches Received Successfully" :"Failed to Retrieve All Batches";
            log:print(message);
        } else {
            log:printError(batchInfoList.message());
        }

        //get batch request
        var batchRequest = insertJob->getBatchRequest(batchId);
        if (batchRequest is json) {
            json[]|error batchRequestArr = <json[]>batchRequest;
            if (batchRequestArr is json[]) {
                string message = batchRequestArr.length() == 2 ? "Batch Request Received Successfully" :"Failed to Retrieve Batch Request";
                log:print(message);
            } else {
                log:printError(batchRequestArr.message());
            }
        } else if (batchRequest is error) {
            log:printError(batchRequest.message());
        } else {
            log:printError(batchRequest.toString());
        }

        //get batch result
        var batchResult = insertJob->getBatchResult(batchId);
        if (batchResult is sfdc:Result[]) {
           string message = batchResult.length() > 0 ? "Batch Result Received Successfully" :"Failed to Retrieve Batch Result";
           log:print(message);
        } else if (batchResult is error) {
            log:printError(batchResult.message());
        } else {
            log:printError(batchResult.toString());
        }

        //close job
        error|sfdc:JobInfo closedJob = baseClient->closeJob(insertJob);
        if (closedJob is sfdc:JobInfo) {
            string message = closedJob.state == "Closed" ? "Job Closed Successfully" :"Failed to Close the Job";
            log:print(message);
        } else {
            log:printError(closedJob.message());
        }
    }
}
````

