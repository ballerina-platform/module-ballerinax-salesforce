//
// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
//

// Salesforce account session ID
final string SESSION_ID = "00D2v000001XKxi!AQ4AQPbuMTyFqHLOM.qUPaHmY.R_9LIUVFivlWFQFiejPqgJx8M_sXBDOe4.vmce1Yp5dhL3UzX1UzT4LkBdJPywkHTRpnqk";
// XML namespace used by salesforce responses
final string XML_NAMESPACE = "http://www.force.com/2009/06/asyncapi/dataload";

// Content types
final string APP_XML =  "application/xml; charset=UTF-8";
final string APP_JSON =  "application/json; charset=UTF-8";
final string TEXT_CSV = "text/csv; charset=UTF-8";
final string APP_OCT_STREAM = "application/octet-stream";

// Salesforce terms
final string JOB = "job";
final string BATCH = "batch";
final string REQUEST = "request";
final string RESULT = "result";

// characters and words
final string EMPTY_STRING = "";
final string FORWARD_SLASH = "/";
final string QUESTION_MARK = "?";
final string EQUAL_SIGN = "=";
final string AMPERSAND = "&";
final string OPEN_CURLY_BRACKET = "{";
final string CLOSE_CURLY_BRACKET = "}";
final string TRUE = "true";
final string ENCODING_CHARSET_UTF_8 = "utf-8";
final string CONTENT_TYPE = "Content-Type";
final string X_SFDC_SESSION = "X-SFDC-Session";
final string ENABLE_PK_CHUNKING = "Sforce-Enable-PKChunking";

// Payloads
final json JSON_STATE_CLOSED_PAYLOAD = { state : "Closed" };
final json JSON_STATE_ABORTED_PAYLOAD = { state : "Aborted" };
final xml XML_STATE_CLOSED_PAYLOAD = xml `<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">
    <state>Closed</state>
</jobInfo>`;
final xml XML_STATE_ABORTED_PAYLOAD = xml `<jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">
    <state>Aborted</state>
</jobInfo>`;

// Bulk API Operators
final string INSERT = "insert";
final string UPSERT = "upsert";
final string UPDATE = "update";
final string DELETE = "delete";
final string QUERY = "query";

// Content types allowed by Bulk API
final string CSV = "CSV";
final string XML = "XML";
final string JSON = "JSON";
