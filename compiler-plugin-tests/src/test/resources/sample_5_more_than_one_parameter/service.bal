import ballerinax/sfdc;

sfdc:ListenerConfiguration listenerConfig = {
   username: "",
   password: ""
};
listener sfdc:Listener eventListener = new (listenerConfig);

@sfdc:ServiceConfig {
    channelName:"/data/ChangeEvents"
}
service on eventListener {
    remote function onCreate(string one, string two) {

    }
}