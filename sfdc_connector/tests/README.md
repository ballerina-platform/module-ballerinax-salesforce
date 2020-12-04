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

**Create external ID field in Salesforce**

Since External ID field called `My_External_Id__c` is used in the tests, follow below steps to create this external ID
field in the salesforce.

1. Log in to your salesforce account and go to the `Setup` by clicking on the settings icon in the right side of the 
   menu.
2. Then in the left side panel, under Platform tools click on the `Objects and Fields` and the click on 
   `Object Manager`. 
3. In the Object Manager page click on the `Contact` since we are going to create a external field for Contact SObject.
4. In the Contact page click on the `Fields & Relationships` and click `New` in the right hand side.
5. Then select `Text` as the Data type and click `Next`.
6. Add `My_External_Id` for "Field Label" and `255` for "Length" and click `Next`.
7. At the end click `Save` and see whether external field is added successfully by checking `Fields & Relationships`
   fields.
   
**Create a PushTopic in Salesforce**

To run the listener testcase, the following PushTopic needs to created in the Salesforce instance.

```
PushTopic pushTopic = new PushTopic();
pushTopic.Name = 'AccountUpdate';
pushTopic.Query = 'SELECT Id, Name FROM Account';
pushTopic.ApiVersion = 48.0;
pushTopic.NotifyForOperationUpdate = true;
pushTopic.NotifyForFields = 'Referenced';
insert pushTopic;
```

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
   SF_USERNAME="<USERNAME>"
   SF_PASSWORD="<PASSWORD>"
   ```
2. Run the following command inside repo root folder.
   ```bash
   $ ballerina test -a --sourceroot sfdc-connector
   ```
   