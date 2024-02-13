# Email Lead Info into Salesforce using OpenAI.
This sample creates a lead on [Salesforce](https://salesforce.com) for each email marked with a specific label on [Gmail](https://mail.google.com) using the [OpenAI](https://openai.com) chat API to infer customer details.

## Use case
The following sample demonstrates a scenario in which customer leads obtained through email are automatically pushed to Salesforce. The required details for the lead (name, company, designation, etc.) are inferred from the content of the email and the OpenAI chat API.

When the user receives an email pertaining to a lead, they will mark that thread with a specific label (e.g., `"Lead"`). This Ballerina program will run continuously in the background, polling the email server every 10 minutes for threads marked with this label. If an email is found, its content will be read and used to infer the following details
* First name
* Last name
* Phone number
* Email address
* Company name
* Designation

Once these details have been inferred, a new lead will be generated on Salesforce.

![Flow diagram](/gmail-to-salesforce-lead/docs/images/flow-diagram.png)

## Prerequisites
* An email account configured to use [Gmail](https://mail.google.com)
* An account on the [Google Cloud Platform](https://console.cloud.google.com)
* An [OpenAI](https://openai.com) account with API usage enabled
* A [Salesforce](https://salesforce.com) account

>Note: The following steps will require you to generate keys for the Gmail, OpenAI and Salesforce APIs. These keys will have to be securely stored in the `Config.toml` file in the project directory under the relevant fields.

### Configuring your email account to use Gmail
> Note: If you already have a Gmail account (ending with `@gmail.com`) or your account is on the Google workspace, you do not need to follow the steps below. In essence, if you can access your email via `www.gmail.com`, the following is not necessary.
1. Visit [Gmail](https://gmail.com) and create a new account or log into an existing account.
2. Enter the `Accounts` tab under settings and click on `Add a mail account`.
3. Provide the necessary authentication details to your email account.
4. After adding a mail account, you should be able to see all new emails received to your email via the Gmail interface.

### Obtaining the Gmail API keys
1. Create a new [Google Cloud Platform project](https://console.cloud.google.com). 
2. Find and click `APIs & Services` --> `Library` from the navigation menu.
3. In the search box, enter `"Gmail"`.
4. Then select Gmail API and click `Enable` button.
5. Complete the OAuth consent screen setup.
6. Click the `Credential` tab from the left sidebar. In the displaying window click on the `Create Credentials` button and select OAuth client ID.
7. Fill in the required fields. Add `"https://developers.google.com/oauthplayground"` to the Redirect URI field.
8. Note down the `clientId` and `clientSecret`.
9. Visit https://developers.google.com/oauthplayground/. Go to settings (Top right corner) -> Tick 'Use your own OAuth credentials' and insert Oauth ClientId and clientSecret. Click close.
10. Then, Complete Step1 (Select and Authorize APIs)
11. Make sure you select the `"https://www.googleapis/auth/gmail.modify"` and `"https://www.googleapis/auth/gmail.labels` OAuth scopes. These two scopes will allow the program to read emails, including adding/removing labels.
12. Click `Authorize APIs`, and you will be in step 2.
13. Exchange Auth code for tokens.
14. Copy the `Access token` and enter it on the `Config.toml` file.

### Obtaining an OpenAI key
1. Create an [OpenAI account](https://platform.openai.com).
2. If you are eligible for a free trial of the OpenAI API, use that. Otherwise, set up your [billing information](https://platform.openai.com/account/billing/overview).
3. Obtain your [API key](https://platform.openai.com/account/api-keys) and include it in the `Config.toml` file.

### Setting up the Salesforce account
1. Visit [Salesforce](https://www.salesforce.com/) and create a Salesforce account.
2. Create a connected app and obtain the following credentials:
    *   Base URL (Endpoint)
    *   Client ID
    *   Client Secret
    *   Refresh Token
    *   Refresh Token URL
3. When you are setting up the connected app, select the following scopes under Selected OAuth Scopes:
    *   Access and manage your data (api)
    *   Perform requests on your behalf at any time (refresh_token, offline_access)
    *   Provide access to your data via the Web (web)
4. Provide the client ID and client secret to obtain the refresh token and access token. For more information on obtaining OAuth2 credentials, go to [Salesforce documentation](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).
5. Once you have obtained the access token, include it in the `Config.toml` file.

## Configuration
Create a file called `Config.toml` at the root of the project.

### Config.toml 
```
gmailAccessToken = "<GMAIL_ACCESS_TOKEN>"
openAIKey = "<OPEN_AI_KEY>"
salesforceBaseUrl = "https://<INSTANCE_ID>.salesforce.com"
salesforceAccessToken = "<SALESFORCE_ACCESS_TOKEN>"
```
### Configuration
1. Obtain the relevant OAuth access tokens for `Google Drive` and `Microsoft One Drive` configurations.
2. Obtain the folder ID of the Google Drive folder you want to sync.
3. Obtain the path of the OneDrive folder you want to sync.
4. Once you have obtained all configurations, Create the `Config.toml` file in the root directory.
5. Replace the necessary fields in the `Config.toml` file with your data.

## Testing

### Adding labels
In Gmail, we can use a label to mark an email under several categories. These labels can be manually added to email threads by the user or can be automatically added based on user-provided rules as well. For this sample, we will use a custom label to mark emails pertaining to a lead generation as `"Lead"`.

1. Log into your Gmail account.
2. Create a new label named `"Lead"` from the `Labels` tab under `Settings`
3. Whenever you receive an email pertaining to a lead generation, add the newly created label to it by clicking on the Labels icon above the thread.

### Running the project
1. Execute the ballerina project by executing `bal run` in the project directory.
2. You should see the emails you've marked as `LEAD` should have the label removed and a new lead should be created on Salesforce.
