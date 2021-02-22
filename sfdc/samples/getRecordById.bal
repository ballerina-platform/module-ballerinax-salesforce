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

    string path = "/services/data/v48.0/sobjects/Account/" + accountId;

    json|sfdc:Error res = baseClient->getRecord(path);

    if (res is json) {
        log:print("Account data received successfully. Account Name : " + res.Name.toString());
    } else {
        log:printError(msg = res.message());
    }

}
