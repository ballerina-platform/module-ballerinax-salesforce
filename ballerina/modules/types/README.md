## Overview

Salesforce is a leading customer relationship management (CRM) platform that helps businesses manage and streamline their sales, service, and marketing operations. The [Ballerina Salesforce Connector](https://central.ballerina.io/ballerinax/salesforce/latest) is a project designed to enhance integration capabilities with Salesforce by providing a seamless connection for Ballerina. Notably, this Ballerina project incorporates record type definitions for the base types of Salesforce objects, offering a comprehensive and adaptable solution for developers working on Salesforce integration projects.

## Setup Guide

To customize this project for your Salesforce account and include your custom SObjects, follow the steps below:

### Step 1: Login to Your Salesforce Developer Account

Begin by logging into your [Salesforce Developer Account](https://developer.salesforce.com/).

### Step 2: Generate Open API Specification for Your SObjects

#### Step 2.1: Initiate OpenAPI Document Generation

Use the following command to send a POST request to start the OpenAPI document generation process.

```bash
curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
https://MyDomainName.my.salesforce.com/services/data/vXX.X/async/specifications/oas3 \
-d '{"resources": ["*"]}'
```
Replace YOUR_ACCESS_TOKEN and MyDomainName with your actual access token and Salesforce domain. If successful, you'll receive a response with a URI. Extract the locator ID from the URI.

#### Step 2.2: Retrieve the OpenAPI Document

Send a GET request to fetch the generated OpenAPI document using the following command.

```bash
curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
https://MyDomainName.my.salesforce.com/services/data/vXX.X/async/specifications/oas3/LOCATOR_ID -o oas.json
```
Replace YOUR_ACCESS_TOKEN, MyDomainName, and LOCATOR_ID with your actual values.

### Step 3: Configure Cluster Settings

To prevent Out-of-Memory (OOM) issues, execute the following command:

```bash
export JAVA_OPTS="$JAVA_OPTS -DmaxYamlCodePoints=99999999"
```

Generate the Ballerina project for the OpenAPI spec using the Ballerina Open API tool with the following commands.

1. Create a new Ballerina project, naming the project as desired (e.g., custom_types, salesforce_types, etc.).

```bash
bal new custom_types
```

2. Customize the package details by editing the `Ballerina.toml` file. For instance, you can modify the [package] section as follows:

```toml
[package]
org = "example"
name = "salesforce.types"
version = "0.1.0"
```

Feel free to replace "salesforce.types" with one of the suitable desired names like "custom.types" or "integration.types," or come up with your own unique package name.

4. Move the OpenAPI spec into the newly created project directory and execute the following command:

```bash
bal openapi -i oas.json --mode client --client-methods resource
```

This will generate the Ballerina project structure, record types that correspond to the SObject definitions, and client methods based on the provided OpenAPI specification.

### Step 4: Edit the Generated Client and Push it to Local Repository

#### Step 4.1 Delete the utils.bal and clients.bal files.

#### Step 4.2 Use the following commands to build, pack, and push the package:

````bash
bal pack

bal push --repository=local
````

By following these steps, you can set up and customize the Ballerina Salesforce Connector for your Salesforce account with ease.

## Quickstart

To use the `salesforce.types` module in your Ballerina application, modify the `.bal` file as follows:

### Step 1: Import the package

Import `ballerinax/salesforce.types` module.

```ballerina
import ballerinax/salesforce;
import ballerinax/salesforce.types;
```

### Step 2: Instantiate a new client

Obtain the tokens using the following the [`ballerinax/salesforce` connector set up guide](https://central.ballerina.io/ballerinax/salesforce/latest). Create a salesforce:ConnectionConfig with the obtained OAuth2 tokens and initialize the connector with it.

```ballerina
salesforce:ConnectionConfig config = {
    baseUrl: baseUrl,
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
    }
};

salesforce:Client salesforce = new(config);
```

### Step 3: Invoke the connector operation

Now you can utilize the available operations. Note that they are in the form of remote operations. Following is an example on how to create a record using the connector.

```ballerina
salesforce:Client salesforce = check new (config);
stypes:AccountSObject response = {
   Name: "IT World",
   BillingCity: "New York"
};

salesforce:CreationResponse response = check salesforce->create("Account", response);
```

Use following command to compile and run the Ballerina program.

```bash
bal run
```
