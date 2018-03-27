# Salesforce Connector

## Salesforce
Salesforce is the world’s #1 CRM platform that employees can access entirely over the Internet (https://www.salesforce.com)

The Salesforce connector which is implemented in ballerina allows you to access the Salesforce REST API. SalesforceConnector covers the basic functionalities as well as the high level functionalities of the REST API. (https://developer.salesforce.com/page/REST_API)

Ballerina is a strong and flexible language. Also it is JSON friendly. It provides an integration tool which can be used to integrate the Salesforce API with other endpoints.  It is easy to write programs for the Salesforce API by having a connector for Salesforce. Therefor the Salesforce connector allows you to access the Salesforce REST API through Ballerina easily. 

Salesforce connector actions are being invoked by a ballerina main function. The following section provides you the details on how to use Ballerina Salesforce connector.


![alt text](https://github.com/erandiganepola/connector-salesforce/blob/master/salesforce.png)


## Compatibility

| Language Version  | Connector Version | API Version |
| ------------------| ------------------| ------------|
|  0.964            |        0.1        |   v37.0     |
|  0.970-alpha0     |        0.2        |   v37.0     |


## Getting started

1. Download the Ballerina tool `0.970-alpha0` distribution by navigating to https://ballerinalang.org/downloads/ and setup      the SDK
2. Clone the repository by running the following command,
  `git clone https://github.com/wso2-ballerina/package-salesforce.git` and
   Import the package to your ballerina project.

### Prerequisites
Create a Salesforce organization, create a connected app by visiting Salesforce and obtain the following parameters:
* Client Id
* Client Secret
* Access Token
* Refresh Token
* Api Instance
* Api Version
* Refresh endpoint
 * Refresh endpoint :- Sandbox Organization - https://test.salesforce.com/services/oauth2/token Other Organization - https://login.salesforce.com/services/oauth2/token

IMPORTANT: This access token and refresh token can be used to make API requests on your own account's behalf. Do not share your access token, client secret with anyone.

### Working with Salesforce REST connector actions

In order to use the Salesforce connector, first you need to create a SalesforceConnector endpoint by passing above mentioned parameters and initialize it.
#### Salesforce struct
```ballerina
public struct SalesforceConnector {
    OAuth2Client oauth2;
}
```
#### Init() function
```ballerina
public function <SalesforceConnector sfConnector> init (string baseUrl, string accessToken, string refreshToken,
                                                        string clientId, string clientSecret, string refreshTokenEP, string refreshTokenPath) {
    sfConnector.oauth2 = {};
    sfConnector.oauth2.init(baseUrl, accessToken, refreshToken,
                            clientId, clientSecret, refreshTokenEP, refreshTokenPath, "", "");
}
```
#### Following public actions are provided to the user

[describeAvailableObjects()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_describeGlobal.htm)
Lists the available objects and their metadata for your organization’s data
* Properties
   ##### Parameters
   * None
   ##### Returns
   * Json Response or salesforce:SalesforceConnectorError

[describeSObject()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_sobject_describe.htm)
Completely describes the individual metadata at all levels for the specified object
* Properties
   ##### Parameters
   * sobjectName: The relevant sobject name
   ##### Returns
   * Json Response or salesforce:SalesforceConnectorError

[getAvailableApiVersions()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_versions.htm?search_text=error)
Lists summary information about each REST API version currently available
* Properties
   ##### Parameters
   * None
   ##### Returns
   * Json Response or salesforce:SalesforceConnectorError

[getResourcesByApiVersion()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_discoveryresource.htm)
Lists the resources available for the specified API version
* Properties
   ##### Parameters
   * None
   ##### Returns
   * Json Response or salesforce:SalesforceConnectorError
   
[query()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_query.htm)
Executes the specified SOQL query
* Properties
   ##### Parameters
    * query: The request SOQL query
    ##### Returns
    * Json Response or salesforce:SalesforceConnectorError

[getAllQueries()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_queryall.htm?search_text=updated)
QueryAll will return records that have been deleted because of a merge or delete, archived Task and Event records
* Properties
   ##### Parameters
    * apiVersion: The api version to send request to
    * queryString: The request SOQL query
   ##### Returns
    * Json Response or salesforce:SalesforceConnectorError

nextQueryResult()
If the queryAll results are too large, retrieve the next batch of results
* Properties
   ##### Parameters
   * nextRecordsUrl: The url sent with first batch of queryAll results to get the next batch
   ##### Returns
    * Json Response or salesforce:SalesforceConnectorError
   
[getOrganizationLimits()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_limits.htm)
Lists limits information for your organization
* Properties
   ##### Parameters
   * None
   ##### Returns
   * Json Response or salesforce:SalesforceConnectorError
    
[getSObjectBasicInfo()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_sobject_basic_info.htm)
Describes the individual metadata for the specified object
* Properties
   ##### Parameters
   * sobjectName: The relevant sobject name
   ##### Returns
   * Json Response or salesforce:SalesforceConnectorError

[sObjectPlatformAction()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_sobject_platformaction.htm)
Query for actions displayed in the UI, given a user, a context, device format, and a record ID
* Properties
   ##### Parameters
   * None
   ##### Returns
   * Json Response or salesforce:SalesforceConnectorError

[getRecordByExternalId()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/using_resources_retrieve_with_externalid.htm?search_text=external%20ID)
Creates new records or updates existing records (upserts records) based on the value of a specified external ID field
* Properties
   ##### Parameters
   * sobjectName: The relevant sobject name
   * fieldName: The external field name
   * fieldValue: The external field value
   ##### Returns
   * Json Response or salesforce:SalesforceConnectorError

[explainQueryOrReportOrListview()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_query_explain.htm?search_text=explain)
Get feedback on how Salesforce will execute your list view
* Properties
   ##### Parameters
    * queryReportOrListview: The parameter to get feedback on
   ##### Returns 
    * Json Response or salesforce:SalesforceConnectorError

[getRecord()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/using_resources_working_with_records.htm)
Accesses records based on the specified object ID
* Properties
   ##### Parameters
   * sobjectName: The relevant sobject name
   ##### Returns
   * Json Response or salesforce:SalesforceConnectorError

[createRecord()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_sobject_create.htm)
Creates new records
* Properties
    ##### Parameters
    * sobjectName: The relevant sobject name
    * record: json payload containing record data
    ##### Returns
    * String ID or salesforce:SalesforceConnectorError

[createMultipleRecords()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_composite_sobject_tree_flat.htm)
Create multiple records
* Properties
   ##### Parameters
   * sObjectName: The relevant sobject name
   * payload: json payload containing record data
   ##### Returns
   * Json Response or salesforce:SalesforceConnectorError
   
[updateRecord()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_update_fields.htm)
Updates an existing record
* Properties
   ##### Parameters
   * sobjectName: The relevant sobject name
   * record: json payload containing record data
   ##### Returns
   * boolean (if success: true, else false) or salesforce:SalesforceConnectorError

[deleteRecord()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_delete_record.htm)
Deletes existing record
* Properties
   ##### Parameters
   * sobjectName: The relevant sobject name
   * id: The id of the relevant record supposed to be deleted
   ##### Returns
   * boolean (if success: true, else false) or salesforce:SalesforceConnectorError

[getfieldValuesFromSObjectRecord()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_get_field_values.htm)
Retrieve field values from a record
* Properties
   ##### Parameters
   * sobjectName: The relevant sobject name
   * rowId: The row ID of the required record
   * fields: The comma separated set of required fields
   ##### Returns
   * Json Response or salesforce:SalesforceConnectorError

[getFieldValuesFromExternalObjectRecord()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_get_field_values_external_object.htm)
Retrieve field values from an external record
* Properties
   ##### Parameters
   * sobjectName: The relevant sobject name
   * rowId: The row ID of the required record
   * fields: The comma separated set of required fields
   ##### Returns
   * Json Response or salesforce:SalesforceConnectorError
   
[getUpdatedRecords()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_getupdated.htm?search_text=updated)
Retrieves the list of individual records that have been updated (added or changed) within the given timespan for the specified object
* Properties
   ##### Parameters
    * sobjectName: The relevant sobject name
    * startTime: The start time of the time span
    * endTime: The end time of the time span
    ##### Returns
    * Json Response or salesforce:SalesforceConnectorError

[getDeletedRecords()]()
Retrieves the list of individual records that have been deleted within the given timespan for the specified object
* Properties
   ##### Parameters
    * sobjectName: The relevant sobject name
    * startTime: The start time of the time span
    * endTime: The end time of the time span
   ##### Returns
    * Json Response or salesforce:SalesforceConnectorError

[explainQueryOrReportOrListview()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_query_explain.htm?search_text=explain)
Get feedback on how Salesforce will execute the query, report, or list view based on performance
* Properties
   ##### Parameters
    * queryReportOrListview: The parameter to get feedback on
   ##### Returns
    * Json Response or salesforce:SalesforceConnectorError

[searchSOSLString()](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_search.htm?search_text=feedback)
Executes the specified SOSL search
* Properties
   ##### Parameters
    * searchString: The request SOSL string
   ##### Returns
    * Json Response or salesforce:SalesforceConnectorError

#### Account: SObject specific
getAccountById()

Accesses Account SObject records based on the Account object ID
* Properties
   ##### Parameters
    * accountId: The relevant account's id
   ##### Returns
    * Json Response or salesforce:SalesforceConnectorError
 
createAccount(): 
Creates new Account object record
* Properties
   ##### Parameters
    * accountRecord: json payload containing Account record data
   ##### Returns
    * String ID or salesforce:SalesforceConnectorError  
    
updateAccount(): 
Updates existing Account object record
* Properties
   ##### Parameters
    * accountId: Specified account id
    * accountRecord: json payload containing Account record data
   ##### Returns
    * boolean (if success: true, else: false) or salesforce:SalesforceConnectorError
    
deleteAccount(): 
Deletes existing Account's records
* Properties
   ##### Parameters
    * accountId: Specified account id
   ##### Returns
    * boolean (if success: true, else: false) or salesforce:SalesforceConnectorError

#### Product: SObject specific
getProductById(): 
Accesses Product SObject records based on the Product object ID
* Properties
   ##### Parameters
    * productId: The relevant Product's id
   ##### Returns
    * Json Response or salesforce:SalesforceConnectorError
    
createProduct(): 
Creates new Product object record
* Properties
   ##### Parameters
    * productRecord: json payload containing Product record data
   ##### Returns
    * String ID or salesforce:SalesforceConnectorError  
    
updateProduct(): 
Updates existing Product object record
* Properties
   ##### Parameters
    * productId: Specified Product id
    * productRecord: json payload containing Product record data
   ##### Returns
    * boolean (if success: true, else: false) or salesforce:SalesforceConnectorError
    
deleteProduct(): 
Deletes existing Product's records
* Properties
   ##### Parameters
    * productId: Specified Product id
   ##### Returns
    * boolean (if success: true, else: false) or salesforce:SalesforceConnectorError

#### Opportunity: SObject specific
getOpportunityById(): 
Accesses Opportunity SObject records based on the Opportunity object ID
* Properties
   ##### Parameters
    * opportunityId: The relevant Opportunity's id
   ##### Returns
    * Json Response or salesforce:SalesforceConnectorError
     
createOpportunity(): 
Creates new Opportunity object record
* Properties
   ##### Parameters
    * opportunityRecord: json payload containing Opportunity record data
   ##### Returns
    * String ID or salesforce:SalesforceConnectorError 
    
updateOpportunity(): 
Updates existing Opportunity object record
* Properties
   ##### Parameters
    * opportunityId: Specified Product id
    * opportunityRecord: json payload containing Product record data
   ##### Returns
    * boolean (if success: true, else: false) or salesforce:SalesforceConnectorError
    
deleteOpportunity(): 
Deletes existing Opportunity's records
* Properties
   ##### Parameters
    * opportunityId: Specified Opportunity id
   ##### Returns
    * boolean (if success: true, else: false) or salesforce:SalesforceConnectorError
    
#### Lead: SObject specific
getLeadById(): 
Accesses Lead SObject records based on the Lead object ID
* Properties
   ##### Parameters
    * leadId: The relevant Lead's id
   ##### Returns
    * Json Response or salesforce:SalesforceConnectorError
    
createLead(): 
Creates new Lead object record
* Properties
   ##### Parameters
    * leadRecord: json payload containing Lead record data
   ##### Returns
    * String ID or salesforce:SalesforceConnectorError 
    
updateLead(): 
Updates existing Lead object record
* Properties
   ##### Parameters
    * leadId: Specified Lead id
    * leadRecord: json payload containing Lead record data
   ##### Returns
    * boolean (if success: true, else: false) or salesforce:SalesforceConnectorError
    
deleteLead(): 
Deletes existing Lead's records
* Properties
   ##### Parameters
    * leadId: Specified Lead id
   ##### Returns
    * boolean (if success: true, else: false) or salesforce:SalesforceConnectorError

#### Contact: SObject specific
getContactById(): 
Accesses Contact SObject records based on the Contact object ID
* Properties
   ##### Parameters
    * contactId: The relevant Contact's id
   ##### Returns
    * Json Response or salesforce:SalesforceConnectorError
    
createContact(): 
Creates new Contact object record
* Properties
   ##### Parameters
    * contactRecord: json payload containing Contact record data
   ##### Returns
    * String ID or salesforce:SalesforceConnectorError 
    
updateContact(): 
Updates existing Contact object record
* Properties
   ##### Parameters
    * contactId: Specified Contact id
    * contactRecord: json payload containing Contact record data
   ##### Returns
    * boolean (if success: true, else: false) or salesforce:SalesforceConnectorError
    
deleteContact(): 
Deletes existing Contact's records
* Properties
   ##### Parameters
    * contactId: Specified Contact id
   ##### Returns
    * boolean (if success: true, else: false) or salesforce:SalesforceConnectorError
