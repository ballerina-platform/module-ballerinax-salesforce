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

    string contacts = "Id,description,FirstName,LastName,Title,Phone,Email,My_External_Id__c,Department\n" +
        "0032w00000QD4GNAA1,Created_from_Ballerina_Sf_Bulk_API,Tony,Stark,Software Engineer Level 2,0882236677,tonys@gmail.com,862,Human Resources\n" +
        "0032w00000QD4GOAA1,Created_from_Ballerina_Sf_Bulk_API,Peter,Parker,Software Engineer Level 2,0882211777,peter77@gmail.com,863,Human Resources";
    

    sfdc:BulkJob|error updateJob = baseClient->creatJob("upsert", "Contact", "CSV","My_External_Id__c");

    if (updateJob is sfdc:BulkJob){
        error|sfdc:BatchInfo batch = updateJob->addBatch(contacts);
        if (batch is sfdc:BatchInfo) {
           string message = batch.id.length() > 0 ? "Batch Upserted Successfully" :"Failed to Upsert the Batch";
           batchId = batch.id;
           log:print(message);
        } else {
           log:printError(batch.message());
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




