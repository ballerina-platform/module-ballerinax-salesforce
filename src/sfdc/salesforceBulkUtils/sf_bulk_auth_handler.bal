// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/auth;
import ballerina/http;

# Representation of the Bearer Auth header handler for both inbound and outbound HTTP traffic.
#
# + authProvider - The `InboundAuthProvider` instance or the `OutboundAuthProvider` instance.
public type SalesforceBulkAuthHandler object {

    *http:OutboundAuthHandler;

    public auth:OutboundAuthProvider authProvider;

    public function init(auth:OutboundAuthProvider authProvider) {
        self.authProvider = authProvider;
    }

    # Prepares the request with the Bearer Auth header.
    #
    # + req - The`Request` instance.
    # + return - Returns the updated `Request` instance or the `AuthenticationError` in case of an error.
    public function prepare(http:Request req) returns http:Request|http:AuthenticationError {
        var authProvider = self.authProvider;
        var token = authProvider.generateToken();
        if (token is string) {
            req.setHeader(X_SFDC_SESSION, token);
            return req;
        } else {
            return prepareAuthenticationError("Failed to prepare request at bearer auth handler.", token);
        }
    }

    # Inspects the request and response and calls the Auth provider for inspection.
    #
    # + req - The `Request` instance.
    # + resp - The `Response` instance.
    # + return - Returns the updated `Request` instance, the `AuthenticationError` in case of an error,
    # or `()` if nothing is to be returned.
    public function inspect(http:Request req, http:Response resp) returns http:Request|http:AuthenticationError? {
        var authProvider = self.authProvider;
        map<anydata> headerMap = createResponseHeaderMap(resp);
        var token = authProvider.inspect(headerMap);
        if (token is string) {
            req.setHeader(X_SFDC_SESSION, token);
            return req;
        } else if (token is auth:Error) {
            return prepareAuthenticationError("Failed to inspect at bearer auth handler.", token);
        }
        return ();
    }
};
