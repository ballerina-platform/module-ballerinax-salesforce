import ballerinax/salesforce as sfdc;

sfdc:ListenerConfiguration listenerConfig = {
   username: "<USER_NAME>",
   password: "<PASSWORD>"
};
listener sfdc:Listener eventListener = new (listenerConfig);

@sfdc:ServiceConfig {
    channelName:"/data/ChangeEvents"
}
service on eventListener {
    remote function onCreate(string one, string two) {

    }
}