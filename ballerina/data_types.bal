// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
import ballerina/oauth2;

# Configurations related to username/password authentication.
public type CredentialsConfig record {|
    # Salesforce login username
    string username;
    # Salesforce login password appended with the security token (<password><security token>)
    string password;
|};

# OAuth2 authentication configuration type.
public type OAuth2Config http:BearerTokenConfig|
    oauth2:PasswordGrantConfig|oauth2:RefreshTokenGrantConfig|oauth2:ClientCredentialsGrantConfig;

# Salesforce listener configuration.
public type ListenerConfig record {|
    # Authentication configuration for the listener
    CredentialsConfig|OAuth2Config auth;
    # The replay ID to change the point in time when events are read
    int|ReplayOptions replayFrom = REPLAY_FROM_TIP;
    # The type of salesforce environment, if sandbox environment or not
    boolean isSandBox = false;
    # The base URL of the Salesforce instance
    string baseUrl?;
    # The maximum time in seconds to wait for establishing a connection to the Salesforce streaming API
    decimal connectionTimeout = 30;
    # The maximum time in seconds to wait for the long polling transport before considering a request failed
    decimal readTimeout = 30;
    # The maximum duration in seconds that a connection is kept alive without activity
    decimal keepAliveInterval = 120;
    # The Salesforce API version to use for Streaming API
    string apiVersion = "43.0";
|};

# The replay options representing the point in time when events are read.
public enum ReplayOptions {
    # To get all new events sent after subscription. This option is the default
    REPLAY_FROM_TIP,
    # To get all new events sent after subscription and all past events within the retention window
    REPLAY_FROM_EARLIEST
}

# Contains data returned from a Change Data Event.
public type EventData record {
    # A JSON map which contains the changed data
    map<json> changedData;
    # Header fields that contain information about the event
    ChangeEventMetadata metadata?;
};

# Header fields that contain information about the event.
public type ChangeEventMetadata record {
    # The date and time when the change occurred, represented as the number of milliseconds since January 1, 1970 00:00:00 GMT
    int commitTimestamp?;
    # Uniquely identifies the transaction that the change is part of
    string transactionKey?;
    # Origin of the change. Use this field to find out what caused the change.
    string changeOrigin?;
    # The operation that caused the change
    string changeType?;
    # The name of the standard or custom object for this record change
    string entityName?;
    # Identifies the sequence of the change within a transaction
    int sequenceNumber?;
    # The ID of the user that ran the change operation
    string commitUser?;
    # The system change number (SCN) of a committed transaction
    int commitNumber?;
    # The record ID for the changed record
    string recordId?;
};
