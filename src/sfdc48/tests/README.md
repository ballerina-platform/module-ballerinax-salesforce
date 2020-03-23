# Testing Ballerina Salesforce module

**Obtaining Tokens**

1. Visit [Salesforce](https://www.salesforce.com) and create a Salesforce Account.
2. Create a connected app and obtain the following credentials: 
    * Base URL (Endpoint)
    * Access Token
    * Client ID
    * Client Secret
    * Refresh Token
    * Refresh Token URL

Note:- When you are setting up the connected app, select the following scopes under Selected OAuth Scopes:

* Access and manage your data (api)
* Perform requests on your behalf at any time (refresh_token, offline_access)
* Provide access to your data via the Web (web)

3. Provide the client ID and client secret to obtain the refresh token and access token. For more information on 
   obtaining OAuth2 credentials, go to 
   [Salesforce documentation](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).

**Running Tests**

1. Create a `ballerina.conf` inside project root directory and replace values inside quotes (eg: <EP_URL>) with 
   appropriate values.
   ```
   EP_URL="<EP_URL>"
   ACCESS_TOKEN="<ACCESS_TOKEN>"
   CLIENT_ID="<CLIENT_ID>"
   CLIENT_SECRET="<CLIENT_SECRET>"
   REFRESH_TOKEN="<REFRESH_TOKEN>"
   REFRESH_URL="<REFRESH_URL>"
   ```
2. Run the following command inside repo root folder.
   ```bash
   $ ballerina test sfdc48
   ```
   