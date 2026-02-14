/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerinax.salesforce.mock;

import org.cometd.bayeux.server.BayeuxServer;
import org.cometd.server.CometDServlet;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.servlet.ServletContextHandler;
import org.eclipse.jetty.servlet.ServletHolder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Mock Salesforce server that simulates the Salesforce Streaming API (CometD/Bayeux)
 * and SOAP login endpoint for testing the Ballerina Salesforce listener.
 */
public class MockSalesforceServer {

    private static final Logger log = LoggerFactory.getLogger(MockSalesforceServer.class);

    public static void main(String[] args) throws Exception {
        int port = Integer.parseInt(System.getenv().getOrDefault("SERVER_PORT", "8089"));

        Server server = new Server(port);

        ServletContextHandler context = new ServletContextHandler(ServletContextHandler.SESSIONS);
        context.setContextPath("/");
        server.setHandler(context);

        // CometD/Bayeux servlet for Streaming API
        ServletHolder cometdHolder = new ServletHolder("cometd", CometDServlet.class);
        cometdHolder.setInitParameter("ws.cometdURLMapping", "/cometd/*");
        cometdHolder.setInitParameter("timeout", "30000");
        cometdHolder.setInitParameter("interval", "0");
        cometdHolder.setInitParameter("maxInterval", "120000");
        cometdHolder.setInitParameter("long-polling.multiSessionInterval", "2000");
        cometdHolder.setInitOrder(1);
        context.addServlet(cometdHolder, "/cometd/*");

        // SOAP login endpoint
        ServletHolder loginHolder = new ServletHolder("login", SoapLoginServlet.class);
        context.addServlet(loginHolder, "/services/Soap/u/*");

        // Event trigger endpoint for tests to push CDC events
        ServletHolder eventHolder = new ServletHolder("event", EventTriggerServlet.class);
        context.addServlet(eventHolder, "/api/event/*");

        // REST API endpoint for CRUD operations
        ServletHolder restApiHolder = new ServletHolder("restApi", RestApiServlet.class);
        context.addServlet(restApiHolder, "/services/data/*");

        // OAuth2 token endpoint
        ServletHolder oauth2Holder = new ServletHolder("oauth2", OAuth2TokenServlet.class);
        context.addServlet(oauth2Holder, "/services/oauth2/token");

        // Apex REST endpoint
        ServletHolder apexRestHolder = new ServletHolder("apexRest", ApexRestServlet.class);
        context.addServlet(apexRestHolder, "/services/apexrest/*");

        // Health check endpoint
        ServletHolder healthHolder = new ServletHolder("health", HealthCheckServlet.class);
        context.addServlet(healthHolder, "/health");

        server.start();
        log.info("Mock Salesforce server started on port {}", port);

        // Register CometD services after the server is started
        BayeuxServer bayeuxServer = (BayeuxServer) context.getServletContext().getAttribute(BayeuxServer.ATTRIBUTE);
        if (bayeuxServer != null) {
            new MockStreamingService(bayeuxServer);
            // Store bayeux server reference for event trigger servlet
            context.getServletContext().setAttribute("mock.bayeuxServer", bayeuxServer);
            log.info("CometD/Bayeux server initialized with mock streaming service");
        } else {
            log.error("BayeuxServer not found in servlet context!");
        }

        server.join();
    }
}
