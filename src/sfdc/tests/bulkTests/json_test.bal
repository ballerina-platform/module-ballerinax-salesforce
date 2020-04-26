import ballerina/io;
import ballerina/log;
import ballerina/test;

@test:Config {}
function testJsonJob() {
    log:printInfo("salesforceBulkClient -> jsonJob");
    string batchId = "";

    json contacts = [
        {
            description: "Created_from_Ballerina_Sf_Bulk_API",
            FirstName: "Morne",
            LastName: "Morkel",
            Title: "Professor Grade 03",
            Phone: "0442226670",
            Email: "morne89@gmail.com"
        },
        {
            description: "Created_from_Ballerina_Sf_Bulk_API",
            FirstName: "Andi",
            LastName: "Flower",
            Title: "Professor Grade 03",
            Phone: "0442216170",
            Email: "flower.andie@gmail.com"
        }
    ];
    
    string jsonContactsFilePath = "src/sfdc/tests/resources/contacts.json";

    //create job
    error|BulkJob insertJob = bulkClient->creatJob("insert", "Contact", "JSON");

    if(insertJob is BulkJob){
        //add json content
        error|BatchInfo batch = insertJob->addBatch(contacts);
        if(batch is BatchInfo){
            test:assertTrue(batch.id.length() > 0, msg = "Could not upload the contacts using json.");
            batchId = batch.id;
        } else {
            test:assertFail(msg = batch.detail()?.message.toString());
        }

        //add json content via file
        io:ReadableByteChannel|io:Error rbc = io:openReadableFile(jsonContactsFilePath);
        if (rbc is io:ReadableByteChannel) {
            error|BatchInfo batchUsingJsonFile = insertJob->addBatch(<@untained> rbc);
            if (batchUsingJsonFile is BatchInfo) {
                test:assertTrue(batchUsingJsonFile.id.length() > 0, msg = "Could not upload the contacts using json file.");
            } else {
                test:assertFail(msg = batchUsingJsonFile.detail()?.message.toString());
            }
            // close channel.
            closeRb(rbc);
        } else {
            test:assertFail(msg = rbc.detail()?.message.toString());
        }

        //get job info
        error|JobInfo jobInfo = bulkClient->getJobInfo(insertJob);
        if (jobInfo is JobInfo) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = jobInfo.detail()?.message.toString());
        }

        //get batch info
        error|BatchInfo batchInfo = insertJob->getBatchInfo(batchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.detail()?.message.toString());
        }

        //get all batches
        error|BatchInfo[] batchInfoList = insertJob->getAllBatches();
        if (batchInfoList is BatchInfo[]) {
            test:assertTrue(batchInfoList.length() == 2, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = batchInfoList.detail()?.message.toString());
        }

        //get batch request
        var batchRequest = insertJob->getBatchRequest(batchId);
        if (batchRequest is json) {
            json[]|error batchRequestArr = <json[]> batchRequest;
            if (batchRequestArr is json[]) {
                test:assertTrue(batchRequestArr.length() == 2, msg = "Retrieving batch request failed.");                
            } else {
                test:assertFail(msg = batchRequestArr.toString());
            }
        } else {
            test:assertFail(msg = "Invalid Batch Request Type!");
        }

        //get batch result
        error|Result[] batchResult = insertJob->getBatchResult(batchId);
        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
        } else {
            test:assertFail(msg = batchResult.detail()?.message.toString());
        }

        //close job
        error|JobInfo closedJob = bulkClient->closeJob(insertJob);
        if (closedJob is JobInfo) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.detail()?.message.toString());
        }
    } else {
        test:assertFail(msg = insertJob.detail()?.message.toString());
    }
}
