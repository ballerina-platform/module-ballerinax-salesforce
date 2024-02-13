type QuoteRequest record {|
    string oppName;
    string accountName;
    ItemData[] itemData = [];
|};

type ItemData record {|
    string itemId;
    int quantity = 0;
|};

type Id record {|
    string Id;
|};

type PriceBookEntry record {|
    decimal UnitPrice;
|};

type OpportunityProduct record {|
    string OpportunityId;
    string Working_with_3rd_party__c = "No";
    string Product2Id;
    int Quantity;
    decimal UnitPrice;
|};

type Opportunity record {|
    string Name;
    string CurrencyIsoCode = "USD";
    string LeadSource = "Customer Inbound";
    string AccountId;
    string ForecastCategoryName = "Pipeline";
    string CloseDate = "2023-12-18";
    string StageName = "40 - Negotiation/Review";
    string Confidence__c = "Low";
    string Pricebook2Id = "01s6C000000UN4PQAW";
    string Working_with_3rd_party__c = "No";
|};
