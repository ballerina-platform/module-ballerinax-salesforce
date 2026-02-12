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
import io.ballerina.runtime.api.utils.StringUtils;
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
    private static final ArrayList<BObject> services = new ArrayList<>();
    private static final Map<BObject, DispatcherService> serviceDispatcherMap = new HashMap<>();
    private static EmpConnector connector;
    private static TopicSubscription subscription;

    public static void initListener(BObject listener, int replayFrom, boolean isSandBox, boolean isOAuth2,
            BString baseUrl, BDecimal connectionTimeout, BDecimal readTimeout, BDecimal keepAliveInterval) {
        listener.addNativeData(CONSUMER_SERVICES, services);
        listener.addNativeData(DISPATCHERS, serviceDispatcherMap);
        listener.addNativeData(REPLAY_FROM, replayFrom);
        listener.addNativeData(IS_SAND_BOX, isSandBox);
        listener.addNativeData(IS_OAUTH2, isOAuth2);
        listener.addNativeData(BASE_URL, baseUrl.getValue());
        long connectionTimeoutMs = connectionTimeout.value().multiply(java.math.BigDecimal.valueOf(1000)).longValue();
        long readTimeoutMs = readTimeout.value().multiply(java.math.BigDecimal.valueOf(1000)).longValue();
        long keepAliveIntervalMs = keepAliveInterval.value().multiply(java.math.BigDecimal.valueOf(1000)).longValue();
        listener.addNativeData(CONNECTION_TIMEOUT, connectionTimeoutMs);
        listener.addNativeData(READ_TIMEOUT, readTimeoutMs);
        listener.addNativeData(KEEP_ALIVE_INTERVAL, keepAliveIntervalMs);
        listener.addNativeData(CONNECTION_TIMEOUT + "_display",
            connectionTimeout.value().stripTrailingZeros().toPlainString());
        listener.addNativeData(READ_TIMEOUT + "_display", readTimeout.value().stripTrailingZeros().toPlainString());
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

    public static Object startListener(BString username, BString password, BString accessToken, BObject listener) {
        boolean isOAuth2 = (Boolean) listener.getNativeData(IS_OAUTH2);
        String baseUrl = (String) listener.getNativeData(BASE_URL);
        long connectionTimeoutMs = (Long) listener.getNativeData(CONNECTION_TIMEOUT);
        long readTimeoutMs = (Long) listener.getNativeData(READ_TIMEOUT);
        long keepAliveIntervalMs = (Long) listener.getNativeData(KEEP_ALIVE_INTERVAL);
        String connectionTimeoutDisplay = (String) listener.getNativeData(CONNECTION_TIMEOUT + "_display");

        BayeuxParameters params;
        if (isOAuth2) {
            String token = accessToken.getValue();
            params = new BayeuxParameters() {
                @Override
                public String bearerToken() {
                    return token;
                }

                @Override
                public java.net.URL endpoint() {
                    try {
                        String cometdPath = LoginHelper.COMETD_REPLAY + version();
                        return new java.net.URL(baseUrl + cometdPath);
                    } catch (java.net.MalformedURLException e) {
                        throw new RuntimeException("Invalid instance URL: " + baseUrl, e);
                    }
                }

                @Override
                public int maxNetworkDelay() {
                    return (int) readTimeoutMs;
                }

                @Override
                public long keepAlive() {
                    return keepAliveIntervalMs;
                }

                @Override
                public TimeUnit keepAliveUnit() {
                    return TimeUnit.MILLISECONDS;
                }
            };
        } else {
            BearerTokenProvider tokenProvider = new BearerTokenProvider(() -> {
                try {
                    return LoginHelper.login(username.getValue(), password.getValue(), listener);
                } catch (Exception e) {
                    throw sfdcError(e.getMessage());
                }
            });
            try {
                BayeuxParameters loginParams = tokenProvider.login();
                params = new DelegatingBayeuxParameters(loginParams) {
                    @Override
                    public int maxNetworkDelay() {
                        return (int) readTimeoutMs;
                    }

                    @Override
                    public long keepAlive() {
                        return keepAliveIntervalMs;
                    }

                    @Override
                    public TimeUnit keepAliveUnit() {
                        return TimeUnit.MILLISECONDS;
                    }
                };
            } catch (Exception e) {
                throw sfdcError(e.getMessage());
            }
        }

        connector = new EmpConnector(params);
        try {
            connector.start().get(connectionTimeoutMs, TimeUnit.MILLISECONDS);
        } catch (TimeoutException exception) {
            return sfdcError("Connection timed out after " + connectionTimeoutDisplay + " seconds.");
        } catch (Exception e) {
            return sfdcError(e.getMessage());
        }

        @SuppressWarnings("unchecked")
        ArrayList<BObject> services = (ArrayList<BObject>) listener.getNativeData(CONSUMER_SERVICES);
        @SuppressWarnings("unchecked")
        Map<BObject, DispatcherService> serviceDispatcherMap =
                (Map<BObject, DispatcherService>) listener.getNativeData(DISPATCHERS);

        for (BObject service : services) {
            String channelName = listener.getNativeData(CHANNEL_NAME).toString();
            long replayFrom = (Integer) listener.getNativeData(REPLAY_FROM);

            DispatcherService dispatcherService = serviceDispatcherMap.get(service);
            if (dispatcherService == null) {
                return sfdcError("DispatcherService not found for service.");
            }

            Consumer<Map<String, Object>> consumer = event -> injectEvent(dispatcherService, event);

            try {
                subscription = connector.subscribe(channelName, replayFrom, consumer)
                        .get(connectionTimeoutMs, TimeUnit.MILLISECONDS);
            } catch (Exception e) {
                return sfdcError(e.getMessage());
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
        subscription.cancel();
        connector.stop();
        return null;
    }

    private static void injectEvent(DispatcherService dispatcherService, Map<String, Object> eventData) {
        dispatcherService.handleDispatch(eventData);
    }

    private static BError sfdcError(String errorMessage) {
        String message = errorMessage != null ? errorMessage : "Unknown error";
        return ErrorCreator.createError(StringUtils.fromString(message));
    }
}
