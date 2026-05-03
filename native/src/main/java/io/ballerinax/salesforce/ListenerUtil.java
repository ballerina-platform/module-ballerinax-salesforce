/*
 * Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
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
 *
 */

package io.ballerinax.salesforce;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.TypeTags;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BDecimal;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import org.eclipse.jetty.client.HttpProxy;
import org.eclipse.jetty.client.Origin;
import org.eclipse.jetty.client.ProxyConfiguration;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.function.Consumer;
import java.util.stream.Collectors;

import static io.ballerinax.salesforce.Constants.CONSUMER_SERVICES;
import static io.ballerinax.salesforce.Constants.DISPATCHERS;
import static io.ballerinax.salesforce.Constants.IS_SAND_BOX;
import static io.ballerinax.salesforce.Constants.REPLAY_FROM;

/**
 * Util class containing the java external functions for Ballerina Salesforce listener.
 */
public class ListenerUtil {
    public static final String IS_OAUTH2 = "isOAuth2";
    public static final String BASE_URL = "baseUrl";
    public static final String CONNECTION_TIMEOUT = "connectionTimeout";
    public static final String READ_TIMEOUT = "readTimeout";
    public static final String KEEP_ALIVE_INTERVAL = "keepAliveInterval";
    public static final String API_VERSION = "apiVersion";
    public static final String GET_OAUTH2_TOKEN_METHOD = "getOAuth2Token";
    public static final String SUBSCRIPTIONS = "subscriptions";
    public static final String PROXY_CONFIG = "proxyConfig";

    /**
     * Native data key for the per-start-cycle replayFrom override set by
     * {@code CometdStateManager.standbyTick()} when resuming from a persisted
     * checkpoint.  Takes precedence over {@link Constants#REPLAY_FROM} for
     * exactly one {@code startListenerWithOAuth2} call, then is cleared so
     * subsequent starts fall back to the init-time value.
     */
    public static final String EFFECTIVE_REPLAY_FROM = "effective_replay_from";

    private static final String CONNECTOR = "connector";
    private static final List<String> CDC_METHODS = List.of(
            Constants.ON_CREATE, Constants.ON_UPDATE, Constants.ON_DELETE, Constants.ON_RESTORE);

    private static void extractBaseConfigs(BObject listener, int replayFrom,
            BDecimal connectionTimeout, BDecimal readTimeout, BDecimal keepAliveInterval,
            BString apiVersion, Object proxyConfig) {
        listener.addNativeData(CONSUMER_SERVICES, new ArrayList<BObject>());
        listener.addNativeData(DISPATCHERS, new HashMap<BObject, DispatcherService>());
        listener.addNativeData(SUBSCRIPTIONS, new HashMap<BObject, TopicSubscription>());
        listener.addNativeData(REPLAY_FROM, replayFrom);
        listener.addNativeData(API_VERSION, apiVersion.getValue());
        long connectionTimeoutMs = connectionTimeout.value().multiply(java.math.BigDecimal.valueOf(1000)).longValue();
        long readTimeoutMs = readTimeout.value().multiply(java.math.BigDecimal.valueOf(1000)).longValue();
        long keepAliveIntervalMs = keepAliveInterval.value().multiply(java.math.BigDecimal.valueOf(1000)).longValue();
        listener.addNativeData(CONNECTION_TIMEOUT, connectionTimeoutMs);
        listener.addNativeData(READ_TIMEOUT, readTimeoutMs);
        listener.addNativeData(KEEP_ALIVE_INTERVAL, keepAliveIntervalMs);
        listener.addNativeData(CONNECTION_TIMEOUT + "_display",
            connectionTimeout.value().stripTrailingZeros().toPlainString());
        if (proxyConfig != null) {
            listener.addNativeData(PROXY_CONFIG, ProxyConfig.fromBMap(proxyConfig));
        }
    }

