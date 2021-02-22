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

    sfdc:Version[]|sfdc:Error apiVersions = baseClient->getAvailableApiVersions();

    if (apiVersions is sfdc:Version[]) {
        log:print("Versions retrieved successfully : " + apiVersions.toString());
    } else {
        log:printError(msg = apiVersions.message());
    }

    map<string>|sfdc:Error apiVersionResources = baseClient->getResourcesByApiVersion("v48.0");

    if (apiVersionResources is map<string>) {
        log:print("Versions retrieved successfully : " + apiVersionResources.toString());
    } else {
        log:printError(msg = apiVersionResources.message());
    }

    map<sfdc:Limit>|sfdc:Error apiLimits = baseClient->getOrganizationLimits();

    if (apiLimits is map<sfdc:Limit>) {
        log:print("Versions retrieved successfully : " + apiLimits.toString());
    } else {
        log:printError(msg = apiLimits.message());
    }

}
