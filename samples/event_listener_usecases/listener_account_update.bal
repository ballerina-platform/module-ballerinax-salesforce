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

import ballerinax/sfdc;
import ballerina/io;
import ballerina/log;

sfdc:ListenerConfiguration listenerConfig = {
    username: "<user_name>",
    password: "<password>"
};

listener sfdc:Listener eventListener = new (listenerConfig);

//service to catch event when an account is updated
@sfdc:ServiceConfig {topic: "/topic/AccountUpdate"}
service /topic/AccountUpdate on eventListener {
    remote function onEvent(json op) {
        io:StringReader sr = new (op.toJsonString());
        json|error account = sr.readJson();
        if (account is json) {
            json|error accountName = account.sobject.Name;
            if (accountName is json){
                log:printInfo(accountName.toString() + " Account Updated");
            }
        }
    }
}