    public static void initListener(BObject listener, int replayFrom, boolean isSandBox,
            BDecimal connectionTimeout, BDecimal readTimeout, BDecimal keepAliveInterval,
            BString apiVersion, Object proxyConfig) {
        extractBaseConfigs(listener, replayFrom, connectionTimeout, readTimeout, keepAliveInterval,
                apiVersion, proxyConfig);
        listener.addNativeData(IS_OAUTH2, false);
        listener.addNativeData(IS_SAND_BOX, isSandBox);
    }

    public static void initListener(BObject listener, int replayFrom, BString baseUrl,
            BDecimal connectionTimeout, BDecimal readTimeout, BDecimal keepAliveInterval,
            BString apiVersion, Object proxyConfig) {
        extractBaseConfigs(listener, replayFrom, connectionTimeout, readTimeout, keepAliveInterval,
                apiVersion, proxyConfig);
        listener.addNativeData(IS_OAUTH2, true);
        listener.addNativeData(BASE_URL, baseUrl.getValue());
    }

    /**
     * Sets the per-start-cycle effective {@code replayFrom} override.  Called by
     * {@code CometdStateManager.standbyTick()} (via the Ballerina external binding
     * {@code setEffectiveReplayFrom}) when resuming from a persisted coordinator
     * checkpoint.  The value is consumed and cleared by {@link #subscribeServices}
     * so it applies to exactly one subscription attempt.
     *
     * @param listener   the Ballerina {@code Listener} BObject
     * @param replayFrom the checkpoint replayId to use as the subscription start
     */
    public static void setEffectiveReplayFrom(BObject listener, int replayFrom) {
        listener.addNativeData(EFFECTIVE_REPLAY_FROM, (long) replayFrom);
    }

    public static Object attachService(Environment environment, BObject listener, BObject service, Object channelName) {
        String channel = ((BString) channelName).getValue();

        @SuppressWarnings("unchecked")
        ArrayList<BObject> services = (ArrayList<BObject>) listener.getNativeData(CONSUMER_SERVICES);
        @SuppressWarnings("unchecked")
        Map<BObject, DispatcherService> serviceDispatcherMap =
                (Map<BObject, DispatcherService>) listener.getNativeData(DISPATCHERS);

        if (service == null) {
            return null;
        }

        Set<String> methodNames = Arrays.stream(service.getType().getMethods())
                .map(MethodType::getName)
                .collect(Collectors.toSet());
        boolean hasOnMessage = methodNames.contains(DispatcherService.ON_MESSAGE);
        boolean hasCdcMethod = CDC_METHODS.stream().anyMatch(methodNames::contains);
        if (hasOnMessage && hasCdcMethod) {
            return sfdcError("Ambiguous service: the service contains methods from both 'CdcService' " +
                    "and 'PlatformEventsService'. A service must implement only one of these types.", null);
        }

        // Pass the listener BObject to DispatcherService so it can invoke
        // `recordEventDispatched` after each successful user-handler execution.
        DispatcherService dispatcherService =
                new DispatcherService(service, environment.getRuntime(), channel, listener);
        services.add(service);
        serviceDispatcherMap.put(service, dispatcherService);

        return null;
    }

    public static Object startListener(Environment env, BString username, BString password, BObject listener) {
        long readTimeoutMs = (Long) listener.getNativeData(READ_TIMEOUT);
        long keepAliveIntervalMs = (Long) listener.getNativeData(KEEP_ALIVE_INTERVAL);
        String apiVersion = (String) listener.getNativeData(API_VERSION);
        List<ProxyConfiguration.Proxy> proxies = buildProxies(listener);

        BearerTokenProvider tokenProvider = new BearerTokenProvider(() -> {
            try {
                return LoginHelper.login(username.getValue(), password.getValue(), listener, apiVersion);
            } catch (Exception e) {
                throw sfdcError(e.getMessage(), e.getCause());
            }
        });

        BayeuxParameters params;
        try {
            BayeuxParameters loginParams = tokenProvider.login();
            params = new TimeoutBayeuxParameters(loginParams, readTimeoutMs, keepAliveIntervalMs, proxies);
        } catch (Exception e) {
            throw sfdcError(e.getMessage(), e.getCause());
        }

        return startConnector(params, tokenProvider, listener);
    }

