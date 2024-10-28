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
import ballerinax/'client.config;

public type ConnectionConfig record {|
    # The Salesforce endpoint URL
    string baseUrl;
    # Configurations related to client authentication
    http:BearerTokenConfig|config:OAuth2RefreshTokenGrantConfig auth;
    # The HTTP version understood by the client
    http:HttpVersion httpVersion = http:HTTP_2_0;
    # Configurations related to HTTP/1.x protocol
    ClientHttp1Settings http1Settings?;
    # Configurations related to HTTP/2 protocol
    http:ClientHttp2Settings http2Settings?;
    # The maximum time to wait (in seconds) for a response before closing the connection
    decimal timeout = 60;
    # The choice of setting `forwarded`/`x-forwarded` header
    string forwarded = "disable";
    # Configurations associated with request pooling
    http:PoolConfiguration poolConfig?;
    # HTTP caching related configurations
    http:CacheConfig cache?;
    # Specifies the way of handling compression (`accept-encoding`) header
    http:Compression compression = http:COMPRESSION_AUTO;
    # Configurations associated with the behaviour of the Circuit Breaker
    http:CircuitBreakerConfig circuitBreaker?;
    # Configurations associated with retrying
    http:RetryConfig retryConfig?;
    # Configurations associated with inbound response size limits
    http:ResponseLimitConfigs responseLimits?;
    # SSL/TLS-related options
    http:ClientSecureSocket secureSocket?;
    # Proxy server related options
    http:ProxyConfig proxy?;
    # Enables the inbound payload validation functionality which provided by the constraint package. Enabled by default
    boolean validation = true;
|};

# Provides settings related to HTTP/1.x protocol.
public type ClientHttp1Settings record {|
    # Specifies whether to reuse a connection for multiple requests
    http:KeepAlive keepAlive = http:KEEPALIVE_AUTO;
    # The chunking behaviour of the request
    http:Chunking chunking = http:CHUNKING_AUTO;
    # Proxy server related options
    ProxyConfig proxy?;
|};

# Proxy server configurations to be used with the HTTP client endpoint.
public type ProxyConfig record {|
    # Host name of the proxy server
    string host = "";
    # Proxy server port
    int port = 0;
    # Proxy server username
    string userName = "";
    # Proxy server password
    @display {label: "", kind: "password"}
    string password = "";
|};

# Represents converted lead.
#
# + accountId - Account ID  
# + contactId - Contact ID
# + leadId - Lead ID 
# + opportunityId - Opportunity ID
@display {label: "Converted Lead"}
public type ConvertedLead record {
    string accountId;
    string contactId;
    string leadId;
    string opportunityId?;
};

# Represents lead to be converted.
#
# + accountId - ID of the Account into which the lead will be merged
# + accountRecord - Account record to create
# + bypassAccountDedupeCheck - Specifies whether to eliminate duplicate copies of Account data 
# + bypassContactDedupeCheck - Specifies whether to eliminate duplicate copies of Contact data  
# + contactId - ID of the Contact into which the lead will be merged   
# + contactRecord - Contact record to create 
# + convertedStatus - Valid LeadStatus value for a converted lead 
# + doNotCreateOpportunity - Specifies whether to create an Opportunity during lead conversion(false) or not (true)
# + leadId - ID of the Lead to convert
# + opportunityId - The ID of an existing opportunity to relate to the lead. The opportunityId and opportunityName 
# arguments are mutually exclusive. Specifying a value for both results in an error
# If doNotCreateOpportunity argument is true, then no Opportunity is created and this field must be left blank; 
# otherwise, an error is returned
# + opportunityName - Name of the opportunity to create. If no name is specified, then this value defaults to the 
# company name of the lead
# + opportunityRecord - Opportunity record to create 
# + overwriteLeadSource - Specifies whether to overwrite the LeadSource field on the target Contact object with the 
# contents of the LeadSource field in the source Lead object (true), or not (false, the default)
# + ownerId - Specifies the ID of the person to own any newly created account, contact, and opportunity. If the client 
# application doesn’t specify this value, then the owner of the new object will be the owner of the lead
# + sendNotificationEmail - Specifies whether to send a notification email to the owner specified in the ownerId (true) 
# or not (false, the default)
public type LeadConvert record {|
    string accountId?;
    AccountRecord accountRecord?;
    boolean bypassAccountDedupeCheck?;
    boolean bypassContactDedupeCheck?;
    string contactId?;
    ContactRecord contactRecord?;
    string convertedStatus;
    boolean doNotCreateOpportunity = false;
    string leadId;
    string opportunityId?;
    string opportunityName?;
    OpportunityRecord opportunityRecord?;
    boolean overwriteLeadSource?;
    string ownerId?;
    boolean sendNotificationEmail?;
|};

# Account record.
public type AccountRecord record {|
    *Record;
|};

# Contact record.
public type ContactRecord record {|
    *Record;
|};

# Opportunity record.
public type OpportunityRecord record {|
    *Record;
|};

# Record.
#
# + fieldsToNull - Null fields in record  
# + id - Record ID
public type Record record {|
    string[] fieldsToNull?;
    string id?;
|};
