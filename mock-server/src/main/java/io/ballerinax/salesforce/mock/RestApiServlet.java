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
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.reflect.TypeToken;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.IOException;
import java.lang.reflect.Type;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Simulates the Salesforce REST API for CRUD operations on SObjects and
 * additional endpoints (query, search, limits, describe, reports, batch, etc.).
 * Automatically triggers CDC events on the mock streaming service after each CRUD operation.
 */
public class RestApiServlet extends HttpServlet {

    private static final Logger log = LoggerFactory.getLogger(RestApiServlet.class);
    private static final Gson gson = new Gson();
    private static final Map<String, Map<String, Object>> records = new ConcurrentHashMap<>();
    private static final List<Map<String, Object>> reportInstances = new ArrayList<>();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String pathInfo = req.getPathInfo();
        if (pathInfo == null) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        String[] parts = pathInfo.split("/");

        // POST /vXX.0/composite/batch
        if (parts.length >= 4 && "composite".equals(parts[2]) && "batch".equals(parts[3])) {
            handleCompositeBatch(req, resp);
            return;
        }

        // POST /vXX.0/analytics/reports/{id}/instances
        if (parts.length >= 5 && "analytics".equals(parts[2]) && "reports".equals(parts[3])
                && "instances".equals(parts[5 <= parts.length ? 5 : -1])) {
            handleRunReportAsync(parts[4], resp);
            return;
        }

        // POST /vXX.0/sobjects/User/{id}/password (changePassword)
        if (parts.length >= 6 && "sobjects".equals(parts[2]) && "User".equals(parts[3])
                && "password".equals(parts[5])) {
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
            return;
        }

        // Default: CRUD create on sobjects
        String sObjectType = extractSObjectType(pathInfo);
        if (sObjectType == null) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        Map<String, Object> requestBody = parseRequestBody(req);
        String recordId = generateRecordId();
        records.put(recordId, requestBody);

        // Trigger CDC event with non-null changed fields
        triggerCdcEvent("CREATE", sObjectType, recordId, filterNulls(requestBody));

        Map<String, Object> response = new HashMap<>();
        response.put("id", recordId);
        response.put("success", true);
        response.put("errors", new Object[]{});

