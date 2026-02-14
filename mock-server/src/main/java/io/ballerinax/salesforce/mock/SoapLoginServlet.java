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

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.IOException;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Simulates the Salesforce SOAP login endpoint (/services/Soap/u/44.0/).
 * Accepts any username/password and returns a mock sessionId and serverUrl.
 */
public class SoapLoginServlet extends HttpServlet {

    private static final Logger log = LoggerFactory.getLogger(SoapLoginServlet.class);
    private static final String MOCK_SESSION_ID = "mock-session-id-12345";

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        StringBuilder body = new StringBuilder();
        try (BufferedReader reader = req.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) {
                body.append(line);
            }
        }

        log.info("SOAP login request received");
        String requestBody = body.toString();

        // Check if request contains login credentials
        if (!requestBody.contains("urn:login")) {
            sendFaultResponse(resp, "Invalid SOAP request: missing login element");
            return;
        }

        // Determine the server URL based on the request
        String scheme = req.getScheme();
        String serverName = req.getServerName();
        int serverPort = req.getServerPort();
        String serverUrl = String.format("%s://%s:%d/services/Soap/u/44.0/00D000000000000",
                scheme, serverName, serverPort);

        String responseXml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                + "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" "
                + "xmlns:sf=\"urn:partner.soap.sforce.com\">"
                + "<soapenv:Body>"
                + "<sf:loginResponse>"
                + "<sf:result>"
                + "<sf:sessionId>" + MOCK_SESSION_ID + "</sf:sessionId>"
                + "<sf:serverUrl>" + serverUrl + "</sf:serverUrl>"
                + "<sf:userId>005000000000001</sf:userId>"
                + "<sf:userInfo>"
                + "<sf:organizationId>00D000000000000</sf:organizationId>"
                + "<sf:userName>test@example.com</sf:userName>"
                + "</sf:userInfo>"
                + "</sf:result>"
                + "</sf:loginResponse>"
                + "</soapenv:Body>"
                + "</soapenv:Envelope>";

        resp.setContentType("text/xml");
        resp.setStatus(HttpServletResponse.SC_OK);
        resp.getWriter().write(responseXml);
        log.info("SOAP login response sent with sessionId: {}", MOCK_SESSION_ID);
    }

    private void sendFaultResponse(HttpServletResponse resp, String faultMessage) throws IOException {
        String faultXml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                + "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                + "<soapenv:Body>"
                + "<soapenv:Fault>"
                + "<faultstring>" + faultMessage + "</faultstring>"
                + "</soapenv:Fault>"
                + "</soapenv:Body>"
                + "</soapenv:Envelope>";

        resp.setContentType("text/xml");
        resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        resp.getWriter().write(faultXml);
    }
}
