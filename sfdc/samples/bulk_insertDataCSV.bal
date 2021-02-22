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

    string contacts = "description,FirstName,LastName,Title,Phone,Email,My_External_Id__c\n" +
        "Created_from_Ballerina_Sf_Bulk_API,Tony,Stark,Software Engineer Level 02,0332236677,tonys@gmail.com,862\n" +
        "Created_from_Ballerina_Sf_Bulk_API,Peter,Parker,Software Engineer Level 02,0332211777,peter77@gmail.com,863";
    

    sfdc:BulkJob|error insertJob = baseClient->creatJob("insert", "Contact", "CSV");

    if (insertJob is sfdc:BulkJob){
        error|sfdc:BatchInfo batch = insertJob->addBatch(contacts);
        if (batch is sfdc:BatchInfo) {
           string message = batch.id.length() > 0 ? "Batch Added Successfully" :"Failed to add the Batch";
           batchId = batch.id;
           log:print(message + " : " + message + " " + batchId);
        } else {
           log:printError(batch.message());
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
