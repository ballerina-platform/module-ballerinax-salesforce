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

    map<sfdc:Limit>|sfdc:Error orgLimits = baseClient->getOrganizationLimits();

    if (orgLimits is map<sfdc:Limit>) {
        log:print("Versions retrieved successfully : " + orgLimits.toString());
    } else {
        log:printError(msg = orgLimits.message());
    }

}
