//
// Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

documentation { Errors by Salesforce
    F{{message}} Salesforce error message
    F{{errorCode}} Error code
}
public type SalesforceError {
    string message;
    string errorCode;
};

documentation {Errors by HTTP or Salesforce
    F{{message}} Array of string error messages
    F{{cause}} Array of errors
    F{{salesforceErrors}} Array of SalesforceError type errors
}
public type SalesforceConnectorError {
    string message;
    error? cause;
    SalesforceError[] salesforceErrors;
};
