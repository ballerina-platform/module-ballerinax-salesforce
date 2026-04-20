// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

// =============================================================================
// Basic Single-Node Listener with Refresh Token Rotation (RTR)
// =============================================================================
//
// Demonstrates the simplest possible CDC listener setup:
//
//   - Uses `salesforce:RestBasedListenerConfig` with OAuth2 refresh-token grant.
//   - No `tokenStore` is specified — the connector defaults to the built-in
//     `InMemoryTokenStore`, which is suitable for single-replica deployments.
//   - Refresh Token Rotation is handled transparently: when Salesforce rotates
//     the refresh token on each exchange, the connector captures the new RT
//     in memory and uses it for subsequent refreshes.
//   - A background `task:scheduleOneTimeJob` proactively reconnects CometD
//     ~60 seconds before the access token expires, preventing 401 cycles.
//
// Subscribed channel: /data/ChangeEvents (all Change Data Capture events)
//
// Prerequisites:
//   1. Enable Change Data Capture on at least one object in Salesforce:
//      Setup → Integrations → Change Data Capture → select an object.
//   2. Enable Refresh Token Rotation on your Connected App:
//      Setup → App Manager → <Your App> → Edit Policies →
//      Enable Refresh Token Rotation.
//   3. Populate Config.toml (see README.md).
// =============================================================================

import ballerina/http;
import ballerina/log;
import ballerinax/salesforce;

// ---------------------------------------------------------------------------
// Credentials — supplied via Config.toml (never hardcode in source)
// ---------------------------------------------------------------------------
configurable string baseUrl = ?;
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;
configurable string tokenUrl = ?;

// defaultTokenExpTime must match your Salesforce org's Session Timeout setting.
// Navigate to: Setup → Security → Session Settings → Timeout Value.
// Salesforce does NOT return `expires_in` in its token response — this value is
// used by the connector to calculate when to proactively refresh.
// Common values: 900 (15 min), 1800 (30 min), 3600 (1 hr), 7200 (2 hr).
configurable int sessionTimeoutSeconds = 3600;

// ---------------------------------------------------------------------------
// Listener configuration
// ---------------------------------------------------------------------------
// No `tokenStore` is set here. The connector automatically falls back to the
// built-in InMemoryTokenStore, which is correct for a single-replica deployment.
// For multi-replica / Kubernetes deployments, see the `distributed_listener`
// example, which shows how to plug in a shared TokenStore.
salesforce:RestBasedListenerConfig listenerConfig = {
    baseUrl: baseUrl,
    auth: <http:OAuth2RefreshTokenGrantConfig>{
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        refreshUrl: tokenUrl,
        defaultTokenExpTime: <decimal>sessionTimeoutSeconds
    }
    // tokenStore: ()  // default: InMemoryTokenStore (uncomment to be explicit)
};

listener salesforce:Listener eventListener = new (listenerConfig);

// ---------------------------------------------------------------------------
// CDC service — subscribe to all Change Data Capture events
// ---------------------------------------------------------------------------
// Change the service path to target a specific object channel, e.g.:
//   "/data/AccountChangeEvent"  — only Account changes
//   "/data/LeadChangeEvent"     — only Lead changes
//   "/data/ChangeEvents"        — all CDC events (used here)
service "/data/ChangeEvents" on eventListener {

    // Fires when a new record is created.
    remote function onCreate(salesforce:EventData payload) {
        log:printInfo("CDC onCreate received",
                entityName = payload.metadata?.entityName ?: "unknown",
                changeType = payload.metadata?.changeType ?: "unknown");
        log:printDebug("Created record payload", payload = payload.toString());
    }

    // Fires when an existing record is updated.
    remote isolated function onUpdate(salesforce:EventData payload) {
        log:printInfo("CDC onUpdate received",
                entityName = payload.metadata?.entityName ?: "unknown",
                changedFields = payload.changedData.keys().toString());
        log:printDebug("Updated record payload", payload = payload.toString());
    }

    // Fires when a record is deleted (soft-deleted to the Recycle Bin).
    remote function onDelete(salesforce:EventData payload) {
        log:printInfo("CDC onDelete received",
                entityName = payload.metadata?.entityName ?: "unknown");
    }

    // Fires when a record is restored from the Recycle Bin.
    remote function onRestore(salesforce:EventData payload) {
        log:printInfo("CDC onRestore received",
                entityName = payload.metadata?.entityName ?: "unknown");
    }
}

// ---------------------------------------------------------------------------
// Module-level init — runs once at startup before the listener starts
// ---------------------------------------------------------------------------
function init() returns error? {
    log:printInfo("Starting Salesforce CDC listener (single-node / in-memory RTR)",
            baseUrl = baseUrl,
            channel = "/data/ChangeEvents",
            sessionTimeoutSeconds = sessionTimeoutSeconds);
}
