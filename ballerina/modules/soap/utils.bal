// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/lang.'boolean as booleanLib;
import ballerinax/salesforce;

isolated function buildXMLPayload(string sessionId, LeadConvert convert) returns string|error {
    string newOpportunity = convert?.doNotCreateOpportunity.toString();

    string accountRecordVal = EMPTY_STRING;
    if convert?.accountRecord is AccountRecord {       
        accountRecordVal = string `<urn:accountRecord><urn1:Id>${getValue(convert?.accountRecord?.id)}</urn1:Id>
        ${getRecordValue(convert?.accountRecord)}</urn:accountRecord>`;
    }

    string accountDedupeCheck = convert?.bypassAccountDedupeCheck is boolean ?
    string `<urn:bypassAccountDedupeCheck>${convert?.bypassAccountDedupeCheck.toString()}</urn:bypassAccountDedupeCheck>` 
    : EMPTY_STRING;

    string contactDedupeCheck = convert?.bypassContactDedupeCheck is boolean ?
    string `<urn:bypassContactDedupeCheck>${convert?.bypassContactDedupeCheck.toString()}</urn:bypassContactDedupeCheck>` 
    : EMPTY_STRING;

    string contactRecordVal = EMPTY_STRING;
    if convert?.contactRecord is ContactRecord {
        contactRecordVal = string `<urn:contactRecord><urn1:Id>${getValue(convert?.contactRecord?.id)}</urn1:Id>
        ${getRecordValue(convert?.contactRecord)}</urn:contactRecord>`;
    }

    string opportunityId = convert?.opportunityId is string ?
    string `<urn:opportunityId>${convert?.opportunityId.toString()}</urn:opportunityId>` : EMPTY_STRING;
    string opportunityName = convert?.opportunityName is string ?
    string `<urn:opportunityName>${convert?.opportunityName.toString()}</urn:opportunityName>` : EMPTY_STRING;

    string opportunityRecordVal = EMPTY_STRING;
    if convert?.opportunityRecord is OpportunityRecord {
        opportunityRecordVal =
        string `<urn:opportunityRecord><urn1:Id>${getValue(convert?.opportunityRecord?.id)}</urn1:Id>
        ${getRecordValue(convert?.opportunityRecord)}</urn:opportunityRecord>`;
    }

    string overwriteLeadSource = convert?.overwriteLeadSource is boolean ?
    string `<urn:overwriteLeadSource>${convert?.overwriteLeadSource.toString()}</urn:overwriteLeadSource>` 
    : EMPTY_STRING;

    string ownerId = convert?.ownerId is string ? 
    string `<urn:ownerId>${convert?.ownerId.toString()}</urn:ownerId>` : EMPTY_STRING;
    
    string notification = convert?.sendNotificationEmail is boolean ?
    string `<urn:sendNotificationEmail>${convert?.sendNotificationEmail.toString()}</urn:sendNotificationEmail>` 
    : EMPTY_STRING;

    string header = string `<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
        xmlns:urn="urn:enterprise.soap.sforce.com"
        xmlns:urn1="urn:sobject.enterprise.soap.sforce.com">
        <soapenv:Header>
            <urn:SessionHeader>
                <urn:sessionId>${sessionId}</urn:sessionId>
            </urn:SessionHeader>
        </soapenv:Header>
        <soapenv:Body>
            <urn:convertLead>
                <urn:leadConverts>
                    <urn:accountId>${getValue(convert?.accountId)}</urn:accountId>
                    <urn:contactId>${getValue(convert?.contactId)}</urn:contactId>
                    ${accountRecordVal}
                    ${accountDedupeCheck}
                    ${contactDedupeCheck}
                    <urn:contactId>${getValue(convert?.contactId)}</urn:contactId>
                    ${contactRecordVal}
                    <urn:convertedStatus>${convert.convertedStatus}</urn:convertedStatus>
                    <urn:doNotCreateOpportunity>${newOpportunity}</urn:doNotCreateOpportunity>
                    <urn:leadId>${convert.leadId}</urn:leadId>
                    ${opportunityId}
                    ${opportunityName}
                    ${opportunityRecordVal}
                    ${ownerId}
                    ${overwriteLeadSource}
                    ${notification}
                </urn:leadConverts>
            </urn:convertLead>
        </soapenv:Body>
    </soapenv:Envelope>`;
    return header;
}

isolated function getValue(string? val) returns string {
    string str = val is string ? val : EMPTY_STRING;
    return str;
}

isolated function getRecordValue(AccountRecord?|ContactRecord?|OpportunityRecord? rec) returns string {
    string[]? accountFields = rec?.fieldsToNull;
    string fields = EMPTY_STRING;
    if accountFields is string[] {
        foreach string item in accountFields {
            fields += string `<urn1:fieldsToNull>${item}</urn1:fieldsToNull>`;
        }
    }
    return fields;
}

isolated function createResponse(http:Response response) returns ConvertedLead|error {
    xml formattedPayload = check formatPayload(response);
    if response.statusCode == http:STATUS_OK {
        xml xmlStatus = formattedPayload/**/<success>/*;
        boolean status = check booleanLib:fromString(xmlStatus.toString());
        if status {
            return createRecord(formattedPayload/**/<result>);
        } else {
            return error((formattedPayload/**/<errors>/*).toString());
        }
    } else {
        return error(formattedPayload.toString());
    }
}

isolated function formatPayload(http:Response response) returns xml|error {
    xml elements = check response.getXmlPayload();
    string formattedXMLResponse = re `${SOAP_ENV}`.replaceAll(elements.toString(), SOAP_ENV_);
    formattedXMLResponse = re `${XMLNS_SOAP}`.replaceAll(formattedXMLResponse, salesforce:EMPTY_STRING);
    formattedXMLResponse = re `${XMLNS}`.replaceAll(formattedXMLResponse, salesforce:EMPTY_STRING);
    formattedXMLResponse = re `${XMLNS_XSI}`.replaceAll(formattedXMLResponse, salesforce:EMPTY_STRING);
    formattedXMLResponse = re `${XSI}`.replaceAll(formattedXMLResponse, XSI_);
    return check 'xml:fromString(formattedXMLResponse);
}

isolated function createRecord(xml payload) returns ConvertedLead {
    ConvertedLead lead = {
        accountId: (payload/<accountId>/*).toString(),
        contactId: (payload/<contactId>/*).toString(),
        leadId: (payload/<leadId>/*).toString()
    };
    string opportunityId = (payload/<opportunityId>/*).toString();
    if opportunityId != salesforce:EMPTY_STRING {
        lead.opportunityId = opportunityId;
    }
    return lead;
}

isolated function getSessionId(http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler clientHandler,
                                string? contentType = ()) returns string|http:ClientAuthError {
    map<string|string[]> authorizationHeaderMap= {};
    if clientHandler is http:ClientOAuth2Handler {
        authorizationHeaderMap = check clientHandler.getSecurityHeaders();
    } else if clientHandler is http:ClientBearerTokenAuthHandler {
        authorizationHeaderMap = check clientHandler.getSecurityHeaders();
    }
    return (re ` `. split(<string>authorizationHeaderMap[AUTHORIZATION]))[1];
}
