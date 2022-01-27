import ballerinax/salesforce as sfdc;
import ballerina/io;


sfdc:ListenerConfiguration listenerConfig = {
   username: "<USER_NAME>",
   password: "<PASSWORD>"
};
listener sfdc:Listener eventListener = new (listenerConfig);


service on eventListener {
    remote function onCreate(sfdc:EventData quoteUpdate) {
        json quote = quoteUpdate.changedData.get("Status");
        io:println("Quote Status : ", quote);
    }
}