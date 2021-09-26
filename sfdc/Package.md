Connects to Salesforce from Ballerina

## Package overview

The `ballerinax/sfdc` is a [Ballerina](https://ballerina.io/) connector for Salesforce. It is comprised of the following capabilities.

* Perform Salesforce operations programmatically through the Salesforce REST API. Users can perform CRUD operations for SObjects, query using SOQL, search using SOSL and, describe SObjects and organizational data. The `ballerinax/sfdc` module provides this capability.
* Perform Salesforce bulk operations programmatically through the Salesforce Bulk API. Users can perform CRUD operations in bulk for Salesforce. The `ballerinax/sfdc.bulk` module provides this capability.
* Perform Salesforce operations programmatically through the Salesforce SOAP API which is not supported by the Salesforce REST API. The connector is comprised of limited operations on SOAP API. The `ballerinax/sfdc.soap` module provides this capability.
* Listen for Salesforce events and process them. Internally Bayeux protocol is used for polling for events. The `ballerinax/sfdc` module provides this capability.

### Compatibility
|                     | Version         |
|---------------------|-----------------|
| Ballerina Language  | Swan Lake Beta3 |
| Salesforce REST API | v48.0           |
| Salesforce Bulk API | v1              |
| Salesforce SOAP API | Enterprise WSDL |

## Report issues
To report bugs, request new features, start new discussions, view project boards, etc., go to the [Ballerina Extended Library repository](https://github.com/ballerina-platform/ballerina-extended-library)

## Useful links
- Discuss code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
- Chat live with us via our [Slack channel](https://ballerina.io/community/slack/).
- Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag
