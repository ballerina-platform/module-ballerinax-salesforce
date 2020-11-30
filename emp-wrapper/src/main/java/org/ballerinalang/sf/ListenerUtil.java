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

package org.ballerinalang.sf;

import io.ballerina.runtime.api.ErrorCreator;
import io.ballerina.runtime.api.StringUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.async.StrandMetadata;
import org.cometd.bayeux.Channel;
import org.eclipse.jetty.util.ajax.JSON;

import java.util.ArrayList;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.values.MapValue;
import io.ballerina.runtime.values.ObjectValue;

import static org.ballerinalang.sf.LoginHelper.login;

public class ListenerUtil {

    private static final ArrayList<ObjectValue> services = new ArrayList<>();
    private static Runtime runtime;
    private static EmpConnector connector;
    private static final StrandMetadata ON_EVENT_METADATA = new StrandMetadata(Constants.ORG, Constants.MODULE,
            Constants.VERSION, Constants.ON_EVENT);

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
                return LoginHelper.login(username, password);
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
        runtime = Runtime.getCurrentRuntime();
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

    private static void injectEvent(Map<String, Object> event, ObjectValue serviceObject, Runtime runtime) {
        runtime.invokeMethodAsync(serviceObject, Constants.ON_EVENT, null, ON_EVENT_METADATA, null,
                JSON.toString(event), true);
    }

    private static String getTopic(ObjectValue service) {
        MapValue<BString, Object> topicConfig = (MapValue<BString, Object>) service.getType()
                .getAnnotation(StringUtils.fromString(Constants.PACKAGE + ":" + Constants.SERVICE_CONFIG));
        return topicConfig.getStringValue(Constants.TOPIC_NAME).getValue();
    }

    private static long getReplayFrom(ObjectValue service) {
        MapValue<BString, Object> topicConfig = (MapValue<BString, Object>) service.getType()
                .getAnnotation(StringUtils.fromString(Constants.PACKAGE + ":" + Constants.SERVICE_CONFIG));
        return topicConfig.getIntValue(Constants.REPLAY_FROM);
    }

    private static BError sfdcError(String errorMessage) {
        return ErrorCreator.createDistinctError(Constants.SFDC_ERROR, Constants.PACKAGE_ID_SFDC, StringUtils.fromString(errorMessage));
    }
}
