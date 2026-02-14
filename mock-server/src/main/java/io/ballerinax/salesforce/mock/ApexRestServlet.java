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

import com.google.gson.Gson;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Simulates the Salesforce Apex REST API for testing apexRestExecute operations.
 */
public class ApexRestServlet extends HttpServlet {

    private static final Logger log = LoggerFactory.getLogger(ApexRestServlet.class);
    private static final Gson gson = new Gson();
    private static final Map<String, Map<String, Object>> cases = new ConcurrentHashMap<>();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String pathInfo = req.getPathInfo();
        log.info("Apex REST POST: {}", pathInfo);

        Map<String, Object> requestBody = parseRequestBody(req);
        String caseId = "500" + UUID.randomUUID().toString().replace("-", "").substring(0, 15);
        cases.put(caseId, requestBody);

        resp.setContentType("application/json");
        resp.setStatus(HttpServletResponse.SC_CREATED);
        // Return just the case ID as a JSON string (Salesforce Apex REST returns the ID as a string)
        resp.getWriter().write("\"" + caseId + "\"");
        log.info("Created Apex case: {}", caseId);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String pathInfo = req.getPathInfo();
        log.info("Apex REST GET: {}", pathInfo);

        String caseId = extractCaseId(pathInfo);
        if (caseId != null && cases.containsKey(caseId)) {
            Map<String, Object> caseRecord = new HashMap<>(cases.get(caseId));
            caseRecord.put("Id", caseId);
            resp.setContentType("application/json");
            resp.setStatus(HttpServletResponse.SC_OK);
            resp.getWriter().write(gson.toJson(caseRecord));
        } else {
            // Return a mock case record
            Map<String, Object> mockCase = new HashMap<>();
            mockCase.put("Id", caseId != null ? caseId : "500MOCK000000001");
            mockCase.put("subject", "Mock Case");
            mockCase.put("status", "New");
            resp.setContentType("application/json");
            resp.setStatus(HttpServletResponse.SC_OK);
            resp.getWriter().write(gson.toJson(mockCase));
        }
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String pathInfo = req.getPathInfo();
        log.info("Apex REST DELETE: {}", pathInfo);

        String caseId = extractCaseId(pathInfo);
        if (caseId != null) {
            cases.remove(caseId);
        }
        resp.setStatus(HttpServletResponse.SC_OK);
    }

    @Override
    protected void doPut(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String pathInfo = req.getPathInfo();
        log.info("Apex REST PUT: {}", pathInfo);
        resp.setStatus(HttpServletResponse.SC_OK);
        resp.setContentType("application/json");
        resp.getWriter().write("{}");
    }

    private String extractCaseId(String pathInfo) {
        if (pathInfo == null) {
            return null;
        }
        // pathInfo: /Cases/{id}
        String[] parts = pathInfo.split("/");
        if (parts.length >= 3) {
            return parts[2];
        }
        return null;
    }

    private Map<String, Object> parseRequestBody(HttpServletRequest req) throws IOException {
        StringBuilder body = new StringBuilder();
        try (BufferedReader reader = req.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) {
                body.append(line);
            }
        }
        @SuppressWarnings("unchecked")
        Map<String, Object> result = gson.fromJson(body.toString(), Map.class);
        return result != null ? result : new HashMap<>();
    }
}
