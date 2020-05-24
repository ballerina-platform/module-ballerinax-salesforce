import ballerina/log;
import ballerina/test;

@test:Config {
    dependsOn: ["updateXml", "insertXmlFromFile"]
}
function queryXml() {
    log:printInfo("bulkClient -> queryXml");
    string batchId = "";

    string queryStr = "SELECT Id, Name FROM Contact WHERE Title='Professor Grade 05'";

    //create job
    error|BulkJob queryJob = bulkClient->creatJob("query", "Contact", "XML");

    if(queryJob is BulkJob){
        //add xml content
        error|BatchInfo batch = queryJob->addBatch(queryStr);
        if(batch is BatchInfo){
            test:assertTrue(batch.id.length() > 0, msg = "Could not upload batch.");
            batchId = batch.id;
        } else {
            test:assertFail(msg = batch.detail()?.message.toString());
        }

        //get job info
        error|JobInfo jobInfo = bulkClient->getJobInfo(queryJob);
        if (jobInfo is JobInfo) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = jobInfo.detail()?.message.toString());
        }

        //get batch info
        error|BatchInfo batchInfo = queryJob->getBatchInfo(batchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.detail()?.message.toString());
        }

        //get all batches
        error|BatchInfo[] batchInfoList = queryJob->getAllBatches();
        if (batchInfoList is BatchInfo[]) {
            test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = batchInfoList.detail()?.message.toString());
        }

        //get batch request
        var batchRequest = queryJob->getBatchRequest(batchId);
        if (batchRequest is string) {
            test:assertTrue(batchRequest.startsWith("SELECT"), msg = "Retrieving batch request failed.");
        } else if (batchRequest is error) {
            test:assertFail(msg = batchRequest.detail()?.message.toString());
        } else {
            test:assertFail(msg = "Invalid Batch Request!");
        }
        
        //get batch result
        var batchResult = queryJob->getBatchResult(batchId);
        if (batchResult is xml) {
            test:assertTrue((batchResult/<*>).length() == 5, msg = "Retrieving batch result failed.");
            xmlQueryResult = <@untainted> batchResult;
        } else if (batchResult is error) {
            test:assertFail(msg = batchResult.detail()?.message.toString());
        } else {
            test:assertFail("Invalid Batch Result!");
        }

        //close job
        error|JobInfo closedJob = bulkClient->closeJob(queryJob);
        if (closedJob is JobInfo) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.detail()?.message.toString());
        }
        
    } else {
        test:assertFail(msg = queryJob.detail()?.message.toString());
    }
}
