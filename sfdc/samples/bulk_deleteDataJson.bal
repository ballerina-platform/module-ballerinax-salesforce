import ballerina/config;
import ballerina/log;
import ballerinax/sfdc;

public function main(){

    string batchId = "";
    json contactsToDelete = [
        {"Id":"0032w00000QD4v8AAD"}, 
        {"Id":"0032w00000QD4v9AAD"}
    ];

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


    sfdc:BulkJob|error deleteJob = baseClient->creatJob("delete", "Contact", "JSON");

    if (deleteJob is sfdc:BulkJob){
        error|sfdc:BatchInfo batch = deleteJob->addBatch(contactsToDelete);
        if (batch is sfdc:BatchInfo) {
           string message = batch.id.length() > 0 ? "Contacts Successfully uploaded to delete" :"Failed to upload the Contacts to delete";
           log:print(message);
           batchId = batch.id;
           
        } else {
           log:printError(batch.message());
        }
        
        //get batch result
        var batchResult = deleteJob->getBatchResult(batchId);
        if (batchResult is sfdc:Result[]) {
            foreach sfdc:Result res in batchResult {
                if (!res.success) {
                    log:printError("Failed result, res=" + res.toString(), err = ());
                }
            }
        } else if (batchResult is error) {
            if (batchResult.message() == "InvalidBatch"){
                log:print("Records Deleted successfully");
            }
            else{
                log:printError(batchResult.message());
            }          
        } else {
            log:printError("Invalid Batch Result!");
        }

        //close job
        error|sfdc:JobInfo closedJob = baseClient->closeJob(deleteJob);
        if (closedJob is sfdc:JobInfo) {
            string message = closedJob.state == "Closed" ? "Job Closed Successfully" :"Failed to Close the Job";
            log:print(message);
        } else {
            log:printError(closedJob.message());
        }
    }

}




