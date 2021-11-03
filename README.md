Ballerina Salesforce Connector
===================
[![Build](https://github.com/ballerina-platform/module-ballerinax-sfdc/workflows/CI/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-sfdc/actions?query=workflow%3ACI)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-sfdc.svg)](https://github.com/ballerina-platformmodule-ballerinax-sfdc/commits/master)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Salesforce has a vast collection of APIs since they follow an API-first approach to build features on the Salesforce Platform. This approach gives their users the flexibility to manipulate their data however they want. The most commonly used Salesforce Data APIs are REST API, SOAP API, Bulk API, and Streaming API. 

Ballerina Salesforce connector utilizes the Salesforce REST API, Bulk API, and SOAP API for convenient data manipulation. The Salesforce connector allows you to perform CRUD operations for SObjects, query using SOQL, search using SOSL, and describe SObjects and organizational data through the Salesforce REST API and SOAP API. Also, it supports adding bulk data jobs and batches of types JSON, XML, and CSV via the Salesforce Bulk API. Apart from these functionalities, Ballerina Salesforce connector includes a listener to capture events.
For more information about configuration and operations, go to the module(s).
- [sfdc](sfdc/Module.md) 
   - Perform Salesforce operations programmatically through the Salesforce REST API. Users can perform CRUD operations for SObjects, query using SOQL, search using SOSL and, describe SObjects and organizational data.
   - Listen for Salesforce events and process them. Internally Bayeux protocol is used for polling for events.
- [sfdc.rest](sfdc/modules/bulk/Module.md) 
   - Perform Salesforce bulk operations programatically through the Salesforce Bulk API. Users can perform CRUD operations in bulk for Salesforce.
- [sfdc.soap](sfdc/modules/soap/Module.md)
   - Perform Salesforce operations programmatically through the Salesforce SOAP API which is not supported by the Salesforce REST API. The connector is comprised of limited operations on SOAP API.

## Building from the source
### Setting up the prerequisites
1. Download and install Java SE Development Kit (JDK) version 11. You can install either [OpenJDK](https://adoptopenjdk.net/) or [Oracle JDK](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html).

   > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed JDK.
 
2. Download and install [Ballerina Swan Lake Beta3](https://ballerina.io/)

### Building the source
 
Execute the commands below to build from the source.

1. To build Java dependency
   ```   
   ./gradlew build
   ```
2. * To build the package:
      ```   
      bal pack ./sfdc
      ```
   * To run tests after build:
      ```
      bal test ./sfdc
      ```
## Contributing to Ballerina
 
As an open source project, Ballerina welcomes contributions from the community.
 
For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).
 
## Code of conduct
 
All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).
 
## Useful links
 
* Discuss code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Slack channel](https://ballerina.io/community/slack/).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
 