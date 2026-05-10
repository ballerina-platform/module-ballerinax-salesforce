# Distributed CDC Listener with Custom TokenStore

This example demonstrates a production-ready Salesforce Change Data Capture (CDC) listener that coordinates token refresh across **multiple replicas** (e.g., several Kubernetes pods sharing a single Salesforce Connected App). It is the recommended setup for any horizontally-scaled deployment where Refresh Token Rotation is enabled on the Salesforce Connected App.

## The Problem: Token Replay Attacks

When Salesforce enables **Refresh Token Rotation**, every OAuth2 token exchange:
- Issues a **new** refresh token (RT#N+1)
- **Immediately revokes** the old one (RT#N)

In a multi-pod deployment without coordination, two pods starting up simultaneously — or both responding to a 401 — will each send the **same** stale refresh token to Salesforce. The first pod gets `AT#1 + RT#1`. The second pod gets `400 invalid_grant` because `RT_seed` was already rotated. Salesforce then **revokes the entire token family**, crashing all pods into a crash-loop that requires manual re-authentication to recover from.

## The Solution: Distributed Double-Checked Locking

All pods share one `salesforce:TokenStore` instance backed by a distributed store (Redis, PostgreSQL, etc.). The connector's `TokenManager` enforces:

```
Pod A (wins lock)               Shared Store               Salesforce
│── acquireLock() ──────────────→ SETNX lock:key ─────────┐
│   acquired=true ◄────────────────────────────────────────┘
│── getTokenData() ─────────────→ () (empty)                ← double-check
│── POST /oauth2/token ───────────────────────────────────────────────→
│   AT#1 + RT#1 ◄─────────────────────────────────────────────────────
│── setTokenData(AT#1, RT#1) ───→ data:key=AT#1/RT#1
│── releaseLock() ──────────────→ DEL lock:key

Pod B (loses lock)              Shared Store
│── acquireLock() ──────────────→ lock held → acquired=false
│   [exponential backoff poll]
│── getTokenData() ─────────────→ AT#1/RT#1  (written by Pod A)
│   AT#1 adopted ◄───────────────────────────                ← no HTTP call!
```

Only **one** HTTP call is made to Salesforce. All other pods adopt the result from the shared store.

## What this example contains

`distributed_listener.bal` provides a **fully compilable** `SharedTokenStore` class that uses Ballerina's built-in isolated maps as its backing store. This lets the example compile and run without any external infrastructure, while clearly documenting the Redis or JDBC equivalent of every operation in inline comments.

To adapt it for production, replace the `lock { ... }` body of each method with the corresponding Redis or database call. The method contract (signatures, semantics, error types) stays identical.

## Salesforce prerequisites

Same as the [basic_single_node_listener](../basic_single_node_listener/README.md#salesforce-prerequisites), plus:

- Ensure your **Refresh Token Policy** is set to *"Refresh token is valid until revoked"* or a sliding-window policy. An absolute-expiry policy will eventually kill the token family regardless of coordination.

## Configuration

Create a `Config.toml` file in this directory:

```toml
baseUrl               = "https://<YOUR_ORG>.my.salesforce.com"
clientId              = "<CONNECTED_APP_CONSUMER_KEY>"
clientSecret          = "<CONNECTED_APP_CONSUMER_SECRET>"
refreshToken          = "<YOUR_OAUTH2_REFRESH_TOKEN>"
tokenUrl              = "https://<YOUR_ORG>.my.salesforce.com/services/oauth2/token"
sessionTimeoutSeconds = 3600   # must match Setup → Security → Session Settings → Timeout Value
```

## Run the example (standalone / demo mode)

```bash
bal run
```

This uses the in-process `SharedTokenStore` stub. You will see the same RTR log output as the basic example; the difference is that you can see exactly which methods get called on the store by adding `log:printDebug` calls inside the store's methods.

## Adapting for Redis (production Kubernetes)

### 1. Add the Redis dependency to `Ballerina.toml`

```toml
[[dependency]]
org     = "ballerinax"
name    = "redis"
version = "3.2.1"   # use the latest stable release
```

### 2. Create a `RedisTokenStore` class

```ballerina
import ballerina/log;
import ballerinax/redis;
import ballerinax/salesforce;

public isolated class RedisTokenStore {
    *salesforce:TokenStore;

    private final redis:Client redisClient;

    public isolated function init(string host = "localhost", int port = 6379) returns error? {
        self.redisClient = check new ({
            connection: {host: host, port: port}
        });
    }

    public isolated function acquireLock(string lockKey, int ttlSeconds) returns boolean|error {
        boolean acquired = check self.redisClient->setNx("lock:" + lockKey, "1");
        if acquired {
            _ = check self.redisClient->expire("lock:" + lockKey, ttlSeconds);
        }
        return acquired;
    }

    public isolated function releaseLock(string lockKey) returns error? {
        _ = check self.redisClient->del(["lock:" + lockKey]);
    }

    public isolated function getTokenData(string key) returns salesforce:TokenData?|error {
        string|redis:Error? raw = self.redisClient->get("data:" + key);
        if raw is string {
            json jsonData = check raw.fromJsonString();
            return check jsonData.cloneWithType(salesforce:TokenData);
        }
        return ();
    }

    public isolated function setTokenData(string key, salesforce:TokenData data) returns error? {
        _ = check self.redisClient->set("data:" + key, data.toJsonString());
    }

    public isolated function clearTokenData(string key) returns error? {
        _ = check self.redisClient->del(["data:" + key, "lock:" + key]);
        log:printInfo("Token data evicted from Redis (cache poisoning prevention)",
                storeKey = key);
    }
}
```

### 3. Replace the store instance

In `distributed_listener.bal`, change:

```ballerina
final salesforce:TokenStore sharedStore = new SharedTokenStore();
```

to:

```ballerina
configurable string redisHost = "redis-service";  // K8s Service name
configurable int    redisPort = 6379;

final salesforce:TokenStore sharedStore = check new RedisTokenStore(redisHost, redisPort);
```

### 4. Start Redis

```bash
# Local development (Refer to module-ballerinax-salesforce/ballerina/tests/resources/docker-compose.yml and execute below)
docker compose up -d

# OR directly execute docker command
docker run -d --name redis -p 6379:6379 redis:7-alpine

# Kubernetes — example Deployment + Service (adapt as needed)
# kubectl apply -f k8s/redis.yaml
```

All pods must point to the **same** Redis instance. This is what makes the advisory lock effective across replicas.

## Key `defaultTokenExpTime` note

Salesforce does **not** include `expires_in` in its OAuth token response. The connector derives the access-token expiry as:

```
expiryEpoch = issued_at + defaultTokenExpTime - 30 (clock-skew buffer)
```

Always set `defaultTokenExpTime` to your org's **Session Timeout** value:
Setup → Security → Session Settings → Timeout Value.

## Further reading

- [examples/README.md](../../README.md) — full guide to the TokenStore interface and deployment models
- [ballerina/modules/utils/tests/redis_token_store.bal](../../../../ballerina/modules/utils/tests/redis_token_store.bal) — battle-tested Redis implementation used in the connector's own integration test suite
