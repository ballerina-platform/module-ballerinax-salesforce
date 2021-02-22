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

    json|sfdc:Error account = baseClient->getAccountById(accountId, "Name", "BillingCity");

    if (account is json) {
        log:print("Account data retrieved successfully. Account Name : " + account.Name.toString());
    } else {
        log:printError(msg = account.message());
    }
}
