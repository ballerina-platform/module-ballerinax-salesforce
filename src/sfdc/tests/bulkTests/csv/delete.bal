import ballerina/log;
import ballerina/test;

@test:Config {
    dependsOn: ["queryCsv"]
}
function deleteCsv() {
    log:printInfo("bulkClient -> deleteCsv");
    string batchId = "";

    string contacts = getCsvContactsToDelete(csvQueryResult);

    //create job
    error|BulkJob deleteJob = bulkClient->creatJob("delete", "Contact", "CSV");

    if(deleteJob is BulkJob){
        //add csv content
        error|BatchInfo batch = deleteJob->addBatch(<@untained>  contacts);
        if(batch is BatchInfo){
            test:assertTrue(batch.id.length() > 0, msg = "Could not upload the contacts to delete using CSV.");
            batchId = batch.id;
        } else {
            test:assertFail(msg = batch.detail()?.message.toString());
        }

        //get job info
        error|JobInfo jobInfo = bulkClient->getJobInfo(deleteJob);
        if (jobInfo is JobInfo) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = jobInfo.detail()?.message.toString());
        }

        //get batch info
        error|BatchInfo batchInfo = deleteJob->getBatchInfo(batchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.detail()?.message.toString());
        }

        //get all batches
        error|BatchInfo[] batchInfoList = deleteJob->getAllBatches();
        if (batchInfoList is BatchInfo[]) {
            test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = batchInfoList.detail()?.message.toString());
        }

         //get batch request
        var batchRequest = deleteJob->getBatchRequest(batchId);
        if (batchRequest is string) {
            test:assertTrue(checkCsvResult(batchRequest) == 5, msg = "Retrieving batch request failed.");                
        } else if (batchRequest is error) {
            test:assertFail(msg = batchRequest.detail()?.message.toString());
        } else {
            test:assertFail(msg = "Invalid Batch Request!");
        }

        var batchResult = deleteJob->getBatchResult(batchId);
        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
            test:assertTrue(checkBatchResults(batchResult), msg = "Delete was not successful.");
        } else if (batchResult is error) {
            test:assertFail(msg = batchResult.detail()?.message.toString());
        } else {
            test:assertFail("Invalid Batch Result!");
        }

        //close job
        error|JobInfo closedJob = bulkClient->closeJob(deleteJob);
        if (closedJob is JobInfo) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.detail()?.message.toString());
        }
        
    } else {
        test:assertFail(msg = deleteJob.detail()?.message.toString());
    }
}
