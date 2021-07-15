Ballerina Salesforce Connector
===================
[![Build](https://github.com/ballerina-platform/module-ballerinax-sfdc/workflows/CI/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-sfdc/actions?query=workflow%3ACI)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-sfdc.svg)](https://github.com/ballerina-platformmodule-ballerinax-sfdc/commits/master)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Salesforce has a vast landscape of APIs since they follow an API-first approach to building features on the Salesforce Platform. This approach gives users flexibility to manipulate their data however they want. The most commonly used Salesforce Data APIs are REST API, SOAP API, Bulk API and Streaming API and together they make up the Salesforce Data API. 

Ballerina Salesforce connector currently utilizes the Salesforce REST API and Bulk API for convenient data manipulation. The Salesforce connector allows users to perform CRUD operations for SObjects, query using SOQL, search using SOSL, and describe SObjects and organizational data through the Salesforce REST API. Also, it supports adding bulk data jobs and batches of types JSON, XML, and CSV via the Salesforce Bulk API. Apart from these functionalities Ballerina Salesforce Connector includes a listener module to capture events.
For more information about configuration and operations, go to the module.
- [ballerinax/sfdc](sfdc/Module.md)
- [ballerinax/sfdc.rest](sfdc/modules/bulk/Module.md)
- [ballerinax/sfdc.soap](sfdc/modules/soap/Module.md)

## Building from the source
### Setting up the prerequisites
1. Download and install Java SE Development Kit (JDK) version 11 (from one of the following locations).
 
  * [Oracle](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)
 
  * [OpenJDK](https://adoptopenjdk.net/)
 
       > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed
       JDK.
 
2. Download and install [Ballerina Swan Lake Beta2](https://ballerina.io/)

### Building the source
 
Execute the commands below to build from the source.

1. To build Java dependency
   ```   
   ./gradlew build
   ```
2. To build the package:
   ```   
   bal build -c ./sfdc
   ```
3. To run the without tests:
   ```
   bal build -c --skip-tests ./sfdc
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
 