        resp.setContentType("application/json");
        resp.setStatus(HttpServletResponse.SC_CREATED);
        resp.getWriter().write(gson.toJson(response));
        log.info("Created {} record: {}", sObjectType, recordId);
    }

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if ("PATCH".equalsIgnoreCase(req.getMethod())) {
            doPatch(req, resp);
        } else {
            super.service(req, resp);
        }
    }

    protected void doPatch(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String pathInfo = req.getPathInfo();
        if (pathInfo == null) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        String recordId = extractRecordId(pathInfo);
        String sObjectType = extractSObjectType(pathInfo);
        if (recordId == null || sObjectType == null) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        Map<String, Object> requestBody = parseRequestBody(req);

        Map<String, Object> existing = records.getOrDefault(recordId, new HashMap<>());
        existing.putAll(requestBody);
        records.put(recordId, existing);

        // Trigger CDC event with non-null changed fields
        triggerCdcEvent("UPDATE", sObjectType, recordId, filterNulls(requestBody));

        resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
        log.info("Updated {} record: {}", sObjectType, recordId);
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String pathInfo = req.getPathInfo();
        if (pathInfo == null) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        String[] parts = pathInfo.split("/");

        // DELETE /vXX.0/sobjects/User/{id}/password (resetPassword)
        if (parts.length >= 6 && "sobjects".equals(parts[2]) && "User".equals(parts[3])
                && "password".equals(parts[5])) {
            resp.setContentType("application/json");
            resp.setStatus(HttpServletResponse.SC_OK);
            resp.getWriter().write("{\"NewPassword\":\"mockPassword123\"}");
            return;
        }

        // DELETE /vXX.0/sobjects/{type}/{extIdField}/{extIdValue}
        // This also covers normal delete: /vXX.0/sobjects/{type}/{id}
        String recordId = extractRecordId(pathInfo);
        String sObjectType = extractSObjectType(pathInfo);
        if (recordId == null || sObjectType == null) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        records.remove(recordId);

        // Trigger CDC event
        triggerCdcEvent("DELETE", sObjectType, recordId, new HashMap<>());

        resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
        log.info("Deleted {} record: {}", sObjectType, recordId);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String pathInfo = req.getPathInfo();
        if (pathInfo == null || pathInfo.equals("/")) {
            // GET /services/data → API versions
            handleApiVersions(resp);
            return;
        }

        String[] parts = pathInfo.split("/");
        // parts[0] = "", parts[1] = "vXX.0", parts[2..] = rest

        if (parts.length < 2) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        // GET /services/data/vXX.0 → Resources
        if (parts.length == 2) {
            handleResources(parts[1], resp);
            return;
        }

        String segment = parts[2];

        switch (segment) {
            case "query":
                handleQuery(req, resp);
                return;
            case "search":
                handleSearch(req, resp);
                return;
            case "limits":
                handleLimits(resp);
                return;
            case "quickActions":
                handleQuickActions(resp);
                return;
            case "analytics":
                handleAnalytics(parts, resp);
                return;
            case "composite":
                // GET on composite shouldn't happen normally but handle gracefully
                resp.setStatus(HttpServletResponse.SC_OK);
                resp.setContentType("application/json");
                resp.getWriter().write("{}");
                return;
            case "sobjects":
                handleSObjects(parts, resp);
                return;
            default:
                break;
        }

        // Fallback: try record retrieval
        String recordId = extractRecordId(pathInfo);
        if (recordId != null && records.containsKey(recordId)) {
            Map<String, Object> record = new HashMap<>(records.get(recordId));
            record.put("Id", recordId);
            resp.setContentType("application/json");
            resp.setStatus(HttpServletResponse.SC_OK);
            resp.getWriter().write(gson.toJson(record));
        } else {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
            resp.getWriter().write("{\"errorCode\":\"NOT_FOUND\",\"message\":\"Record not found\"}");
        }
    }

    // ========================= API Versions =========================

    private void handleApiVersions(HttpServletResponse resp) throws IOException {
        JsonArray versions = new JsonArray();
        for (String v : new String[]{"v57.0", "v58.0", "v59.0"}) {
            JsonObject ver = new JsonObject();
            ver.addProperty("label", "Spring '24");
            ver.addProperty("url", "/services/data/" + v);
            ver.addProperty("version", v.substring(1));
            versions.add(ver);
        }
        writeJson(resp, HttpServletResponse.SC_OK, versions.toString());
    }

    // ========================= Resources =========================

    private void handleResources(String apiVersion, HttpServletResponse resp) throws IOException {
        JsonObject resources = new JsonObject();
        String base = "/services/data/" + apiVersion;
        resources.addProperty("sobjects", base + "/sobjects");
        resources.addProperty("search", base + "/search");
        resources.addProperty("query", base + "/query");
        resources.addProperty("licensing", base + "/licensing");
        resources.addProperty("connect", base + "/connect");
        resources.addProperty("tooling", base + "/tooling");
        resources.addProperty("chatter", base + "/chatter");
        resources.addProperty("recent", base + "/recent");
        resources.addProperty("limits", base + "/limits");
        resources.addProperty("composite", base + "/composite");
        resources.addProperty("analytics", base + "/analytics");
        writeJson(resp, HttpServletResponse.SC_OK, resources.toString());
    }

    // ========================= Query (SOQL) =========================

    private void handleQuery(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        JsonObject result = new JsonObject();
        JsonArray recordsArray = new JsonArray();

        // Return stored records that match if any exist; otherwise return a dummy record
        for (Map.Entry<String, Map<String, Object>> entry : records.entrySet()) {
            JsonObject rec = new JsonObject();
            rec.addProperty("Id", entry.getKey());
            for (Map.Entry<String, Object> field : entry.getValue().entrySet()) {
                if (field.getValue() != null) {
                    rec.addProperty(field.getKey(), field.getValue().toString());
                }
            }
            JsonObject attributes = new JsonObject();
            attributes.addProperty("type", "Account");
            attributes.addProperty("url", "/services/data/v59.0/sobjects/Account/" + entry.getKey());
            rec.add("attributes", attributes);
            recordsArray.add(rec);
        }

        if (recordsArray.size() == 0) {
            // Return at least one dummy record so tests pass
            JsonObject rec = new JsonObject();
            rec.addProperty("Id", "001MOCK000000001");
            rec.addProperty("Name", "Mock Account");
            JsonObject attributes = new JsonObject();
            attributes.addProperty("type", "Account");
            attributes.addProperty("url", "/services/data/v59.0/sobjects/Account/001MOCK000000001");
            rec.add("attributes", attributes);
            recordsArray.add(rec);
        }

        result.addProperty("totalSize", recordsArray.size());
        result.addProperty("done", true);
        result.add("records", recordsArray);
        writeJson(resp, HttpServletResponse.SC_OK, result.toString());
    }

    // ========================= Search (SOSL) =========================

    private void handleSearch(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        JsonObject result = new JsonObject();
        JsonArray searchRecords = new JsonArray();

        // Return stored records as search results
        for (Map.Entry<String, Map<String, Object>> entry : records.entrySet()) {
            JsonObject rec = new JsonObject();
            rec.addProperty("Id", entry.getKey());
            for (Map.Entry<String, Object> field : entry.getValue().entrySet()) {
                if (field.getValue() != null) {
                    rec.addProperty(field.getKey(), field.getValue().toString());
                }
            }
            JsonObject attributes = new JsonObject();
            attributes.addProperty("type", "Account");
            attributes.addProperty("url", "/services/data/v59.0/sobjects/Account/" + entry.getKey());
            rec.add("attributes", attributes);
            searchRecords.add(rec);
        }

        if (searchRecords.size() == 0) {
            JsonObject rec = new JsonObject();
            rec.addProperty("Id", "001MOCK000000001");
            rec.addProperty("Name", "Mock Search Result");
            JsonObject attributes = new JsonObject();
            attributes.addProperty("type", "Account");
            attributes.addProperty("url", "/services/data/v59.0/sobjects/Account/001MOCK000000001");
            rec.add("attributes", attributes);
            searchRecords.add(rec);
        }

        result.add("searchRecords", searchRecords);
        writeJson(resp, HttpServletResponse.SC_OK, result.toString());
    }

    // ========================= Limits =========================

    private void handleLimits(HttpServletResponse resp) throws IOException {
        JsonObject limits = new JsonObject();
        String[] limitNames = {"DailyApiRequests", "DailyBulkApiRequests", "DailyStreamingApiEvents",
                "SingleEmail", "MassEmail", "DailyAsyncApexExecutions"};
        for (String name : limitNames) {
            JsonObject limit = new JsonObject();
            limit.addProperty("Max", 15000);
            limit.addProperty("Remaining", 14998);
            limits.add(name, limit);
        }
        writeJson(resp, HttpServletResponse.SC_OK, limits.toString());
    }

    // ========================= Quick Actions =========================

    private void handleQuickActions(HttpServletResponse resp) throws IOException {
        JsonArray actions = new JsonArray();
        JsonObject action = new JsonObject();
        action.addProperty("actionEnumOrId", "001Mock");
        action.addProperty("label", "Mock Action");
        action.addProperty("name", "MockAction");
        action.addProperty("type", "Create");
        JsonObject urls = new JsonObject();
        urls.addProperty("quickAction", "/services/data/v59.0/quickActions/MockAction");
        urls.addProperty("describe", "/services/data/v59.0/quickActions/MockAction/describe");
        urls.addProperty("defaultValues", "/services/data/v59.0/quickActions/MockAction/defaultValues");
        urls.addProperty("defaultValuesTemplate", "/services/data/v59.0/quickActions/MockAction/defaultValues/template");
        action.add("urls", urls);
        actions.add(action);
        writeJson(resp, HttpServletResponse.SC_OK, actions.toString());
    }

    // ========================= Analytics (Reports) =========================

    private void handleAnalytics(String[] parts, HttpServletResponse resp) throws IOException {
        // parts: ["", "vXX.0", "analytics", "reports", ...]
        if (parts.length < 4 || !"reports".equals(parts[3])) {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        if (parts.length == 4) {
            // GET /vXX.0/analytics/reports → list reports
            handleListReports(resp);
        } else if (parts.length == 5) {
            // GET /vXX.0/analytics/reports/{id} → run report sync
            handleRunReportSync(parts[4], resp);
        } else if (parts.length == 6 && "instances".equals(parts[5])) {
            // GET /vXX.0/analytics/reports/{id}/instances → list async runs
            handleListAsyncRuns(parts[4], resp);
        } else if (parts.length == 7 && "instances".equals(parts[5])) {
            // GET /vXX.0/analytics/reports/{id}/instances/{instanceId} → get instance result
            handleGetReportInstanceResult(parts[4], parts[6], resp);
        } else {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    private void handleListReports(HttpServletResponse resp) throws IOException {
        JsonArray reports = new JsonArray();
        JsonObject report = new JsonObject();
        report.addProperty("id", "00O5g00000Jrs9DEAR");
        report.addProperty("name", "Mock Report");
        report.addProperty("url", "/services/data/v59.0/analytics/reports/00O5g00000Jrs9DEAR");
        report.addProperty("describeUrl", "/services/data/v59.0/analytics/reports/00O5g00000Jrs9DEAR/describe");
        report.addProperty("instancesUrl", "/services/data/v59.0/analytics/reports/00O5g00000Jrs9DEAR/instances");
        reports.add(report);
        writeJson(resp, HttpServletResponse.SC_OK, reports.toString());
    }

    private void handleRunReportSync(String reportId, HttpServletResponse resp) throws IOException {
        writeJson(resp, HttpServletResponse.SC_OK, buildReportInstanceResult(reportId, true));
    }

    private void handleRunReportAsync(String reportId, HttpServletResponse resp) throws IOException {
        String instanceId = "0LG" + UUID.randomUUID().toString().replace("-", "").substring(0, 15);
        String now = Instant.now().toString();

        Map<String, Object> instance = new HashMap<>();
        instance.put("id", instanceId);
        instance.put("status", "Success");
        instance.put("requestDate", now);
        instance.put("completionDate", now);
        instance.put("url", "/services/data/v59.0/analytics/reports/" + reportId + "/instances/" + instanceId);
        instance.put("ownerId", "005000000000001");
        instance.put("queryable", true);
        instance.put("hasDetailRows", true);
        synchronized (reportInstances) {
            reportInstances.add(instance);
        }

        writeJson(resp, HttpServletResponse.SC_OK, gson.toJson(instance));
        log.info("Created async report instance: {}", instanceId);
    }

    private void handleListAsyncRuns(String reportId, HttpServletResponse resp) throws IOException {
        JsonArray instances = new JsonArray();
        synchronized (reportInstances) {
            for (Map<String, Object> inst : reportInstances) {
                instances.add(gson.toJsonTree(inst));
            }
        }
        if (instances.size() == 0) {
            // Add a default instance
            JsonObject inst = new JsonObject();
            inst.addProperty("id", "0LGMock000000001");
            inst.addProperty("status", "Success");
            inst.addProperty("requestDate", Instant.now().toString());
            inst.addProperty("completionDate", Instant.now().toString());
            inst.addProperty("url", "/services/data/v59.0/analytics/reports/" + reportId + "/instances/0LGMock000000001");
            inst.addProperty("ownerId", "005000000000001");
            inst.addProperty("queryable", true);
            inst.addProperty("hasDetailRows", true);
            instances.add(inst);
        }
        writeJson(resp, HttpServletResponse.SC_OK, instances.toString());
    }

    private void handleGetReportInstanceResult(String reportId, String instanceId, HttpServletResponse resp)
            throws IOException {
        writeJson(resp, HttpServletResponse.SC_OK, buildReportInstanceResult(reportId, false));
    }

    private String buildReportInstanceResult(String reportId, boolean isSync) {
        JsonObject result = new JsonObject();

        JsonObject attributes = new JsonObject();
        if (isSync) {
            attributes.addProperty("reportId", reportId);
            attributes.addProperty("reportName", "Mock Report");
            attributes.addProperty("type", "Report");
            attributes.addProperty("describeUrl", "/services/data/v59.0/analytics/reports/" + reportId + "/describe");
            attributes.addProperty("instancesUrl", "/services/data/v59.0/analytics/reports/" + reportId + "/instances");
        } else {
            attributes.addProperty("id", "0LGMock000000001");
            attributes.addProperty("reportId", reportId);
            attributes.addProperty("reportName", "Mock Report");
            attributes.addProperty("status", "Success");
            attributes.addProperty("ownerId", "005000000000001");
            attributes.addProperty("requestDate", Instant.now().toString());
            attributes.addProperty("completionDate", Instant.now().toString());
            attributes.addProperty("type", "Report");
            attributes.addProperty("errorMessage", (String) null);
            attributes.addProperty("queryable", true);
        }
        result.add("attributes", attributes);
        result.addProperty("allData", true);
        result.add("factMap", new JsonObject());
        result.add("groupingsAcross", new JsonObject());
        result.add("groupingsDown", new JsonObject());
        result.add("reportMetadata", new JsonObject());
        result.addProperty("hasDetailRows", true);
        result.add("reportExtendedMetadata", new JsonObject());

        return result.toString();
    }

    // ========================= SObjects =========================

    private void handleSObjects(String[] parts, HttpServletResponse resp) throws IOException {
        // parts: ["", "vXX.0", "sobjects", ...]

        if (parts.length == 3) {
            // GET /vXX.0/sobjects → Organization metadata
            handleOrganizationMetadata(resp);
            return;
        }

        String sObjectType = parts[3];

        if (parts.length == 4) {
            // GET /vXX.0/sobjects/{type} → Basic info or record retrieval
            // Check if it looks like a record ID (starts with 001 or similar)
            handleBasicInfo(sObjectType, resp);
            return;
        }

        if (parts.length == 5) {
            String fifth = parts[4];
            if ("describe".equals(fifth)) {
                handleDescribe(sObjectType, resp);
                return;
            }
            if ("deleted".equals(fifth)) {
                handleDeleted(sObjectType, resp);
                return;
            }
            if ("updated".equals(fifth)) {
                handleUpdated(sObjectType, resp);
                return;
            }
            // GET /vXX.0/sobjects/{type}/{id} → record retrieval
            if (records.containsKey(fifth)) {
                Map<String, Object> record = new HashMap<>(records.get(fifth));
                record.put("Id", fifth);
                writeJson(resp, HttpServletResponse.SC_OK, gson.toJson(record));
            } else {
                resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                resp.setContentType("application/json");
                resp.getWriter().write("{\"errorCode\":\"NOT_FOUND\",\"message\":\"Record not found\"}");
            }
            return;
        }

        if (parts.length == 6) {
            // GET /vXX.0/sobjects/User/{id}/password
            if ("User".equals(sObjectType) && "password".equals(parts[5])) {
                handlePasswordInfo(resp);
                return;
            }
            // GET /vXX.0/sobjects/{type}/describe/namedLayouts (shouldn't happen, needs 7 parts)
            // GET /vXX.0/sobjects/{type}/{extIdField}/{extIdValue} → record by ext ID
            // Just return 204 for delete or a simple record for GET
            writeJson(resp, HttpServletResponse.SC_OK, "{}");
            return;
        }

        if (parts.length >= 7 && "describe".equals(parts[4]) && "namedLayouts".equals(parts[5])) {
            handleNamedLayouts(sObjectType, parts[6], resp);
            return;
        }

        resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
    }

    private void handleOrganizationMetadata(HttpServletResponse resp) throws IOException {
        JsonObject metadata = new JsonObject();
        metadata.addProperty("encoding", "UTF-8");
        metadata.addProperty("maxBatchSize", 200);

        JsonArray sobjects = new JsonArray();
        for (String name : new String[]{"Account", "Contact", "Lead", "Opportunity"}) {
            JsonObject sobj = new JsonObject();
            sobj.addProperty("name", name);
            sobj.addProperty("createable", true);
            sobj.addProperty("deletable", true);
            sobj.addProperty("updateable", true);
            sobj.addProperty("queryable", true);
            sobj.addProperty("label", name);
            JsonObject urls = new JsonObject();
            urls.addProperty("sobject", "/services/data/v59.0/sobjects/" + name);
            urls.addProperty("describe", "/services/data/v59.0/sobjects/" + name + "/describe");
            urls.addProperty("rowTemplate", "/services/data/v59.0/sobjects/" + name + "/{ID}");
            sobj.add("urls", urls);
            sobjects.add(sobj);
        }
        metadata.add("sobjects", sobjects);
        writeJson(resp, HttpServletResponse.SC_OK, metadata.toString());
    }

    private void handleBasicInfo(String sObjectType, HttpServletResponse resp) throws IOException {
        JsonObject result = new JsonObject();
        JsonObject objectDescribe = new JsonObject();
        objectDescribe.addProperty("name", sObjectType);
        objectDescribe.addProperty("createable", true);
        objectDescribe.addProperty("deletable", true);
        objectDescribe.addProperty("updateable", true);
        objectDescribe.addProperty("queryable", true);
        objectDescribe.addProperty("label", sObjectType);
        JsonObject urls = new JsonObject();
        urls.addProperty("sobject", "/services/data/v59.0/sobjects/" + sObjectType);
        urls.addProperty("describe", "/services/data/v59.0/sobjects/" + sObjectType + "/describe");
        urls.addProperty("rowTemplate", "/services/data/v59.0/sobjects/" + sObjectType + "/{ID}");
        objectDescribe.add("urls", urls);
        result.add("objectDescribe", objectDescribe);
        writeJson(resp, HttpServletResponse.SC_OK, result.toString());
    }

    private void handleDescribe(String sObjectType, HttpServletResponse resp) throws IOException {
        JsonObject describe = new JsonObject();
        describe.addProperty("name", sObjectType);
        describe.addProperty("createable", true);
        describe.addProperty("deletable", true);
        describe.addProperty("updateable", true);
        describe.addProperty("queryable", true);
        describe.addProperty("label", sObjectType);
        JsonObject urls = new JsonObject();
        urls.addProperty("sobject", "/services/data/v59.0/sobjects/" + sObjectType);
        urls.addProperty("describe", "/services/data/v59.0/sobjects/" + sObjectType + "/describe");
        urls.addProperty("rowTemplate", "/services/data/v59.0/sobjects/" + sObjectType + "/{ID}");
        describe.add("urls", urls);
        writeJson(resp, HttpServletResponse.SC_OK, describe.toString());
    }

    private void handleDeleted(String sObjectType, HttpServletResponse resp) throws IOException {
        JsonObject result = new JsonObject();
        result.add("deletedRecords", new JsonArray());
        result.addProperty("earliestDateAvailable", Instant.now().toString());
        result.addProperty("latestDateCovered", Instant.now().toString());
        writeJson(resp, HttpServletResponse.SC_OK, result.toString());
    }

    private void handleUpdated(String sObjectType, HttpServletResponse resp) throws IOException {
        JsonObject result = new JsonObject();
        result.add("ids", new JsonArray());
        result.addProperty("latestDateCovered", Instant.now().toString());
        writeJson(resp, HttpServletResponse.SC_OK, result.toString());
    }

    private void handlePasswordInfo(HttpServletResponse resp) throws IOException {
        writeJson(resp, HttpServletResponse.SC_OK, "{\"isExpired\":false}");
    }

    private void handleNamedLayouts(String sObjectType, String layoutName, HttpServletResponse resp)
            throws IOException {
        JsonObject result = new JsonObject();
        JsonArray layouts = new JsonArray();
        JsonObject layout = new JsonObject();
        layout.addProperty("name", layoutName);
        layouts.add(layout);
        result.add("layouts", layouts);
        result.add("recordTypeMappings", new JsonArray());
        JsonArray selectorRequired = new JsonArray();
        selectorRequired.add(false);
        result.add("recordTypeSelectorRequired", selectorRequired);
        writeJson(resp, HttpServletResponse.SC_OK, result.toString());
    }

    // ========================= Composite Batch =========================

    private void handleCompositeBatch(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Map<String, Object> requestBody = parseRequestBody(req);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> batchRequests = (List<Map<String, Object>>) requestBody.get("batchRequests");

        JsonArray results = new JsonArray();
        if (batchRequests != null) {
            for (Map<String, Object> subrequest : batchRequests) {
                JsonObject subResult = new JsonObject();
                subResult.addProperty("statusCode", 200);
                // Return a simple describe-like result for each subrequest
                JsonObject resultBody = new JsonObject();
                resultBody.addProperty("name", "MockSObject");
                resultBody.addProperty("createable", true);
                subResult.add("result", resultBody);
                results.add(subResult);
            }
        }

        JsonObject batchResult = new JsonObject();
        batchResult.addProperty("hasErrors", false);
        batchResult.add("results", results);
        writeJson(resp, HttpServletResponse.SC_OK, batchResult.toString());
    }

    // ========================= CDC Event Trigger =========================

    private void triggerCdcEvent(String changeType, String entityName, String recordId,
                                  Map<String, Object> changedFields) {
        new Thread(() -> {
            try {
                Thread.sleep(2000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            MockStreamingService streamingService = MockStreamingService.getInstance();
            if (streamingService != null) {
                streamingService.publishEvent("/data/ChangeEvents", changeType, entityName, recordId, changedFields);
                log.info("Triggered {} CDC event for {} record: {}", changeType, entityName, recordId);
            }
        }).start();
    }

    // ========================= Utility Methods =========================

    private void writeJson(HttpServletResponse resp, int status, String json) throws IOException {
        resp.setContentType("application/json");
        resp.setStatus(status);
        resp.getWriter().write(json);
    }

    private Map<String, Object> parseRequestBody(HttpServletRequest req) throws IOException {
        StringBuilder body = new StringBuilder();
        try (BufferedReader reader = req.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) {
                body.append(line);
            }
        }
        Type type = new TypeToken<Map<String, Object>>() {}.getType();
        Map<String, Object> result = gson.fromJson(body.toString(), type);
        return result != null ? result : new HashMap<>();
    }

    private String extractSObjectType(String pathInfo) {
        String[] parts = pathInfo.split("/");
        if (parts.length >= 4 && "sobjects".equals(parts[2])) {
            return parts[3];
        }
        return null;
    }

    private String extractRecordId(String pathInfo) {
        String[] parts = pathInfo.split("/");
        if (parts.length >= 5 && "sobjects".equals(parts[2])) {
            return parts[4];
        }
        return null;
    }

    private static Map<String, Object> filterNulls(Map<String, Object> map) {
        Map<String, Object> filtered = new HashMap<>();
        for (Map.Entry<String, Object> entry : map.entrySet()) {
            if (entry.getValue() != null) {
                filtered.put(entry.getKey(), entry.getValue());
            }
        }
        return filtered;
    }

    private static String generateRecordId() {
        return "001" + UUID.randomUUID().toString().replace("-", "").substring(0, 15);
    }
}
