import ballerinax/sfdc;
import ballerina/io;


sfdc:ListenerConfiguration listenerConfig = {
   username: "",
   password: ""
};
listener sfdc:Listener eventListener = new (listenerConfig);

@sfdc:ServiceConfig {
    channelName:"/data/ChangeEvents"
}
service on eventListener {
    resource function onCreate(sfdc:EventData quoteUpdate) {
        json quote = quoteUpdate.changedData.get("Status");
        io:println("Quote Status : ", quote);
    }
}