import ballerina/log;
import ballerina/test;

@test:Config {
    dependsOn: ["insertXml"]
}
function upsertXml() {
    log:printInfo("bulkClient -> upsertXml");
    string batchId = "";

    xml contacts = xml `<sObjects xmlns="http://www.force.com/2009/06/asyncapi/dataload">
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <FirstName>Lucas</FirstName>
            <LastName>Podolski</LastName>
            <Title>Professor Grade 05</Title>
            <Phone>0442254123</Phone>
            <Email>lucas@yahoo.com</Email>
            <My_External_Id__c>221</My_External_Id__c>
        </sObject>
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <FirstName>John</FirstName>
            <LastName>Wicks</LastName>
            <Title>Professor Grade 05</Title>
            <Phone>0442552550</Phone>
            <Email>wicks@gmail.com</Email>
            <My_External_Id__c>223</My_External_Id__c>
        </sObject>
    </sObjects>`;

    //create job
    error|BulkJob upsertJob = bulkClient->creatJob("upsert", "Contact", "XML", "My_External_Id__c");

    if(upsertJob is BulkJob){
        //add xml content
        error|BatchInfo batch = upsertJob->addBatch(contacts);
        if(batch is BatchInfo){
            test:assertTrue(batch.id.length() > 0, msg = "Could not upload the contacts using xml.");
            batchId = batch.id;
        } else {
            test:assertFail(msg = batch.detail()?.message.toString());
        }

        //get job info
        error|JobInfo jobInfo = bulkClient->getJobInfo(upsertJob);
        if (jobInfo is JobInfo) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = jobInfo.detail()?.message.toString());
        }

        //get batch info
        error|BatchInfo batchInfo = upsertJob->getBatchInfo(batchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.detail()?.message.toString());
        }

        //get all batches
        error|BatchInfo[] batchInfoList = upsertJob->getAllBatches();
        if (batchInfoList is BatchInfo[]) {
            test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = batchInfoList.detail()?.message.toString());
        }

         //get batch request
        var batchRequest = upsertJob->getBatchRequest(batchId);
        if (batchRequest is xml) {
            test:assertTrue((batchRequest/<*>).length() == 2, msg = "Retrieving batch request failed.");                
        } else if (batchRequest is error) {
            test:assertFail(msg = batchRequest.detail()?.message.toString());
        } else {
            test:assertFail("Invalid batch request!");
        }

        //get batch result
        var batchResult = upsertJob->getBatchResult(batchId);
        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
            test:assertTrue(checkBatchResults(batchResult), msg = "Upsert was not successful.");
        } else if (batchResult is error) {
            test:assertFail(msg = batchResult.detail()?.message.toString());
        } else {
            test:assertFail("Invalid Batch Result!");
        }

        //close job
        error|JobInfo closedJob = bulkClient->closeJob(upsertJob);
        if (closedJob is JobInfo) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.detail()?.message.toString());
        }
        
    } else {
        test:assertFail(msg = upsertJob.detail()?.message.toString());
    }
}
