import ballerina/config;
import ballerina/log;
import ballerinax/sfdc;
import ballerina/stringutils;


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
    
    string contactsToDelete = "Id\n" + "0032w00000QD4GNAA1\n" + "0032w00000QD4G2AAL\n" 
    sfdc:BulkJob|error deleteJob = baseClient->creatJob("delete", "Contact", "CSV");

    if (deleteJob is sfdc:BulkJob){
        error|sfdc:BatchInfo batch = deleteJob->addBatch(contactsToDelete);
        if (batch is sfdc:BatchInfo) {
            batchId = batch.id;
            string message = batch.id.length() > 0 ? "Contacts Successfully uploaded to delete" :"Failed to upload the Contacts to delete";
            log:print(message); 
        } else {
           log:printError(batch.message());
        }

        //get batch result
        var batchResult = deleteJob->getBatchResult(batchId);
        if (batchResult is string) {
            string[] records = stringutils:split(batchResult, "\n");
            log:print("Number of Records Received :" + records.toString());

        } else if (batchResult is error) {
           string msg = batchResult.message();
           log:printError(msg);
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




