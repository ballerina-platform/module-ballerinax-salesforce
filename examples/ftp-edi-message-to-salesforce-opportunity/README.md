# FTP B2B EDI message to Salesforce opportunity

This sample reads EDI files from a given FTP location, converts those EDI messages to Ballerina records, and creates a Salesforce opportunity for each EDI message.

## Use case

Business-to-Business(B2B) communications are commonly performed via EDI messages. Therefore, it's critical to integrate B2B messaging channels with internal IT to streamline and automate business processes. In this context, this sample shows how EDI messages containing requests for quotes (EDIFACT REQOTE) can be used to automatically create opportunities in Salesforce, and add all products in a quote as products associated with the opportunity.

## Prerequisites
* Salesforce account
* FTP server

### Setting up the Salesforce account
1. Visit [Salesforce](https://www.salesforce.com/) and create a Salesforce Account.
2. Create a connected app and obtain the following credentials:
    *   Base URL (Endpoint)
    *   Access Token
    *   Client ID
    *   Client Secret
    *   Refresh Token
    *   Refresh Token URL
3. When you are setting up the connected app, select the following scopes under Selected OAuth Scopes:
    *   Access and manage your data (api)
    *   Perform requests on your behalf at any time (refresh_token, offline_access)
    *   Provide access to your data via the Web (web)
4. Provide the client ID and client secret to obtain the refresh token and access token. For more information on obtaining OAuth2 credentials, go to [Salesforce documentation](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).
5. Fill in details under the `Salesforce configuration` in the `Config.toml` with Salesforce access details.
6. Create a sample Account named `TechShop` in Salesforce.
7. Create two Products in Salesforce and obtain product IDs. Replace `<productId1>` and `<productId2>` place holders in `resoures/inputs/quote1.edi` and `resources/inputs/quote2.edi` with product IDs.
8. Create a PriceBook in Salesforce and fill the `salesforcePriceBookId` entry in `Config.toml` with the price book ID. Add prices for products created in step 7 to the price book.

### Setting up an FTP server
1. Start FTP server using the command below.
```docker run -d -p <ftp-host-port>:21 -p 21000-21010:21000-21010 -e USERS="<username>|<password>" -e ADDRESS=localhost delfer/alpine-ftp-server```
(E.g. ```docker run -d -p 2100:21 -p 21000-21010:21000-21010 -e USERS="user1|pass1" -e ADDRESS=localhost delfer/alpine-ftp-server```).
Note that any FTP server with read and write access can be used for this sample. If an FTP server is available, skip this point.
2. Create two folders in the FTP server for input EDI files and processed EDI files (E.g. `samples/new-quotes`, `samples/processed-quotes`)
3. Copy files in the resources/inputs folder to the FTP folder created for input EDI files.
4. Fill in fields under the `FTP configuration` section in `Config.toml` with FTP server details and paths for EDI files.

### Config.toml
```
salesforcePriceBookId = "<pricebook-id>"
ftpNewQuotesPath = "<ftp-path-for-input-edi-files>"
ftpProcessedQuotesPath = "<ftp-path-for-processed-edi-files>"

# ==========================
# FTP configuration
# ==========================

[ftpConfig]
protocol = "ftp"
host = "localhost"
port = <ftp-host-port>

[ftpConfig.auth.credentials]
username = "<username>"
password = "<password>"

# ==========================
# Salesforce configuration
# ==========================

[salesforceConfig]
baseUrl = "<salesforce-base-url>"

[salesforceConfig.auth]
clientId = "<salesforce-client-id>"
clientSecret = "<salesforce-client-secret>"
refreshToken = "<salesforce-refresh-token>"
refreshUrl = "<salesforce-refresh-url>"
```

## Testing

1. Make sure the FTP server is running.
2. Run the sample using the `bal run` command.
3. Log in to Salesforce and check opportunities. Two new opportunities will be created, one for each EDI file.
4. Check FTP locations. Both EDI files will be moved to the process-quotes folder.

