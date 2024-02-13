import ballerinax/kafka;
import ballerinax/salesforce;

configurable string salesforceAccessToken = ?;
configurable string salesforceBaseUrl = ?;
configurable string salesforcePriceBookId = ?;

public type ProductPrice readonly & record {|
    string name;
    float unitPrice;
|};

public type ProductPriceUpdate readonly & record {|
    float UnitPrice;
|};

listener kafka:Listener priceListener = new (kafka:DEFAULT_URL, {
    groupId: "order-group-id",
    topics: "product-price-updates"
});

final salesforce:Client salesforce = check new ({
    baseUrl: salesforceBaseUrl,
    auth: {
        token: salesforceAccessToken
    }
});

service on priceListener {
    isolated remote function onConsumerRecord(ProductPrice[] prices) returns error? {
        foreach ProductPrice {name, unitPrice} in prices {
            stream<record {}, error?> retrievedStream = check salesforce->query(
                string `SELECT Id FROM PricebookEntry 
                    WHERE Pricebook2Id = '${salesforcePriceBookId}' AND 
                    Name = '${name}'`);
            record {}[] retrieved = check from record {} entry in retrievedStream
                select entry;
            anydata pricebookEntryId = retrieved[0]["Id"];
            if pricebookEntryId is string {
                ProductPriceUpdate updatedPrice = {UnitPrice: unitPrice};
                check salesforce->update("PricebookEntry", pricebookEntryId, updatedPrice);
            }
        }
    }
}
