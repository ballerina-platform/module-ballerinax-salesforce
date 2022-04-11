import ballerinax/salesforce.soap;
import ballerina/log;

public function main() returns error? {

    soap:Client salesforceClient = check new ({
        baseUrl: "<BASE_URL>",
        clientConfig: {
            clientId: "<CLIENT_ID>",
            clientSecret: "<CLIENT_SECRET>",
            refreshToken: "<REFESH_TOKEN>",
            refreshUrl: "<REFRESH_URL>"
        }
    });

    soap:ConvertedLead convertLead = check salesforceClient->convertLead({
        leadId: "xxx",
        convertedStatus: "Closed - Converted"
    });
    log:printInfo(convertLead.toString());
}