    public static Object startListener(Environment env, BObject listener) {
        String baseUrl = (String) listener.getNativeData(BASE_URL);
        long readTimeoutMs = (Long) listener.getNativeData(READ_TIMEOUT);
        long keepAliveIntervalMs = (Long) listener.getNativeData(KEEP_ALIVE_INTERVAL);
        String apiVersion = (String) listener.getNativeData(API_VERSION);
        List<ProxyConfiguration.Proxy> proxies = buildProxies(listener);

        BearerTokenProvider tokenProvider = new BearerTokenProvider(() ->
            new OAuth2BayeuxParameters(() -> getOAuth2Token(env, listener), baseUrl,
                readTimeoutMs, keepAliveIntervalMs, apiVersion, proxies));

        BayeuxParameters params;
        try {
            params = tokenProvider.login();
        } catch (Exception e) {
            throw sfdcError(e.getMessage(), e.getCause());
        }

        return startConnector(params, tokenProvider, listener);
    }

    static ProxyConfig getProxyConfig(BObject listener) {
        return (ProxyConfig) listener.getNativeData(PROXY_CONFIG);
    }

    private static List<ProxyConfiguration.Proxy> buildProxies(BObject listener) {
        ProxyConfig proxy = getProxyConfig(listener);
        if (proxy == null) {
            return Collections.emptyList();
        }
        return Collections.singletonList(
                new HttpProxy(new Origin.Address(proxy.host(), proxy.port()), proxy.isSecure(), null));
    }

    private static Object startConnector(BayeuxParameters params, BearerTokenProvider tokenProvider,
            BObject listener) {
        long connectionTimeoutMs = (Long) listener.getNativeData(CONNECTION_TIMEOUT);
        String connectionTimeoutDisplay = (String) listener.getNativeData(CONNECTION_TIMEOUT + "_display");

        EmpConnector connector = new EmpConnector(params);
        ProxyConfig proxy = getProxyConfig(listener);
        if (proxy != null && proxy.hasCredentials()) {
            connector.setProxyAuthentication(proxy.host(), proxy.port(),
                    proxy.auth().username(), proxy.auth().password(), proxy.isSecure());
        }
        connector.setBearerTokenProvider(tokenProvider);
        try {
            connector.start().get(connectionTimeoutMs, TimeUnit.MILLISECONDS);
        } catch (TimeoutException exception) {
            connector.stop();
            return sfdcError("Connection timed out after " + connectionTimeoutDisplay + " seconds.", null);
        } catch (Exception e) {
            return sfdcError(e.getMessage(), e.getCause());
        }
        listener.addNativeData(CONNECTOR, connector);
        return subscribeServices(listener, connector, connectionTimeoutMs);
    }

