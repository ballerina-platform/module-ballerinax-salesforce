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

# Triggers when a new event related to Salesforce records is received.
# Available actions: onCreate, onUpdate, onDelete, and onRestore
public type RecordService service object {
    # Triggers on a new record create event.
    #
    # + payload - The information about the triggered event
    # + return - `()` on success else an `error`
    remote function onCreate(EventData payload) returns error?;

    # Triggers on a record update event.
    #
    # + payload - The information about the triggered event
    # + return - `()` on success else an `error` 
    remote function onUpdate(EventData payload) returns error?;

    # Triggers on a record delete event.
    #
    # + payload - The information about the triggered event
    # + return - `()` on success else an `error`
    remote function onDelete(EventData payload) returns error?;

    # Triggers on a record restore event.
    #
    # + payload - The information about the triggered event
    # + return - `()` on success else an `error`
    remote function onRestore(EventData payload) returns error?;
};
