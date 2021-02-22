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

    int totalRecords = 0;
    string searchString = "FIND {WSO2 Inc}";
    sfdc:SoslResult|sfdc:Error res = baseClient->searchSOSLString(searchString);

    if (res is sfdc:SoslResult){
        log:print(res.searchRecords.length().toString() + " Record Received");
    }
    else{
        log:printError(res.message());
    }

}
