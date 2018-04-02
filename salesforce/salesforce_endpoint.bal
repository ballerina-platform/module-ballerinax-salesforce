package salesforce;

import ballerina/io;
import wso2/oauth2;


public struct SalesforceConfiguration {
    oauth2:OAuth2Configuration oauth2Config;
}

public function <SalesforceConfiguration oauth2Config> SalesforceConfiguration () {
    oauth2Config.oauth2Config = {};
}


public struct SalesforceEndpoint {
    SalesforceConfiguration salesforceConfig;
    SalesforceConnector salesforceConnector;
}

public function <SalesforceEndpoint ep> init (SalesforceConfiguration salesforceConfig) {
    oauth2:OAuth2Configuration oAuth2Configuration = salesforceConfig.oauth2Config;
    oauth2:OAuth2Connector oAuth2Connector = {accessToken:oAuth2Configuration.accessToken,
                                          refreshToken:oAuth2Configuration.refreshToken,
                                          clientId:oAuth2Configuration.clientId,
                                          clientSecret:oAuth2Configuration.clientSecret,
                                          refreshTokenEP:oAuth2Configuration.refreshTokenEP,
                                          refreshTokenPath:oAuth2Configuration.refreshTokenPath,
                                          useUriParams:oAuth2Configuration.useUriParams,
                                          httpClient:http:createHttpClient(oAuth2Configuration.baseUrl, oAuth2Configuration.clientConfig)};
    ep.salesforceConnector = {oauth2:oAuth2Connector};
}

public function <SalesforceEndpoint ep> register (typedesc serviceType) {

}

public function <SalesforceEndpoint ep> start () {

}

@Description {value:"Returns the connector that client code uses"}
@Return {value:"The connector that client code uses"}
public function <SalesforceEndpoint ep> getClient () returns SalesforceConnector {
    return ep.salesforceConnector;
}

@Description {value:"Stops the registered service"}
@Return {value:"Error occured during registration"}
public function <SalesforceEndpoint ep> stop () {

}