import ballerina/config;
import ballerina/log;
import ballerinax/sfdc;

public function main(){

    string batchId = "";
    json[] jsonQueryResult = [];

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
    
    string queryStr = "SELECT Id, Name FROM Contact WHERE Title='Software Engineer Level 1'";

    sfdc:BulkJob|error queryJob = baseClient->creatJob("query", "Contact", "JSON");

    if (queryJob is sfdc:BulkJob){
        error|sfdc:BatchInfo batch = queryJob->addBatch(queryStr);
        if (batch is sfdc:BatchInfo) {
           string message = batch.id.length() > 0 ? "Query Executed Successfully" :"Failed to Execute the Quesry";
           batchId = batch.id;
        } else {
           log:printError(batch.message());
        }

         //get batch info
        error|sfdc:BatchInfo batchInfo = queryJob->getBatchInfo(batchId);
        if (batchInfo is sfdc:BatchInfo) {
            string message = batchInfo.id == batchId ? "Batch Info Received Successfully" :"Failed to Retrieve Batch Info";
            log:print(message);
        } else {
            log:printError(batchInfo.message());
        }

        //get all batches
        error|sfdc:BatchInfo[] batchInfoList = queryJob->getAllBatches();
        if (batchInfoList is sfdc:BatchInfo[]) {
            string message = batchInfoList.length() == 1 ? "All Batches Received Successfully" :"Failed to Retrieve All Batches";
            log:print(message);
        } else {
            log:printError(batchInfoList.message());
        }

        //get batch request
        var batchRequest = queryJob->getBatchRequest(batchId);
        if (batchRequest is string) {
            string message = batchRequest.startsWith("SELECT") ? "Batch Request Received Successfully" :"Failed to Retrieve Batch Request";
            log:print(message);
            
        } else if (batchRequest is error) {
            log:printError(batchRequest.message());
        } else {
            log:printError(batchRequest.toString());
        }


        //get batch result
        var batchResult = queryJob->getBatchResult(batchId);
        if (batchResult is json) {
            json[]|error batchResultArr = <json[]>batchResult;
            if (batchResultArr is json[]) {
                jsonQueryResult = <@untainted>batchResultArr;
                //io:println("count : " + batchResultArr.length().toString());
                log:print("Number of Records Received :" + batchResultArr.length().toString());
            } else {
                string msg = batchResultArr.toString();
                log:printError(msg);
            }
        } else if (batchResult is error) {
           string msg = batchResult.message();
           log:printError(msg);
        } else {
            log:printError("Invalid Batch Result!");
        }

        //close job
        error|sfdc:JobInfo closedJob = baseClient->closeJob(queryJob);
        if (closedJob is sfdc:JobInfo) {
            string message = closedJob.state == "Closed" ? "Job Closed Successfully" :"Failed to Close the Job";
            log:print(message);
        } else {
            log:printError(closedJob.message());
        }
    }
}




