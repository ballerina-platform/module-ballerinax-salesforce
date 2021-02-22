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

    string contactId = "0032w00000QD5PcAAL";

    json|sfdc:Error account = baseClient->getContactById(contactId, "FirstName", "LastName", "Title");

    if (account is json) {
        log:print("Contact data retrieved successfully. Cotact's Name : " + account.FirstName.toString());
    } else {
        log:printError(msg = account.message());
    }
}
