//
// Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

# Bulk operator abstract client.
public type BulkOperator abstract client object {
    JobInfo job;
    SalesforceBaseClient httpBaseClient;

    # Get job information.
    #
    # + return - JobInfo record if successful else ConnectorError occured
    public remote function getJobInfo() returns @tainted JobInfo|ConnectorError;

    # Close job.
    #
    # + return - JobInfo record if successful else ConnectorError occured
    public remote function closeJob() returns @tainted JobInfo|ConnectorError;

    # Abort job.
    #
    # + return - JobInfo record if successful else ConnectorError occured
    public remote function abortJob() returns @tainted JobInfo|ConnectorError;

    # Get batch information.
    #
    # + batchId - batch ID 
    # + return - BatchInfo record if successful else ConnectorError occured
    public remote function getBatchInfo(string batchId) returns @tainted BatchInfo|ConnectorError;

    # Get information of all batches of the job.
    #
    # + return - BatchInfo[] if successful else ConnectorError occured
    public remote function getAllBatches() returns @tainted BatchInfo[]|ConnectorError;
};
