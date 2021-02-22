import ballerina/config;
import ballerina/log;
import ballerinax/sfdc;
import ballerina/stringutils;


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

    string id1 = getContactIdByName("Tony", "Stark", "Software Engineer Level 2");
    string id2 = getContactIdByName("Peter", "Parker", "Software Engineer Level 2");

    string contacts = "Id,description,FirstName,LastName,Title,Phone,Email,My_External_Id__c,Department\n" +
        id1 + ",Created_from_Ballerina_Sf_Bulk_API,Tony,Stark,Software Engineer Level 2,0882236677,tonys@gmail.com,862,HR\n" +
        id2 + "1,Created_from_Ballerina_Sf_Bulk_API,Peter,Parker,Software Engineer Level 2,0882211777,peter77@gmail.com,863,HR";
    

    sfdc:BulkJob|error updateJob = baseClient->creatJob("upsert", "Contact", "CSV","My_External_Id__c");

    if (updateJob is sfdc:BulkJob){
        error|sfdc:BatchInfo batch = updateJob->addBatch(<@untainted>contacts);
        if (batch is sfdc:BatchInfo) {
            batchId = batch.id;
            string message = batch.id.length() > 0 ? "Batch added to upsert Successfully" :"Failed to add the batch";
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
        if (batchRequest is string) {
            string message = (stringutils:split(batchRequest, "\n")).length() > 0 ? "Batch Request Received Successfully" :"Failed to Retrieve Batch Request";
            log:print(message);
            
        } else if (batchRequest is error) {
            log:printError(batchRequest.message());
        } else {
            log:printError(batchRequest.toString());
        }

        //get batch result
        var batchResult = updateJob->getBatchResult(batchId);
        if (batchResult is sfdc:Result[]) {
            foreach sfdc:Result res in batchResult {
                if (!res.success) {
                    log:printError("Failed result, res=" + res.toString(), err = ());
                }
            }
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
