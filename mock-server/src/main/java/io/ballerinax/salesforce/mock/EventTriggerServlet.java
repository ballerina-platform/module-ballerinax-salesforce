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
import com.google.gson.reflect.TypeToken;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.IOException;
import java.lang.reflect.Type;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * HTTP endpoint that allows tests to trigger mock CDC events.
 *
 * <p>Usage:
 * <pre>
 * POST /api/event
 * Content-Type: application/json
 *
 * {
 *   "channel": "/data/ChangeEvents",
 *   "changeType": "CREATE",
 *   "entityName": "Account",
 *   "recordId": "001xx000003DGbYAAW",
 *   "changedFields": {
 *     "Name": "John Keells Holdings",
 *     "BillingCity": "Colombo 3"
 *   }
 * }
 * </pre>
 */
public class EventTriggerServlet extends HttpServlet {

    private static final Logger log = LoggerFactory.getLogger(EventTriggerServlet.class);
    private static final Gson gson = new Gson();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        StringBuilder body = new StringBuilder();
        try (BufferedReader reader = req.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) {
                body.append(line);
            }
        }

        Type type = new TypeToken<Map<String, Object>>() {}.getType();
        Map<String, Object> request = gson.fromJson(body.toString(), type);

        String channel = (String) request.getOrDefault("channel", "/data/ChangeEvents");
        String changeType = (String) request.getOrDefault("changeType", "CREATE");
        String entityName = (String) request.getOrDefault("entityName", "Account");
        String recordId = (String) request.getOrDefault("recordId", generateRecordId());

        @SuppressWarnings("unchecked")
        Map<String, Object> changedFields = (Map<String, Object>) request.getOrDefault("changedFields",
                new HashMap<>());

        MockStreamingService streamingService = MockStreamingService.getInstance();
        if (streamingService == null) {
            resp.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            resp.getWriter().write("{\"error\": \"Streaming service not initialized\"}");
            return;
        }

        streamingService.publishEvent(channel, changeType, entityName, recordId, changedFields);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("channel", channel);
        response.put("changeType", changeType);
        response.put("entityName", entityName);
        response.put("recordId", recordId);

        resp.setContentType("application/json");
        resp.setStatus(HttpServletResponse.SC_OK);
        resp.getWriter().write(gson.toJson(response));

        log.info("Event triggered: {} {} on {}", changeType, entityName, channel);
    }

    private static String generateRecordId() {
        // Generate a Salesforce-style 18-character ID
        return "001" + UUID.randomUUID().toString().replace("-", "").substring(0, 15);
    }
}
