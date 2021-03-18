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

import ballerina/log;
import ballerinax/sfdc;

public function main(){

    // Create Salesforce client configuration by reading from config file.
    sfdc:SalesforceConfiguration sfConfig = {
        baseUrl: "<BASE_URL>",
        clientConfig: {
            clientId: "<CLIENT_ID>",
            clientSecret: "<CLIENT_SECRET>",
            refreshToken: "<REFESH_TOKEN>",
            refreshUrl: "<REFRESH_URL>"
        }
    };

    // Create Salesforce client.
    sfdc:Client baseClient = checkpanic new(sfConfig);
    
    int totalRecords = 0;
    string sampleQuery = "SELECT name FROM Account";
    sfdc:SoqlResult|sfdc:Error res = baseClient->getQueryResult(sampleQuery);

    if (res is sfdc:SoqlResult) {
        if (res.totalSize > 0){
            totalRecords = res.records.length() ;
            string|error nextRecordsUrl = res["nextRecordsUrl"].toString();
            while (nextRecordsUrl is string && nextRecordsUrl.trim() != "") {
                log:print("Found new query result set! nextRecordsUrl:" + nextRecordsUrl);
                sfdc:SoqlResult|sfdc:Error nextRes = baseClient->getNextQueryResult(<@untainted>nextRecordsUrl);
                
                if (nextRes is sfdc:SoqlResult) {
                    totalRecords = totalRecords + nextRes.records.length();
                    res = nextRes;
                } 
            }
            log:print(totalRecords.toString() + " Records Recieved");
        }
        else{
            log:print("No Results Found");
        }
        
    } else {
        log:printError(msg = res.message());
    }

}
