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

import java.io.IOException;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Simulates the Salesforce OAuth2 token endpoint.
 * Returns a mock access token for any valid request.
 */
public class OAuth2TokenServlet extends HttpServlet {

    private static final Logger log = LoggerFactory.getLogger(OAuth2TokenServlet.class);

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String scheme = req.getScheme();
        String serverName = req.getServerName();
        int serverPort = req.getServerPort();
        String instanceUrl = String.format("%s://%s:%d", scheme, serverName, serverPort);

        String responseJson = "{"
                + "\"access_token\":\"mock-access-token-" + System.currentTimeMillis() + "\","
                + "\"instance_url\":\"" + instanceUrl + "\","
                + "\"id\":\"https://login.salesforce.com/id/00D000000000000/005000000000001\","
                + "\"token_type\":\"Bearer\","
                + "\"issued_at\":\"" + System.currentTimeMillis() + "\","
                + "\"signature\":\"mock-signature\""
                + "}";

        resp.setContentType("application/json");
        resp.setStatus(HttpServletResponse.SC_OK);
        resp.getWriter().write(responseJson);
        log.info("OAuth2 token response sent");
    }
}
