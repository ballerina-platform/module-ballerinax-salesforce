# MySQL Record to Salesforce New Product

This example creates a new product in [Salesforce](https://www.salesforce.com/) using [MySQL](https://www.mysql.com/) and Salesforce integration.

## Use case
MySQL is an open-source relational database management system that can be easily used for data storing and retrieving applications. 

Organizations maintain details about products in various data stores such as ERP systems, databases, etc. These data stores could be updated by different business units. It is important to keep Salesforce up to date about the organization's current product lineup so that sales staff can effectively promote and sell valid products.

The following sample demonstrates a scenario of creating products in Salesforce with product details fetched from a MySQL database.

## Prerequisites
* Salesforce account
* MySQL Client

### Setting up a Salesforce account
1. Visit [Salesforce](https://www.salesforce.com/) and create a Salesforce Account.
2. Create a connected app and obtain the following credentials:
    *   Base URL (Endpoint)
    *   Access Token
    *   Client ID
    *   Client Secret
    *   Refresh Token
    *   Refresh Token URL
3. When you are setting up the connected app, select the following scopes under Selected OAuth Scopes:
    *   Access and manage your data (API)
    *   Perform requests on your behalf at any time (refresh_token, offline_access)
    *   Provide access to your data via the Web (web)
4. Provide the client ID and client secret to obtain the refresh token and access token. For more information on obtaining OAuth2 credentials, go to [Salesforce documentation](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).
5. Once you obtained all configurations, add those to the `Config.toml` file.

### Config.toml 
```
[<ORG_NAME>.mysql_record_to_sfdc_new_product]
salesforceBaseUrl = "<SALESFORCE_BASE_URL>"
port = <PORT>
host = "<DATABASE_HOST>'
user = "<USERNAME>'
password = "<PASSWORD>"
database = "<DATABASE_NAME>"
salesforceAccessToken = "<SALESFORCE_ACCESS_TOKEN>"
```
## Configuration
Create a file called `Config.toml` at the root of the project and include all the required configurations in the config file.

## Testing
1. Make sure the database is running and accessible.
2. Run the sample using `bal Run`

When the ballerina program is executed, it will create a new product in Salesforce for all the new entries and change the processed column to True so that it won't be processed again.
