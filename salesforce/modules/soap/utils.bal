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
import ballerina/regex;
import ballerinax/salesforce as sfdc;

isolated function buildXMLPayload(string sessionId, string leadId, boolean? opporinityNotRequired) returns string|error {
    string opportunity = opporinityNotRequired is boolean ? opporinityNotRequired.toString() : false.toString();
    string header = string `<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
        xmlns:urn="urn:enterprise.soap.sforce.com"
        xmlns:urn1="urn:sobject.enterprise.soap.sforce.com">
        <soapenv:Header>
            <urn:SessionHeader>
                <urn:sessionId>${
    sessionId}</urn:sessionId>
            </urn:SessionHeader>
        </soapenv:Header>
        <soapenv:Body>
            <urn:convertLead>
                <urn:leadConverts>
                    <urn:doNotCreateOpportunity>${
    opportunity}</urn:doNotCreateOpportunity>
                    <urn:convertedStatus>Closed - Converted</urn:convertedStatus>
                        <urn:leadId>${
    leadId}</urn:leadId>
                    </urn:leadConverts>
                </urn:convertLead>
            </soapenv:Body>
        </soapenv:Envelope>`;
    return header;
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
    string formattedXMLResponse = regex:replaceAll(elements.toString(), SOAP_ENV, SOAP_ENV_);
    formattedXMLResponse = regex:replaceAll(formattedXMLResponse, XMLNS_SOAP, sfdc:EMPTY_STRING);
    formattedXMLResponse = regex:replaceAll(formattedXMLResponse, XMLNS, sfdc:EMPTY_STRING);
    formattedXMLResponse = regex:replaceAll(formattedXMLResponse, XMLNS_XSI, sfdc:EMPTY_STRING);
    formattedXMLResponse = regex:replaceAll(formattedXMLResponse, XSI, XSI_);
    return check 'xml:fromString(formattedXMLResponse);
}

isolated function createRecord(xml payload) returns ConvertedLead {
    ConvertedLead lead = {
        accountId: (payload/<accountId>/*).toString(),
        contactId: (payload/<contactId>/*).toString(),
        leadId: (payload/<leadId>/*).toString()
    };
    string opportunityId = (payload/<opportunityId>/*).toString();
    if opportunityId != sfdc:EMPTY_STRING {
        lead.opportunityId = opportunityId;
    }
    return lead;
}

isolated function getSessionId(http:ClientOAuth2Handler|http:ClientBearerTokenAuthHandler clientHandler, 
                               string? contentType = ()) returns string|http:ClientAuthError {
    map<string|string[]> authorizationHeaderMap;
    if clientHandler is http:ClientOAuth2Handler {
        authorizationHeaderMap = check clientHandler.getSecurityHeaders();
    } else if clientHandler is http:ClientBearerTokenAuthHandler  {
        authorizationHeaderMap = check clientHandler.getSecurityHeaders();
    } else {
        return error("Invalid authentication handler");
    }
    return (regex:split(<string>authorizationHeaderMap[AUTHORIZATION], " "))[1];
}
