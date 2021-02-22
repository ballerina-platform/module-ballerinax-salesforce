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
                Id: "0032w00000QD49QAAT",
                FirstName: "Avenra",
                LastName: "Stanis",
                Title: "Software Engineer Level 1",
                Phone: "0937443354",
                Email: "remusArf@gmail.com",
                My_External_Id__c: "860"
            },
            {
                description: "Created_from_Ballerina_Sf_Bulk_API",
                Id: "0032w00000QD49RAAT",
                FirstName: "Irma",
                LastName: "Martin",
                Title: "Software Engineer Level 1",
                Phone: "0893345789",
                Email: "irmaHel@gmail.com",
                My_External_Id__c: "861"
            }
        ];
    

    sfdc:BulkJob|error updateJob = baseClient->creatJob("update", "Contact", "JSON");

    if (updateJob is sfdc:BulkJob){
        error|sfdc:BatchInfo batch = updateJob->addBatch(contacts);
        if (batch is sfdc:BatchInfo) {
           string message = batch.id.length() > 0 ? "Batch Updated Successfully" :"Failed to Update the Batch";
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




