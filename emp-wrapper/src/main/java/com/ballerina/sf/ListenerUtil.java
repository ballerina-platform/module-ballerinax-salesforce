/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
 */

package com.ballerina.sf;

import org.ballerinalang.jvm.BallerinaErrors;
import org.ballerinalang.jvm.values.ErrorValue;
import org.cometd.bayeux.Channel;
import org.eclipse.jetty.util.ajax.JSON;

import java.util.ArrayList;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

import org.ballerinalang.jvm.BRuntime;
import org.ballerinalang.jvm.values.MapValue;
import org.ballerinalang.jvm.values.ObjectValue;

import static com.ballerina.sf.LoginHelper.login;

public class ListenerUtil {

    private static final ArrayList<ObjectValue> services = new ArrayList<>();
    private static BRuntime runtime;
    private static EmpConnector connector;

    public static void initListener(ObjectValue listener) {
        listener.addNativeData(Constants.CONSUMER_SERVICES, services);
    }

    public static Object attachService(ObjectValue listener, ObjectValue service) {
        @SuppressWarnings("unchecked")
        ArrayList<ObjectValue> services =
                (ArrayList<ObjectValue>) listener.getNativeData(Constants.CONSUMER_SERVICES);
        services.add(service);
        return null;
    }

    public static Object startListener(String username, String password, ObjectValue listener) {
        BearerTokenProvider tokenProvider = new BearerTokenProvider(() -> {
            try {
                return login(username, password);
            } catch (Exception e) {
                throw sfdcError(e.getMessage());
            }
        });
        BayeuxParameters params;
        try {
            params = tokenProvider.login();
        } catch (Exception e) {
            throw sfdcError(e.getMessage());
        }
        connector = new EmpConnector(params);
        LoggingListener loggingListener = new LoggingListener(true, true);
        connector.addListener(Channel.META_CONNECT, loggingListener)
                .addListener(Channel.META_DISCONNECT, loggingListener)
                .addListener(Channel.META_HANDSHAKE, loggingListener);
        try {
            connector.start().get(5, TimeUnit.SECONDS);
        } catch (Exception e) {
            throw sfdcError(e.getMessage());
        }
        runtime = BRuntime.getCurrentRuntime();
        @SuppressWarnings("unchecked")
        ArrayList<ObjectValue> services =
                (ArrayList<ObjectValue>) listener.getNativeData(Constants.CONSUMER_SERVICES);
        for (ObjectValue service : services) {
            String topic = getTopic(service);
            long replayFrom = getReplayFrom(service);
            Consumer<Map<String, Object>> consumer = event -> injectEvent(event, service, runtime);
            try {
                TopicSubscription subscription = connector.subscribe(topic, replayFrom, consumer).get(5, TimeUnit.SECONDS);
            } catch (Exception e) {
                throw sfdcError(e.getMessage());
            }
        }
        return null;
    }

    public static Object detachService(ObjectValue listener, ObjectValue service) {
        String topic = getTopic(service);
        connector.unsubscribe(topic);
        @SuppressWarnings("unchecked")
        ArrayList<ObjectValue> services =
                (ArrayList<ObjectValue>) listener.getNativeData(Constants.CONSUMER_SERVICES);
        services.remove(service);
        return null;
    }

    public static Object stopListener() {
        connector.stop();
        return null;
    }

    private static void injectEvent(Map<String, Object> event, ObjectValue serviceObject, BRuntime runtime) {
        runtime.invokeMethodAsync(serviceObject, Constants.ON_EVENT, JSON.toString(event), true);
    }

    private static String getTopic(ObjectValue service) {
        MapValue topicConfig = (MapValue) service.getType()
                .getAnnotation(Constants.PACKAGE, Constants.SERVICE_CONFIG);
        return topicConfig.getStringValue(Constants.TOPIC_NAME).getValue();
    }

    private static long getReplayFrom(ObjectValue service) {
        MapValue topicConfig = (MapValue) service.getType()
                .getAnnotation(Constants.PACKAGE, Constants.SERVICE_CONFIG);
        return topicConfig.getIntValue(Constants.REPLAY_FROM);
    }

    private static ErrorValue sfdcError(String errorMessage) {
        return BallerinaErrors.createDistinctError(Constants.SFDC_ERROR, Constants.PACKAGE_ID_SFDC, errorMessage);
    }
}
