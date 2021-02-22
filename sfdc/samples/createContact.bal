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

    json contactRecord = {
        FirstName: "Peter",
        LastName: "Potts",
        Title: "Software Engineer",
        Phone: "0475626670",
        Email: "peter@gmail.com",
        My_External_Id__c: "870"
    };

    string|sfdc:Error res = baseClient->createContact(contactRecord);

    if (res is string) {
        log:print("Contact Created Successfully. Contact ID : " + res);
    } else {
        log:printError(msg = res.message());
    }
}
