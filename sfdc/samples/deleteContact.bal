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

    string contactId = getContactIdByName("Peter", "Potts");

    boolean|sfdc:Error res = baseClient->deleteContact(contactId);

    if res is boolean{
        string outputMessage = (res == true) ? "Contact Deleted Successfully!" : "Failed to Delete the Contact";
        log:print(outputMessage);
    }
    else{
        log:printError(res.message());
    }

}

function getContactIdByName(string firstName, string lastName) returns @tainted string {
    string contactId = "";
    string sampleQuery = "SELECT Id FROM Contact WHERE FirstName='" + firstName + "' AND LastName='" + lastName + "'";
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