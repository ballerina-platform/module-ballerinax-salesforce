# Ballerina Salesforce Connector — Examples

This directory contains practical Ballerina examples for the `ballerinax/salesforce` connector, grouped by API surface and use case.

## Directory structure

```
examples/
├── rest_api_usecases/          CRUD operations via Salesforce REST API
├── bulk_api_usecases/          Bulk v1 ingest and query jobs
├── bulkv2_api_usecases/        Bulk v2 ingest jobs
├── soap_api_usecases/          SOAP API operations (lead conversion, etc.)
├── apex_rest_api_usecases/     Calling custom Apex REST endpoints
└── listener_usecases/          CDC Listener with Refresh Token Rotation (RTR)
    ├── basic_single_node_listener/   Default in-memory RTR (single replica)
    └── distributed_listener/         Custom TokenStore for multi-replica K8s
```

---

## Running any example

### Prerequisites

1. Follow the [Setup guide](../README.md#setup-guide) in the root README to obtain your Salesforce OAuth2 credentials.
2. Build and push the connector to your local Ballerina repository:

   ```bash
   cd ../ballerina
   bal pack && bal push --repository=local
   ```

3. `cd` into the example directory, create a `Config.toml` with your credentials (each example's README lists the required keys), then run:

   ```bash
   bal run
   ```

---

## Listener use cases: Refresh Token Rotation (RTR)

The CDC Listener examples deserve extra attention because they address a common production pitfall — **token replay attacks** — that silently kills Salesforce integrations running in Kubernetes.

### What is a Token Replay Attack?

When Salesforce enables **Refresh Token Rotation**, every token exchange invalidates the previous refresh token and issues a new one. In a multi-replica deployment, if two pods simultaneously try to use the *same* refresh token (e.g., on startup or after a 401), the second request arrives after the token has been rotated. Salesforce returns `400 invalid_grant` and permanently revokes the **entire token family** — both pods crash-loop until a human re-authenticates.

### How the connector prevents this

The listener uses a **distributed double-checked locking** protocol through the pluggable `salesforce:TokenStore` interface:

```
Pod A                   TokenStore (Redis/DB)         Salesforce
 │── acquireLock() ──────────→ SETNX lock:key ──┐
 │   lock acquired ◄──────────────────────────── │
 │── getTokenData() ──────────→ (empty)           │    ← double-check
 │── POST /oauth2/token ───────────────────────────────────────→
 │   AT#1 + RT#1 ◄──────────────────────────────────────────── │
 │── setTokenData(AT#1/RT#1) ─→ data:key                        │
 │── releaseLock() ───────────→ DEL lock:key
 │
 │                    Pod B (concurrent)
 │                     │── acquireLock() → lock held (returns false)
 │                     │   [waits with exponential backoff]
 │                     │── getTokenData() → AT#1/RT#1   ← adopts from store
 │                     │   [no HTTP call made]
```

### Deployment models

| Deployment | `tokenStore` config | What happens |
|---|---|---|
| **Single replica / local dev** | Omit `tokenStore` (or leave `()`) | `InMemoryTokenStore` is used automatically. Ballerina's `lock` statement serialises concurrent goroutines within the same process. |
| **Multi-replica (Kubernetes)** | Pass a `salesforce:TokenStore` implementation backed by Redis, PostgreSQL, etc. | The advisory lock ensures only one pod calls Salesforce. All others adopt the result from the shared store. |

### Implementing a custom TokenStore

Implement the `salesforce:TokenStore` object type in your project:

```ballerina
import ballerinax/salesforce;

public isolated class MyRedisTokenStore {
    *salesforce:TokenStore;

    // Acquire an advisory lock. Return true if this replica owns it.
    // Use Redis SETNX + EXPIRE, or a SELECT ... FOR UPDATE on a DB row.
    public isolated function acquireLock(string lockKey, int ttlSeconds) returns boolean|error {
        // TODO: replace with your Redis / DB call
        return true;
    }

    // Release the lock when the refresh cycle is complete.
    public isolated function releaseLock(string lockKey) returns error? {
        // TODO: DEL lock:key in Redis, or DELETE FROM locks WHERE key = lockKey
    }

    // Read the current token data from the shared store.
    // Return () if the key does not exist yet (first startup).
    public isolated function getTokenData(string key) returns salesforce:TokenData?|error {
        // TODO: GET data:key from Redis, deserialise JSON → salesforce:TokenData
        return ();
    }

    // Persist updated token data after a successful refresh.
    public isolated function setTokenData(string key, salesforce:TokenData data) returns error? {
        // TODO: SET data:key (JSON-serialised data) in Redis
    }

    // Evict all state for this token family (called on invalid_grant to prevent
    // cache poisoning — without this, replicas would crash-loop on restart).
    public isolated function clearTokenData(string key) returns error? {
        // TODO: DEL data:key and lock:key
    }
}
```

Wire it into the listener:

```ballerina
import ballerina/http;
import ballerinax/salesforce;

final salesforce:TokenStore tokenStore = check new MyRedisTokenStore();

salesforce:RestBasedListenerConfig listenerConfig = {
    baseUrl: "<YOUR_SF_INSTANCE>.my.salesforce.com",
    auth: <http:OAuth2RefreshTokenGrantConfig>{
        clientId:      "<CLIENT_ID>",
        clientSecret:  "<CLIENT_SECRET>",
        refreshToken:  "<REFRESH_TOKEN>",
        refreshUrl:    "https://<YOUR_SF_INSTANCE>.my.salesforce.com/services/oauth2/token",
        defaultTokenExpTime: 3600  // must match Setup → Security → Session Settings → Timeout Value
    },
    tokenStore: tokenStore
};

listener salesforce:Listener eventListener = new (listenerConfig);
```

### TokenData record

When your store serialises/deserialises token data, map to this exact record:

```ballerina
public type TokenData record {|
    string accessToken;            // current access token
    string refreshToken;           // current refresh token (may have been rotated)
    int    accessTokenExpiryEpoch; // Unix epoch (seconds) when the AT expires
    int    issuedAtEpoch;          // Unix epoch (seconds) from Salesforce `issued_at`
    int    lastRefreshedAtEpoch;   // Unix epoch (seconds) when this data was written
|};
```

### Important: `defaultTokenExpTime`

Salesforce does **not** include `expires_in` in its OAuth token response. The connector derives the access-token expiry as:

```
expiryEpoch = issued_at + defaultTokenExpTime - 30 (clock-skew buffer)
```

Set `defaultTokenExpTime` to your org's **Session Timeout** value (found at Setup → Security → Session Settings → Timeout Value). A mismatch causes either premature refreshes (value too low) or missed 401s (value too high).

---

## Examples index

| Example | Description |
|---|---|
| [basic_single_node_listener](listener_usecases/basic_single_node_listener) | CDC listener with default in-memory RTR. Zero additional dependencies. |
| [distributed_listener](listener_usecases/distributed_listener) | CDC listener with a custom `TokenStore` demonstrating the full distributed coordination pattern. |
| [create_sobjects](rest_api_usecases/create_sobjects) | Create Salesforce SObjects via the REST API. |
| [get_by_id](rest_api_usecases/get_by_id) | Retrieve an SObject by ID. |
| [update_sobject](rest_api_usecases/update_sobject) | Update an existing SObject. |
| [delete_sobject](rest_api_usecases/delete_sobject) | Delete a Salesforce SObject. |
| [use_query_api](rest_api_usecases/use_query_api) | Execute SOQL queries and stream results. |
| [use_search_api](rest_api_usecases/use_search_api) | Execute SOSL search queries. |
| [execute_insert_job](bulk_api_usecases/execute_insert_job) | Bulk v1 CSV insert job. |
| [execute_update_job](bulk_api_usecases/execute_update_job) | Bulk v1 CSV update job. |
| [execute_upsert_job](bulk_api_usecases/execute_upsert_job) | Bulk v1 CSV upsert job. |
| [execute_delete_job](bulk_api_usecases/execute_delete_job) | Bulk v1 CSV delete job. |
| [execute_query_job](bulk_api_usecases/execute_query_job) | Bulk v1 CSV query job. |
| [execute_bulkv2_ingest_job](bulkv2_api_usecases/execute_bulkv2_ingest_job) | Bulk v2 ingest job. |
| [convert_lead](soap_api_usecases/convert_lead) | Convert a lead via the SOAP API. |
| [create_case](apex_rest_api_usecases/create_case) | Invoke a custom Apex REST endpoint. |
