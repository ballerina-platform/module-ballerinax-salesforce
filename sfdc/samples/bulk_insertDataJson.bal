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
