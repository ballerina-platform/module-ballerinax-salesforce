import ballerina/config;
import ballerina/log;
import ballerinax/sfdc;

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

public function main(){

    string accountId = getAccountIdByName("WSO2 Inc, Sri Lanka");

    json accountRecord = {
        Name: "WSO2 Inc",
        BillingCity: "Colombo 3"
    };

    boolean|sfdc:Error res = baseClient->updateAccount(accountId,accountRecord);

   if res is boolean{
        string outputMessage = (res == true) ? "Account Updated Successfully!" : "Failed to Update the Account";
        log:print(outputMessage);
    } else {
        log:printError(msg = res.message());
    }

}

function getAccountIdByName(string name) returns @tainted string {
    string contactId = "";
    string sampleQuery = "SELECT Id FROM Account WHERE Name='" + name + "'";
    sfdc:SoqlResult|sfdc:Error res = baseClient->getQueryResult(sampleQuery);

    if (res is sfdc:SoqlResult) {
        sfdc:SoqlRecord[]|error records = res.records;
        if (records is sfdc:SoqlRecord[]) {
            string id = records[0]["Id"].toString();
            contactId = id;
        } else {
            log:print("Getting contact ID by name failed. err=" + records.toString());            
        }
    } else {
        log:print("Getting contact ID by name failed. err=" + res.toString());
    }
    return contactId;
}
