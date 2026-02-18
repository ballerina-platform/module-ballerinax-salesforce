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
import io.ballerina.runtime.api.types.TypeTags;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BDecimal;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.function.Consumer;

import static io.ballerinax.salesforce.Constants.CHANNEL_NAME;
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
    private static final ArrayList<BObject> services = new ArrayList<>();
    private static final Map<BObject, DispatcherService> serviceDispatcherMap = new HashMap<>();
    public static final String GET_OAUTH2_TOKEN_METHOD = "getOAuth2Token";
    private static EmpConnector connector;
    private static TopicSubscription subscription;

    private static void extractBaseConfigs(BObject listener, int replayFrom,
            BDecimal connectionTimeout, BDecimal readTimeout, BDecimal keepAliveInterval,
            BString apiVersion) {
        listener.addNativeData(CONSUMER_SERVICES, services);
        listener.addNativeData(DISPATCHERS, serviceDispatcherMap);
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
    }

    public static void initListener(BObject listener, int replayFrom, boolean isSandBox,
            BDecimal connectionTimeout, BDecimal readTimeout, BDecimal keepAliveInterval, BString apiVersion) {
        extractBaseConfigs(listener, replayFrom, connectionTimeout, readTimeout, keepAliveInterval, apiVersion);
        listener.addNativeData(IS_OAUTH2, false);
        listener.addNativeData(IS_SAND_BOX, isSandBox);
    }

    public static void initListener(BObject listener, int replayFrom, BString baseUrl,
            BDecimal connectionTimeout, BDecimal readTimeout, BDecimal keepAliveInterval, BString apiVersion) {
        extractBaseConfigs(listener, replayFrom, connectionTimeout, readTimeout, keepAliveInterval, apiVersion);
        listener.addNativeData(IS_OAUTH2, true);
        listener.addNativeData(BASE_URL, baseUrl.getValue());
    }

    public static Object attachService(Environment environment, BObject listener, BObject service, Object channelName) {
        listener.addNativeData(CHANNEL_NAME, ((BString) channelName).getValue());

        @SuppressWarnings("unchecked")
        ArrayList<BObject> services = (ArrayList<BObject>) listener.getNativeData(CONSUMER_SERVICES);
        @SuppressWarnings("unchecked")
        Map<BObject, DispatcherService> serviceDispatcherMap =
                (Map<BObject, DispatcherService>) listener.getNativeData(DISPATCHERS);

        if (service == null) {
            return null;
        }

        DispatcherService dispatcherService = new DispatcherService(service, environment.getRuntime());
        services.add(service);
        serviceDispatcherMap.put(service, dispatcherService);

        return null;
    }

    public static Object startListener(Environment env, BString username, BString password, BObject listener) {
        long readTimeoutMs = (Long) listener.getNativeData(READ_TIMEOUT);
        long keepAliveIntervalMs = (Long) listener.getNativeData(KEEP_ALIVE_INTERVAL);
        String apiVersion = (String) listener.getNativeData(API_VERSION);

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
            params = new TimeoutBayeuxParameters(loginParams, readTimeoutMs, keepAliveIntervalMs);
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

        BearerTokenProvider tokenProvider = new BearerTokenProvider(() ->
            new OAuth2BayeuxParameters(() -> getOAuth2Token(env, listener), baseUrl,
                readTimeoutMs, keepAliveIntervalMs, apiVersion));

        BayeuxParameters params;
        try {
            params = tokenProvider.login();
        } catch (Exception e) {
            throw sfdcError(e.getMessage(), e.getCause());
        }

        return startConnector(params, tokenProvider, listener);
    }

    private static Object startConnector(BayeuxParameters params, BearerTokenProvider tokenProvider,
            BObject listener) {
        long connectionTimeoutMs = (Long) listener.getNativeData(CONNECTION_TIMEOUT);
        String connectionTimeoutDisplay = (String) listener.getNativeData(CONNECTION_TIMEOUT + "_display");

        connector = new EmpConnector(params);
        connector.setBearerTokenProvider(tokenProvider);
        try {
            connector.start().get(connectionTimeoutMs, TimeUnit.MILLISECONDS);
        } catch (TimeoutException exception) {
            connector.stop();
            return sfdcError("Connection timed out after " + connectionTimeoutDisplay + " seconds.", null);
        } catch (Exception e) {
            return sfdcError(e.getMessage(), e.getCause());
        }

        return subscribeServices(listener, connectionTimeoutMs);
    }

    private static Object subscribeServices(BObject listener, long connectionTimeoutMs) {
        @SuppressWarnings("unchecked")
        ArrayList<BObject> services = (ArrayList<BObject>) listener.getNativeData(CONSUMER_SERVICES);
        @SuppressWarnings("unchecked")
        Map<BObject, DispatcherService> serviceDispatcherMap =
                (Map<BObject, DispatcherService>) listener.getNativeData(DISPATCHERS);

        for (BObject service : services) {
            Object channelNameObj = listener.getNativeData(CHANNEL_NAME);
            if (channelNameObj == null) {
                return sfdcError("Channel name is not set. Please attach a service before starting the listener.",
                        null);
            }
            String channelName = channelNameObj.toString();
            long replayFrom = (Integer) listener.getNativeData(REPLAY_FROM);

            DispatcherService dispatcherService = serviceDispatcherMap.get(service);
            if (dispatcherService == null) {
                return sfdcError("DispatcherService not found for service.", null);
            }

            Consumer<Map<String, Object>> consumer = event -> injectEvent(dispatcherService, event);

            try {
                subscription = connector.subscribe(channelName, replayFrom, consumer)
                        .get(connectionTimeoutMs, TimeUnit.MILLISECONDS);
            } catch (Exception e) {
                connector.stop();
                return sfdcError(e.getMessage(), e.getCause());
            }
        }
        return null;
    }

    public static Object detachService(BObject listener, BObject service) {
        String channel = listener.getNativeData(CHANNEL_NAME).toString();
        connector.unsubscribe(channel);
        @SuppressWarnings("unchecked")
        ArrayList<BObject> services = (ArrayList<BObject>) listener.getNativeData(CONSUMER_SERVICES);
        @SuppressWarnings("unchecked")
        Map<BObject, DispatcherService> serviceDispatcherMap =
                (Map<BObject, DispatcherService>) listener.getNativeData(DISPATCHERS);
        services.remove(service);
        serviceDispatcherMap.remove(service);
        return null;
    }

    public static Object stopListener() {
        if (subscription != null) {
            subscription.cancel();
        }
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
