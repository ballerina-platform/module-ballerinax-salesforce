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
    string sampleQuery = "SELECT name FROM Account";
    sfdc:SoqlResult|sfdc:Error res = baseClient->getQueryResult(sampleQuery);

    if (res is sfdc:SoqlResult) {
        if (res.totalSize > 0){
            totalRecords = res.records.length() ;
            string|error nextRecordsUrl = res["nextRecordsUrl"].toString();
            while (nextRecordsUrl is string && nextRecordsUrl.trim() != "") {
                log:print("Found new query result set! nextRecordsUrl:" + nextRecordsUrl);
                sfdc:SoqlResult|sfdc:Error nextRes = baseClient->getNextQueryResult(<@untainted>nextRecordsUrl);
                
                if (nextRes is sfdc:SoqlResult) {
                    totalRecords = totalRecords + nextRes.records.length();
                    res = nextRes;
                } 
            }
            log:print(totalRecords.toString() + " Records Recieved");
        }
        else{
            log:print("No Results Found");
        }
        
    } else {
        log:printError(msg = res.message());
    }
}
