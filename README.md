Ballerina Salesforce Connector
===================
[![Build](https://github.com/ballerina-platform/module-ballerinax-sfdc/workflows/CI/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-sfdc/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/ballerina-platform/module-ballerinax-sfdc/branch/master/graph/badge.svg)](https://codecov.io/gh/ballerina-platform/module-ballerinax-sfdc)
[![Trivy](https://github.com/ballerina-platform/module-ballerinax-sfdc/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-sfdc/actions/workflows/trivy-scan.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-sfdc.svg)](https://github.com/ballerina-platformmodule-ballerinax-sfdc/commits/master)
[![GraalVM Check](https://github.com/ballerina-platform/module-ballerinax-sfdc/actions/workflows/build-with-bal-test-native.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-sfdc/actions/workflows/build-with-bal-test-native.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Salesforce Sales Cloud is a widely used CRM software provided by Salesforce Inc. Sales Cloud offers various APIs that enable developers to extend and integrate the platform with other applications, services, and systems.

Ballerina Salesforce connector utilizes the Salesforce REST API, Bulk API, Bulk API V2, APEX REST API, and SOAP API for convenient data manipulation. The Salesforce connector allows you to perform CRUD operations for SObjects, query using SOQL, search using SOSL, and describe SObjects and organizational data through the Salesforce REST API and SOAP API. Also, it supports accessing APEX endpoints using the APEX REST API and adding bulk data jobs and batches via the Salesforce Bulk and Bulk V2 APIs.
For more information about configuration and operations, go to the module(s). 

- [salesforce](ballerina/Module.md) 
   - Perform Salesforce operations programmatically through the Salesforce REST API. Users can perform CRUD operations for SObjects, query using SOQL, search using SOSL and describe SObjects and organizational data. Accessing APEX endpoints and Bulk V2 jobs and operations can also be done using this module.
- [salesforce.bulk](ballerina/modules/bulk/Module.md) 
   - Perform Salesforce bulk operations programmatically through the Salesforce Bulk API. Users can perform CRUD operations in bulk for Salesforce.
- [salesforce.soap](ballerina/modules/soap/Module.md)
   - Perform Salesforce operations programmatically through the Salesforce SOAP API, which is not supported by the Salesforce REST API. The connector is comprised of limited operations on SOAP API.

## Setup guide

1. Create a Salesforce account with the REST capability.

2. Go to Setup --> Apps --> App Manager 

   <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sfdc/revamp-2023/docs/setup/resources/side-panel.png alt="Setup Side Panel" width="50%">

3. Create a New Connected App

   <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sfdc/revamp-2023/docs/setup/resources/create-connected-apps.png alt="Create Connected Apps" width="50%">

  - Here we will be using https://test.salesforce.com as we are using sandbox enviorenment. Users can use https://login.salesforce.com for normal usage.
  
      <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sfdc/revamp-2023/docs/setup/resources/create_connected%20_app.png alt="Create Connected Apps" width="50%">

4. After the creation user can get consumer key and secret through clicking on the `Manage Consume Details` button.

   <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sfdc/revamp-2023/docs/setup/resources/crdentials.png alt="Consumer Secrets" width="50%">

5. Next step would be to get the token.
  - Log in to salesforce in your prefered browser and enter the following url 
  `https://<YOUR_INSTANCE>.salesforce.com/services/oauth2/authorize?response_type=code&client_id=<CONSUMER_KEY>&redirect_uri=<REDIRECT_URL>`
  - Allow access if an alert pops up and the browser will be redirected to a Url like follows.
  `https://login.salesforce.com/?code=<ENCODED_CODE>`
  - the code can be obtained after decoding the encoded code

6. Get Access and Refresh tokens
 - following request can be sent to obtain the tokens
 ```curl -X POST https://<YOUR_INSTANCE>.salesforce.com/services/oauth2/token?code=<CODE>&grant_type=authorization_code&client_id=<CONSUMER_KEY>&client_secret=<CONSUMER_SECRET>&redirect_uri=https://test.salesforce.com/``` 
 - tokens can be obtained from the response

## Quickstart

To use the Salesforce connector in your Ballerina application, modify the .bal file as follows:

#### Step 1: Import connector

Import the `ballerinax/salesforce` package into the Ballerina project.

```ballerina
import ballerinax/salesforce;
```

#### Step 2: Create a new connector instance

Create a `salesforce:ConnectionConfig` with the obtained OAuth2 tokens and initialize the connector with it.
```ballerina
salesforce:ConnectionConfig sfConfig = {
    baseUrl: baseUrl,
    auth: {
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: refreshUrl
    }
};

salesforce:Client baseClient = new(sfConfig);
```

#### Step 3: Invoke connector operation

1. Now you can utilize the available operations. Note that they are in the form of remote operations.  

Following is an example on how to create a record using the connector.

  ```ballerina
  record{} accountRecord = {
      "Name": "IT World",
      "BillingCity": "Colombo 1"
  };

    salesforce:CreationResponse res = check 
      baseClient->create("Account", accountRecord);

  ```

2. Use `bal run` command to compile and run the Ballerina program.

## Examples

The `salesforce` integration samples illustrate its usage in various integration scenarios. Explore these examples below, covering the use of salesforce APIs in integrations.

1. [Google Sheets new row to Salesforce contact](https://github.com/ballerina-guides/integration-samples/tree/main/gsheet-new-row-to-salesforce-new-contact) - This example creates new contacts in Salesforce using Google Sheets and Salesforce integration.

2. [Salesforce new contact to Twilio SMS](https://github.com/ballerina-guides/integration-samples/tree/main/salesforce-new-contact-to-twilio-sms) - This example sends a Twilio SMS for every new Salesforce contact.

3. [FTP B2B EDI message to Salesforce opportunity](https://github.com/ballerina-guides/integration-samples/tree/main/ftp-edi-message-to-salesforce-opportunity) - This sample reads EDI files from a given FTP location, converts those EDI messages to Ballerina records and creates a Salesforce opportunity for each EDI message.

4. [Email Lead info into Salesforce using OpenAI](https://github.com/ballerina-guides/integration-samples/tree/main/gmail-to-salesforce-lead) - This sample creates a lead on Salesforce for each email marked with a specific label on Gmail using the OpenAI chat API to infer customer details.

5. [Kafka message to Salesforce price book update](https://github.com/ballerina-guides/integration-samples/tree/main/kafka_salesforce_integration) - This example updates the product price in the Salesforce price book through Kafka and Salesforce integration.

## Report Issues

To report bugs, request new features, start new discussions, view project boards, etc., go to the [Ballerina library parent repository](https://github.com/ballerina-platform/ballerina-library).

## Building from the source
### Setting up the prerequisites
1. Download and install Java SE Development Kit (JDK) version 17. You can install either [OpenJDK](https://adoptopenjdk.net/) or [Oracle JDK](https://www.oracle.com/java/technologies/downloads/).

   > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed JDK.
 
2. Download and install [Ballerina Swan Lake](https://ballerina.io/)

### Building the source
 
Execute the commands below to build from the source.

1. To build Java dependency
   ```   
   ./gradlew build
   ```
2. * To build the package:
      ```   
      bal build ./ballerina
      ```
   * To run tests after build:
      ```
      bal test ./ballerina
      ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

   ```bash
   ./gradlew clean build
   ```

2. To run the tests:

   ```bash
   ./gradlew clean test
   ```

3. To build the without the tests:

   ```bash
   ./gradlew clean build -x test
   ```

4. To debug package with a remote debugger:

   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

5. To debug with the Ballerina language:

   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

6. Publish the generated artifacts to the local Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

7. Publish the generated artifacts to the Ballerina Central repository:

   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contributing to Ballerina
 
As an open source project, Ballerina welcomes contributions from the community.
 
For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).
 
## Code of conduct
 
All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).
 
## Useful links
 
* Discuss code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
