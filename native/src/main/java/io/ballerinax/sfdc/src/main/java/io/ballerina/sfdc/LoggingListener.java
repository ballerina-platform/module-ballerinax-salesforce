/*
 * Copyright (c) 2016, salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.TXT file in the repo root  or https://opensource.org/licenses/BSD-3-Clause
 */

package io.ballerina.sfdc;

import org.cometd.bayeux.Message;
import org.cometd.bayeux.client.ClientSessionChannel;

import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Commandline logger for Long polling
 */
public class LoggingListener implements ClientSessionChannel.MessageListener {

    private boolean logSuccess;
    private boolean logFailure;

    public LoggingListener() {
        this.logSuccess = true;
        this.logFailure = true;
    }

    public LoggingListener(boolean logSuccess, boolean logFailure) {
        this.logSuccess = logSuccess;
        this.logFailure = logFailure;
    }

    @Override
    public void onMessage(ClientSessionChannel clientSessionChannel, Message message) {
        if (logSuccess && message.isSuccessful()) {
            System.out.println(">>>>");
            printPrefix();
            System.out.println("Success:[" + clientSessionChannel.getId() + "]");
            System.out.println(message);
            System.out.println("<<<<");
        }

        if (logFailure && !message.isSuccessful()) {
            System.out.println(">>>>");
            printPrefix();
            System.out.println("Failure:[" + clientSessionChannel.getId() + "]");
            System.out.println(message);
            System.out.println("<<<<");
        }
    }

    private void printPrefix() {
        System.out.print("[" + timeNow() + "] ");
    }

    private String timeNow() {
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS");
        Date now = new Date();
        return dateFormat.format(now);
    }
}
