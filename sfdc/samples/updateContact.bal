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

    string contactId = getContactIdByName("Peter", "Potts", "Software Engineer");

    json contactRecord = {
        FirstName: "Peter",
        LastName: "Potts",
        Title: "Senior Software Engineer",
        Phone: "0475626670",
        Email: "peter@gmail.com",
        My_External_Id__c: "870"
    };

    boolean|sfdc:Error res = baseClient->updateContact(contactId,contactRecord);

    if res is boolean{
        string outputMessage = (res == true) ? "Contact Updated Successfully!" : "Failed to Update the Contact";
        log:print(outputMessage);
    } else {
        log:printError(msg = res.message());
    }
}

function getContactIdByName(string firstName, string lastName, string title) returns @tainted string {
    string contactId = "";
    string sampleQuery = "SELECT Id FROM Contact WHERE FirstName='" + firstName + "' AND LastName='" + lastName 
        + "' AND Title='" + title + "'";
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
