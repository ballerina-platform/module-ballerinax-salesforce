# Basic Single-Node CDC Listener

This example demonstrates a production-ready Salesforce Change Data Capture (CDC) listener that works correctly with Salesforce's **Refresh Token Rotation (RTR)** on a **single replica** (local dev, a single server, or a single Kubernetes pod).

## How it works

The listener is configured with `salesforce:RestBasedListenerConfig` using an OAuth2 `refresh_token` grant. No explicit `tokenStore` is provided — the connector automatically uses its built-in `InMemoryTokenStore`.

The in-memory store is sufficient here because:
- Ballerina's `lock` statement serialises all concurrent token-refresh attempts within the same process.
- Only one HTTP call is ever made to the Salesforce token endpoint per refresh cycle.
- The connector's internal `task:scheduleOneTimeJob` proactively reconnects CometD ~60 seconds before the access token expires, preventing reactive 401 cycles entirely.

For multi-replica (Kubernetes) deployments, see the [distributed_listener](../distributed_listener) example.

## Salesforce prerequisites

1. **Enable Change Data Capture** on at least one object:
   Setup → Integrations → Change Data Capture → check the objects you want to track.

2. **Enable Refresh Token Rotation** on your Connected App:
   Setup → App Manager → *Your App* → Edit Policies → check **Enable Refresh Token Rotation**.

3. Set the **Refresh Token Policy** to *"Refresh token is valid until revoked"* (or an idle/sliding window) so the connector can run indefinitely.

4. Note your org's **Session Timeout** value:
   Setup → Security → Session Settings → Timeout Value.
   You will need this for `sessionTimeoutSeconds` in `Config.toml`.

## Configuration

Create a `Config.toml` file in this directory with your credentials:

```toml
baseUrl              = "https://<YOUR_ORG>.my.salesforce.com"
clientId             = "<CONNECTED_APP_CONSUMER_KEY>"
clientSecret         = "<CONNECTED_APP_CONSUMER_SECRET>"
refreshToken         = "<YOUR_OAUTH2_REFRESH_TOKEN>"
tokenUrl             = "https://<YOUR_ORG>.my.salesforce.com/services/oauth2/token"
sessionTimeoutSeconds = 3600   # must match Setup → Security → Session Settings → Timeout Value
```

> **Security note:** Never commit `Config.toml` to version control. Add it to `.gitignore`.

## Run the example

```bash
bal run
```

The listener will start, subscribe to `/data/ChangeEvents`, and print log lines as CDC events arrive. You should see the proactive token refresh job fire approximately `sessionTimeoutSeconds - 60` seconds after startup.

## Expected log output

**At startup:**
```
time=2026-... level=INFO module=salesforce_examples/basic_single_node_listener
  message="Starting Salesforce CDC listener (single-node / in-memory RTR)"
  baseUrl="https://..." channel="/data/ChangeEvents" sessionTimeoutSeconds=3600
```

**On a CDC event (e.g., an Account update):**
```
time=2026-... level=INFO module=...
  message="CDC onUpdate received" entityName="Account" changedFields="[\"Name\",\"BillingCity\"]"
```

**When the proactive token refresh fires (~55 min after start for a 1-hour session):**
```
time=2026-... level=DEBUG message="Proactive token refresh: stopping CometD to reconnect with fresh token..."
time=2026-... level=DEBUG message="Proactive reconnect succeeded — CometD refreshed with new token"
time=2026-... level=DEBUG message="Proactive token refresh job scheduled (one-shot)" delaySeconds=3300 ...
```
