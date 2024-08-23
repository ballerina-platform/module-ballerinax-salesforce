# Use REST API 

This example demonstrates how to invoke REST API of Salesforce to create sObjects.

## Prerequisites

### 1. Set up
Refer to the setup guide in [ReadMe](../../../README.md) for necessary credentials.

### 2. Configuration

Configure Salesforce API credentials in Config.toml in the example directory:

```toml
clientId = "<CLIENT_ID>"
clientSecret = "<CLIENT_SECRET>"
refreshToken = "<REFRESH_TOKEN>"
refreshUrl = "<REFRESH_URL>"
baseUrl = "<BASE_URL>"
```

### 3. Integrate custom SObject types

To seamlessly integrate custom SObject types into your Ballerina project, you have the option to either generate a package using the Ballerina Open API tool or utilize the `ballerinax/salesforce.types` module. Follow the steps given [here](https://github.com/ballerina-platform/module-ballerinax-salesforce/blob/master/ballerina/modules/types/Module.md) based on your preferred approach.

## Run the example

Execute the following command to run the example:

```bash
bal run
```
