// // Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
// //
// // WSO2 Inc. licenses this file to you under the Apache License,
// // Version 2.0 (the "License"); you may not use this file except
// // in compliance with the License.
// // You may obtain a copy of the License at
// //
// // http://www.apache.org/licenses/LICENSE-2.0
// //
// // Unless required by applicable law or agreed to in writing,
// // software distributed under the License is distributed on an
// // "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// // KIND, either express or implied.  See the License for the
// // specific language governing permissions and limitations
// // under the License.
// //
// import ballerina/oauth2;
// import ballerina/http;

// # Representation of the Bearer Auth header handler for both inbound and outbound HTTP traffic.
// #
// # + authProvider - The `ClientOAuth2Provider` instance to handle auth requests. 
// public client class SalesforceAuthHandler {

//     oauth2:ClientOAuth2Provider authProvider;

//     public isolated function init(http:OAuth2RefreshTokenGrantConfig auth2Congif) {
//         self.authProvider = new (auth2Congif);
//     }

//     public isolated function enrich(http:Request req) returns http:Request|http:ClientAuthError {
//         string|oauth2:Error token = self.authProvider.generateToken();
//         if (token is string) {
//             //req.setHeader(AUTHORIZATION, BEARER + token);
//             req.setHeader(X_SFDC_SESSION, token);
//             return req;
//         } else {
//             return prepareClientAuthError("Failed to enrich request with OAuth2 token.", token);
//         }
//     }
// }
