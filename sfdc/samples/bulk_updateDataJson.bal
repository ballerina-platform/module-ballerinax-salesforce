import ballerina/config;
import ballerina/log;
import ballerinax/sfdc;

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

public function main(){

    string batchId = "";

    string id1 = getContactIdByName("Avenra", "Stanis", "Software Engineer Level 1");
    string id2 = getContactIdByName("Irma", "Martin", "Software Engineer Level 1");

    json contacts = [
            {
                description: "Created_from_Ballerina_Sf_Bulk_API",
                Id: id1,
                FirstName: "Avenra",
                LastName: "Stanis",
                Title: "Software Engineer Level 1",
                Phone: "0937443355",
                Email: "remusArf@gmail.com",
                My_External_Id__c: "860"
            },
            {
                description: "Created_from_Ballerina_Sf_Bulk_API",
                Id: id2,
                FirstName: "Irma",
                LastName: "Martin",
                Title: "Software Engineer Level 1",
                Phone: "0893345755",
                Email: "irmaHel@gmail.com",
                My_External_Id__c: "861"
            }
        ];
    

    sfdc:BulkJob|error updateJob = baseClient->creatJob("update", "Contact", "JSON");

    if (updateJob is sfdc:BulkJob){
        error|sfdc:BatchInfo batch = updateJob->addBatch(<@untainted>contacts);
        if (batch is sfdc:BatchInfo) {
           string message = batch.id.length() > 0 ? "Batch Updated Successfully" :"Failed to Update the Batch";
           batchId = batch.id;
           log:print(message);
        } else {
           log:printError(batch.message());
        }

        //get batch info
        error|sfdc:BatchInfo batchInfo = updateJob->getBatchInfo(batchId);
        if (batchInfo is sfdc:BatchInfo) {
            string message = batchInfo.id == batchId ? "Batch Info Received Successfully" :"Failed to Retrieve Batch Info";
            log:print(message);
        } else {
            log:printError(batchInfo.message());
        }

        //get all batches
        error|sfdc:BatchInfo[] batchInfoList = updateJob->getAllBatches();
        if (batchInfoList is sfdc:BatchInfo[]) {
            string message = batchInfoList.length() == 1 ? "All Batches Received Successfully" :"Failed to Retrieve All Batches";
            log:print(message);
        } else {
            log:printError(batchInfoList.message());
        }

        //get batch request
        var batchRequest = updateJob->getBatchRequest(batchId);
        if (batchRequest is json) {
            json[]|error batchRequestArr = <json[]>batchRequest;
            if (batchRequestArr is json[]) {
                string message = batchRequestArr.length() > 0 ? "Batch Request Received Successfully" :"Failed to Retrieve Batch Request";
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
        var batchResult = updateJob->getBatchResult(batchId);
        if (batchResult is sfdc:Result[]) {
           string message = batchResult.length() > 0 ? "Batch Result Received Successfully" :"Failed to Retrieve Batch Result";
           log:print(message);
        } else if (batchResult is error) {
            log:printError(batchResult.message());
        } else {
            log:printError(batchResult.toString());
        }

        //close job
        error|sfdc:JobInfo closedJob = baseClient->closeJob(updateJob);
        if (closedJob is sfdc:JobInfo) {
            string message = closedJob.state == "Closed" ? "Job Closed Successfully" :"Failed to Close the Job";
            log:print(message);
        } else {
            log:printError(closedJob.message());
        }
    }

}

function getContactIdByName(string firstName, string lastName, string title) returns @tainted string {
    string contactId = "";
    string sampleQuery = "SELECT Id FROM Contact WHERE FirstName='" + firstName + "' AND LastName='" + lastName 
        + "' AND Title='" + title + "'";
    sfdc:SoqlResult|sfdc:Error res = baseClient->getQueryResult(sampleQuery);

    if (res is sfdc:SoqlResult) {
        sfdc:SoqlRecord[]|error records = res.records;
        if (records is sfdc:SoqlRecord[]) {
            string id = records[0]["Id"].toString();
            contactId = id;
        } else {
            log:print("Getting contact ID by name failed. err=" + records.toString());            
        }
    } else {
        log:print("Getting contact ID by name failed. err=" + res.toString());
    }
    return contactId;
}
