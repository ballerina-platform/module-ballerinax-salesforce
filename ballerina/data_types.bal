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

# Configurations related to authentication.
#
# + username - Salesforce login username
# + password - Salesforce login password appended with the security token (<password><security token>)
public type CredentialsConfig record {|
    string username;
    string password;
|};

# Salesforce listener configuration.
# 
# + auth - Configurations related to username/password authentication
# + replayFrom - The replay ID to change the point in time when events are read
# + isSandBox - The type of salesforce environment, if sandbox environment or not
public type ListenerConfig record {|
    CredentialsConfig auth;
    int|ReplayOptions replayFrom = REPLAY_FROM_TIP;
    boolean isSandBox = false;
|};

# The replay options representing the point in time when events are read.
#
# + REPLAY_FROM_TIP - To get all new events sent after subscription. This option is the default
# + REPLAY_FROM_EARLIEST - To get all new events sent after subscription and all past events within the retention window
public enum ReplayOptions {
   REPLAY_FROM_TIP,
   REPLAY_FROM_EARLIEST
}

#  Contains data returned from a Change Data Event.
#
# + changedData - A JSON map which contains the changed data
# + metadata - Header fields that contain information about the event
public type EventData record {
    map<json> changedData;
    ChangeEventMetadata metadata?;
};

# Header fields that contain information about the event.
#
# + commitTimestamp - The date and time when the change occurred, represented as the number of milliseconds 
#                     since January 1, 1970 00:00:00 GMT
# + transactionKey - Uniquely identifies the transaction that the change is part of
# + changeOrigin - Origin of the change. Use this field to find out what caused the change.  
# + changeType - The operation that caused the change  
# + entityName - The name of the standard or custom object for this record change
# + sequenceNumber - Identifies the sequence of the change within a transaction
# + commitUser - The ID of the user that ran the change operation
# + commitNumber - The system change number (SCN) of a committed transaction
# + recordId - The record ID for the changed record
public type ChangeEventMetadata record {
    int commitTimestamp?;
    string transactionKey?;
    string changeOrigin?;
    string changeType?;
    string entityName?;
    int sequenceNumber?;
    string commitUser?;
    int commitNumber?;
    string recordId?;
};
