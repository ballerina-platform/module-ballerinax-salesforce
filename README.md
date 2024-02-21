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

   <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sfdc/master/docs/setup/resources/side-panel.png alt="Setup Side Panel" style="border:1px solid #000000; width:40%">

3. Create a New Connected App.

   <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sfdc/master/docs/setup/resources/create-connected-apps.png alt="Create Connected Apps" style="border:1px solid #000000; width:50%">

    - Here we will be using https://test.salesforce.com as we are using sandbox enviorenment. Users can use https://login.salesforce.com for normal usage.

    <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sfdc/master/docs/setup/resources/create_connected%20_app.png alt="Create Connected Apps" style="border:1px solid #000000; width:100%">

4. After the creation user can get consumer key and secret through clicking on the `Manage Consume Details` button.

   <img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sfdc/master/docs/setup/resources/crdentials.png alt="Consumer Secrets" style="border:1px solid #000000; width:100%">

5. Next step would be to get the token.
    - Log in to salesforce in your prefered browser and enter the following url.
  ```
  https://<YOUR_INSTANCE>.salesforce.com/services/oauth2/authorize?response_type=code&client_id=<CONSUMER_KEY>&redirect_uri=<REDIRECT_URL>
  ```
   - Allow access if an alert pops up and the browser will be redirected to a Url like follows.
  
      ```
      https://login.salesforce.com/?code=<ENCODED_CODE>
      ```
  
   - The code can be obtained after decoding the encoded code

6. Get Access and Refresh tokens
   - Following request can be sent to obtain the tokens.
   
      ```
      curl -X POST https://<YOUR_INSTANCE>.salesforce.com/services/oauth2/token?code=<CODE>&grant_type=authorization_code&client_id=<CONSUMER_KEY>&client_secret=<CONSUMER_SECRET>&redirect_uri=https://test.salesforce.com/
      ``` 
   - Tokens can be obtained from the response.

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

#### Step 3: Invoke connector operation

1. Now you can utilize the available operations. Note that they are in the form of remote operations.  

Following is an example on how to create a record using the connector.

  ```ballerina
  salesforce:CreationResponse response = check 
      baseClient->create("Account", {
                          "Name": "IT World",
                          "BillingCity": "New York"
                          });

  ```

2. Use following command to compile and run the Ballerina program.

```
bal run
````

## Examples

The `salesforce` connector provides practical examples illustrating usage in various scenarios. Explore these examples below, covering use cases like creating sObjects, retrieving records, and executing bulk operations.

1. [Salesforce REST API usecases](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/main/examples/rest_api_usecases) - How to employ REST API of Salesforce to carryout varies tasks.

2. [Salesforce Bulk API usecases](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/main/examples/bulk_api_usecases) - How to employ Bulk API of Salesforce to execute Bulk jobs.

3. [Salesforce Bulk v2 API usecases](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/main/examples/bulkv2_api_usecases) - How to employ Bulk v2 API to execute an ingest job.

4. [Salesforce APEX REST API usecases](https://github.com/ballerina-platform/module-ballerinax-sfdc/tree/main/examples/apex_rest_api_usecases) - How to employ APEX REST API to create a case in Salesforce.

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
