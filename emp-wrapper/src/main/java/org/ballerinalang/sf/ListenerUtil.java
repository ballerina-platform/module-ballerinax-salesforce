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

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.gson.Gson;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.async.StrandMetadata;
import org.cometd.bayeux.Channel;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.internal.values.MapValue;
import io.ballerina.runtime.internal.values.ObjectValue;

import static org.ballerinalang.sf.Constants.*;

public class ListenerUtil {
    private static final ArrayList<ObjectValue> services = new ArrayList<>();
    private static Runtime runtime;
    private static EmpConnector connector;
    private static TopicSubscription subscription;

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
                subscription = connector.subscribe(topic, replayFrom, consumer).get(5, TimeUnit.SECONDS);
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
        // Cancel a subscription
        subscription.cancel();
        // Stop the connector
        connector.stop();
        return null;
    }

    private static void injectEvent(Map<String, Object> event, ObjectValue serviceObject, Runtime runtime) {
        Gson gson = new Gson();
        String eventType = new JSONObject(gson.toJson(event
                          .get(EVENT_PAYLOAD)))
                          .getJSONObject(EVENT_HEADER)
                          .get(EVENT_CHANGE_TYPE).toString();

        BMap<BString, Object> eventObject = getEventDataRecord(event);
        switch (eventType) {
            case "UPDATE":
                final StrandMetadata ON_UPDATE_METADATA = new StrandMetadata(Constants.ORG, Constants.MODULE,
                        Constants.VERSION,Constants.ON_UPDATE);
                runtime.invokeMethodAsync(serviceObject, Constants.ON_UPDATE, null, ON_UPDATE_METADATA, null,
                        eventObject,true);
                break;
            case "CREATE":
                final StrandMetadata ON_CREATE_METADATA = new StrandMetadata(Constants.ORG, Constants.MODULE,
                        Constants.VERSION,Constants.ON_CREATE);
                runtime.invokeMethodAsync(serviceObject, Constants.ON_CREATE, null, ON_CREATE_METADATA, null,
                        eventObject, true);
                break;
            case "DELETE":
                final StrandMetadata ON_DELETE_METADATA = new StrandMetadata(Constants.ORG, Constants.MODULE,
                        Constants.VERSION,Constants.ON_DELETE);
                runtime.invokeMethodAsync(serviceObject, Constants.ON_DELETE, null, ON_DELETE_METADATA, null,
                        eventObject, true);
                break;
            case "UNDELETE":
                final StrandMetadata ON_RESTORE_METADATA = new StrandMetadata(Constants.ORG, Constants.MODULE,
                        Constants.VERSION,Constants.ON_RESTORE);
                runtime.invokeMethodAsync(serviceObject, Constants.ON_RESTORE, null, ON_RESTORE_METADATA, null,
                        eventObject, true);
                break;
        }
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
        return ErrorCreator.createDistinctError(Constants.SFDC_ERROR, PACKAGE_ID_SFDC,
                StringUtils.fromString(errorMessage));
    }

    /**
     * Convert Map to BMap.
     *
     * @param map Input Map used to convert to BMap.
     * @return Converted BMap object.
     */
    public static BMap<BString, Object> toBMap(Map map) {
        BMap<BString, Object> returnMap = ValueCreator.createMapValue();
        if (map != null) {
            for (Object aKey : map.keySet().toArray()) {
                returnMap.put(StringUtils.fromString(aKey.toString()),
                        StringUtils.fromString(map.get(aKey).toString()));
            }
        }
        return returnMap;
    }

    /**
     * Convert Map to Ballerina record tpe
     *
     * @param event Input Map used to convert to BMap.
     * @return Converted BMap object.
     */
    private static BMap<BString, Object> getEventDataRecord(Map<String, Object> event)  {
        Gson gson = new Gson();
        ObjectMapper oMapper = new ObjectMapper();
        Object[] eventData = new Object[2];
        Object[] metadata = new Object[8];

        Object eventPayload = event.get(EVENT_PAYLOAD);
        Map map = oMapper.convertValue(eventPayload, Map.class);
        BMap<BString, Object> eventDataRecord =
                ValueCreator.createRecordValue(PACKAGE_ID_SFDC, EVENT_DATA_RECORD);
        eventData[0] = toBMap(map);
        BMap<BString, Object> eventMetadataRecord =
                ValueCreator.createRecordValue(PACKAGE_ID_SFDC, EVENT_METADATA_RECORD);
        String commitTimestamp = new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).get("commitTimestamp").toString();
        metadata[0] = commitTimestamp;
        String transactionKey = new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).get("transactionKey").toString();
        metadata[1] = transactionKey;
        String changeOrigin = (String) new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).get("changeOrigin");
        metadata[2] = changeOrigin;
        String changeType = new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).get(EVENT_CHANGE_TYPE).toString();
        metadata[3] = changeType;
        String entityName = (String) new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).get("entityName");
        metadata[4] = entityName;
        Integer sequenceNumber = (Integer) new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).get("sequenceNumber");
        metadata[5] = sequenceNumber;
        String commitUser = (String) new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).get("commitUser");
        metadata[6] = commitUser;
        String commitNumber = new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).get("commitNumber").toString();
        metadata[7] = commitNumber;
        eventData[1] = ValueCreator.createRecordValue(eventMetadataRecord, metadata);
        return ValueCreator.createRecordValue(eventDataRecord, eventData);
    }
}
