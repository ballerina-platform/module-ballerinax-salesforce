import ballerinax/trigger.salesforce;
import ballerinax/twilio;

type SalesforceListenerConfig record {|
    string username;
    string password;
|};

type TwilioClientConfig record {|
    string accountSId;
    string authToken;
|};

// Salesforce configuration parameters
configurable SalesforceListenerConfig salesforceListenerConfig = ?;

// Twilio configuration parameters
configurable TwilioClientConfig twilioClientConfig = ?;
configurable string fromNumber = ?;
configurable string toNumber = ?;

listener salesforce:Listener sfdcEventListener = new ({
    username: salesforceListenerConfig.username,
    password: salesforceListenerConfig.password,
    channelName: "/data/ContactChangeEvent"
});

final twilio:Client twilio = check new ({
    twilioAuth: {
        accountSId: twilioClientConfig.accountSId,
        authToken: twilioClientConfig.authToken
    }
});

service salesforce:RecordService on sfdcEventListener {
    isolated remote function onCreate(salesforce:EventData payload) returns error? {
        string[] nameParts = re `,`.split(payload.changedData["Name"].toString());
        string firstName = (nameParts.length() >= 2) ? re `=`.split(nameParts[0])[1] : "";
        string lastName = (nameParts.length() >= 2) ?
            re `=`.split(re `\}`.replace(nameParts[1], ""))[1] :
            re `=`.split(re `\}`.replace(nameParts[0], ""))[1];
        _ = check twilio->sendSms(fromNumber, toNumber,
            string `New contact is created! | Name: ${firstName} ${lastName} | Created Date: 
            ${(check payload.changedData.CreatedDate).toString()}`);
    }

    isolated remote function onUpdate(salesforce:EventData payload) returns error? {
        return;
    }

    isolated remote function onDelete(salesforce:EventData payload) returns error? {
        return;
    }

    isolated remote function onRestore(salesforce:EventData payload) returns error? {
        return;
    }
}
