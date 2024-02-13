# Kafka Message to Salesforce Price Book Update

This example updates the product price in the [Salesforce](https://www.salesforce.com/) price book through [Kafka](https://kafka.apache.org/) and Salesforce integration.

## Use case
Apache Kafka is a distributed event store and stream-processing platform, widely used for enterprise messaging applications.

Organizations maintain details about products in various data stores such as ERP systems, databases, etc. Different business units can update these data stores. As these updates roll out, it's essential to implement reliable communication between business units and data stores to update data across all systems consistently.

The following sample demonstrates a scenario in which a product's price in a price book in Salesforce is updated with product details fetched from a Kafka topic whenever a new message is received.

## Prerequisites
* Salesforce account
* Install Kafka

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

### Setting up Kafka.
1. To test in local machines, install the Kafka to your machine and start the server. You can follow the steps [here](https://kafka.apache.org/quickstart).

## Configuration
Create a file called `Config.toml` at the root of the project.

### Config.toml 
```
[<ORG_NAME>.kafka_salesforce_pricebook_update]
salesforceBaseUrl = "<SALESFORCE_BASE_URL>"
salesforceAccessToken = "<SALESFORCE_ACCESS_TOKEN>"
salesforcePriceBookId = "<SALESFORCE_PRICEBOOK_ID>"
```

## Testing
1. First, run the kafka-message-producer to start the Kafka producer.
2. Start the Kafka subscriber by running the kafka-salesforce-pricebook_update.
3. Then send the required message to Kafka producer using `curl http://localhost:9090/orders -H "Content-type:application/json" -d "{\"name\": \"<PRODUCT_NAME>\", \"unitPrice\": <UPDATED_PRICE>}"`.

When the new message is published to the Kafka topic, the subscriber will update the new price in the Salesforce price book.