    private static Object subscribeServices(BObject listener, EmpConnector connector, long connectionTimeoutMs) {
        @SuppressWarnings("unchecked")
        ArrayList<BObject> services = (ArrayList<BObject>) listener.getNativeData(CONSUMER_SERVICES);
        @SuppressWarnings("unchecked")
        Map<BObject, DispatcherService> serviceDispatcherMap =
                (Map<BObject, DispatcherService>) listener.getNativeData(DISPATCHERS);
        Map<BObject, TopicSubscription> subscriptionMap =
                (Map<BObject, TopicSubscription>) listener.getNativeData(SUBSCRIPTIONS);

        // Resolve the effective replayFrom for this subscription attempt.
        // When CometdStateManager.standbyTick() loads a persisted checkpoint, it
        // calls setEffectiveReplayFrom() before startListenerWithOAuth2(), which
        // sets EFFECTIVE_REPLAY_FROM on the listener.  We consume-and-clear that
        // value here so subsequent starts fall back to the init-time REPLAY_FROM.
        long replayFrom;
        Object effectiveReplayFromObj = listener.getNativeData(EFFECTIVE_REPLAY_FROM);
        if (effectiveReplayFromObj != null) {
            replayFrom = (Long) effectiveReplayFromObj;
            // Clear so the next start (e.g. proactive token refresh) uses REPLAY_FROM.
            listener.addNativeData(EFFECTIVE_REPLAY_FROM, null);
        } else {
            replayFrom = (Integer) listener.getNativeData(REPLAY_FROM);
        }

        for (BObject service : services) {
            DispatcherService dispatcherService = serviceDispatcherMap.get(service);
            if (dispatcherService == null) {
                return sfdcError("DispatcherService not found for service.", null);
            }

            String channelName = dispatcherService.getChannelName();
            if (channelName == null) {
                return sfdcError("Channel name is not set. Please attach a service before starting the listener.",
                        null);
            }

            Consumer<Map<String, Object>> consumer = event -> injectEvent(dispatcherService, event);

            try {
                TopicSubscription subscription = connector.subscribe(channelName, replayFrom, consumer)
                        .get(connectionTimeoutMs, TimeUnit.MILLISECONDS);
                subscriptionMap.put(service, subscription);
            } catch (Exception e) {
                connector.stop();
                return sfdcError(e.getMessage(), e.getCause());
            }
        }
        return null;
    }

    public static Object detachService(BObject listener, BObject service) {
        @SuppressWarnings("unchecked")
        ArrayList<BObject> services = (ArrayList<BObject>) listener.getNativeData(CONSUMER_SERVICES);
        @SuppressWarnings("unchecked")
        Map<BObject, DispatcherService> serviceDispatcherMap =
                (Map<BObject, DispatcherService>) listener.getNativeData(DISPATCHERS);
        Map<BObject, TopicSubscription> subscriptionMap =
                (Map<BObject, TopicSubscription>) listener.getNativeData(SUBSCRIPTIONS);

        DispatcherService dispatcherService = serviceDispatcherMap.get(service);
        if (dispatcherService != null) {
            TopicSubscription subscription = subscriptionMap.get(service);
            if (subscription != null) {
                subscription.cancel();
                subscriptionMap.remove(service);
            } else {
                EmpConnector connector = (EmpConnector) listener.getNativeData(CONNECTOR);
                if (connector != null) {
                    connector.unsubscribe(dispatcherService.getChannelName());
                }
            }
        }

        services.remove(service);
        serviceDispatcherMap.remove(service);
        return null;
    }

    public static Object stopListener(BObject listener) {
        Map<BObject, TopicSubscription> subscriptionMap =
                (Map<BObject, TopicSubscription>) listener.getNativeData(SUBSCRIPTIONS);
        if (subscriptionMap != null) {
            subscriptionMap.values().forEach(TopicSubscription::cancel);
        }
        EmpConnector connector = (EmpConnector) listener.getNativeData(CONNECTOR);
        if (connector != null) {
            connector.stop();
        }
        return null;
    }

    private static void injectEvent(DispatcherService dispatcherService, Map<String, Object> eventData) {
        dispatcherService.handleDispatch(eventData);
    }

    private static String getOAuth2Token(Environment env, BObject listener) {
        Object result = env.getRuntime().callMethod(listener, GET_OAUTH2_TOKEN_METHOD, null);
        if (TypeUtils.getType(result).getTag() == TypeTags.ERROR_TAG) {
            throw sfdcError(((BError) result).getMessage(), ((BError) result).getCause());
        }
        return ((BString) result).getValue();
    }

    private static BError sfdcError(String errorMessage, Throwable cause) {
        String message = errorMessage != null ? errorMessage : "Unknown error";
        return (cause != null)
                ? ErrorCreator.createError(StringUtils.fromString(message), cause)
                : ErrorCreator.createError(StringUtils.fromString(message));
    }
}
