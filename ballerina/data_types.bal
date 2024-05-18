// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

# Salesforce listener configuration.
# 
# + username - Salesforce login username
# + password - Salesforce login password appended with the security token (<password><security token>)
# + channelName - The channel name to which a client can subscribe to receive event notifications
# + replayFrom - The replay ID to change the point in time when events are read
#   - `-1` - Get all new events sent after subscription. This option is the default
#   - `-2` - Get all new events sent after subscription and all past events within the retention window
#   - `Specific number` - Get all events that occurred after the event with the specified replay ID
# + environment - The type of salesforce environment
#   - `PRODUCTION` - Production environment
#   - `SANDBOX` - Sandbox environment
#   - `DEVELOPER` - Developer environment
@display{label: "Listener Config"}
public type ListenerConfig record {|
    @display{label: "Username", "description": "Salesforce login username"}
    string username;
    @display{label: "Password", "description": "Salesforce login password appended with the security token (<password><security token>)"}
    string password;
    @display{label: "Channel Name", "description": "The channel name to which a client can subscribe to receive event notifications"}
    string channelName;
    @display{label: "Replay ID", "description": "The replay ID to change the point in time when events are read"}
    int replayFrom = REPLAY_FROM_TIP;
    @display{label: "Environment", "description": "The type of Salesforce environment"}
    string environment = PRODUCTION;
|};

# The type of Salesforce environment
# + PRODUCTION - Production environment
# + SANDBOX - Sandbox environment
# + DEVELOPER - Developer environment
public enum Organization {
    PRODUCTION = "Production",
    DEVELOPER = "Developer",
    SANDBOX = "Sandbox"
}

# Replay ID `-1` to get all new events sent after subscription. This option is the default
public const REPLAY_FROM_TIP = -1;
# Replay ID `-2` to get all new events sent after subscription and all past events within the retention window
public const REPLAY_FROM_EARLIEST = -2;

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
