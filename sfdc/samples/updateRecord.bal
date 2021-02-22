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
