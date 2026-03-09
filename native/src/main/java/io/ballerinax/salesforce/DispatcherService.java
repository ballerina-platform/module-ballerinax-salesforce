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

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.gson.Gson;
import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.concurrent.StrandMetadata;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.ObjectType;
import io.ballerina.runtime.api.utils.JsonUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import org.json.JSONObject;

import java.util.Map;

import static io.ballerinax.salesforce.Constants.CHANGE_ORIGIN;
import static io.ballerinax.salesforce.Constants.COMMIT_NUMBER;
import static io.ballerinax.salesforce.Constants.COMMIT_TIME_STAMP;
import static io.ballerinax.salesforce.Constants.COMMIT_USER;
import static io.ballerinax.salesforce.Constants.CREATE;
import static io.ballerinax.salesforce.Constants.DELETE;
import static io.ballerinax.salesforce.Constants.ENTITY_NAME;
import static io.ballerinax.salesforce.Constants.EVENT_CHANGE_TYPE;
import static io.ballerinax.salesforce.Constants.EVENT_DATA_RECORD;
import static io.ballerinax.salesforce.Constants.EVENT_HEADER;
import static io.ballerinax.salesforce.Constants.EVENT_METADATA_RECORD;
import static io.ballerinax.salesforce.Constants.EVENT_PAYLOAD;
import static io.ballerinax.salesforce.Constants.ON_CREATE;
import static io.ballerinax.salesforce.Constants.ON_DELETE;
import static io.ballerinax.salesforce.Constants.ON_RESTORE;
import static io.ballerinax.salesforce.Constants.ON_UPDATE;
import static io.ballerinax.salesforce.Constants.RECORD_IDS;
import static io.ballerinax.salesforce.Constants.SEQUENCE_NUMBER;
import static io.ballerinax.salesforce.Constants.TRANSACTION_KEY;
import static io.ballerinax.salesforce.Constants.UNDELETE;
import static io.ballerinax.salesforce.Constants.UPDATE;

/**
 * Dispatcher Service class to dispatch the event data obtained through the streaming API.
 */
public class DispatcherService {
    public static final String ON_MESSAGE = "onMessage";
    public static final String PLATFORM_EVENT_MESSAGE = "PlatformEventsMessage";
    private static final String PLATFORM_EVENT_CHANNEL_PREFIX = "/event/";
    public static final String EVENT_FIELD = "event";
    public static final String REPLAY_ID = "replayId";

    private final BObject service;
    private final Runtime runtime;
    private final String channelName;

    public DispatcherService(BObject service, Runtime runtime) {
        this(service, runtime, null);
    }

    public DispatcherService(BObject service, Runtime runtime, String channelName) {
        this.service = service;
        this.runtime = runtime;
        this.channelName = channelName;
    }

    public String getChannelName() {
        return channelName;
    }

    public void handleDispatch(Map<String, Object> eventData) {
        boolean isPlatformEvent = channelName != null &&
                channelName.startsWith(PLATFORM_EVENT_CHANNEL_PREFIX);

        if (isPlatformEvent) {
            handlePlatformEvent(eventData);
        } else {
            handleCdcEvent(eventData);
        }
    }

    private void handlePlatformEvent(Map<String, Object> eventData) {
        MethodType[] attachedFunctions = service.getType().getMethods();
        for (MethodType function : attachedFunctions) {
            if (ON_MESSAGE.equals(function.getName())) {
                BMap<BString, Object> record = getPlatformEventDataRecord(eventData);
                executeResourceOnEvent(record, ON_MESSAGE);
            }
        }
    }

    private void handleCdcEvent(Map<String, Object> eventData) {
        MethodType[] attachedFunctions = service.getType().getMethods();
        Gson gson = new Gson();
        String eventType = new JSONObject(gson.toJson(eventData.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER)
                .get(EVENT_CHANGE_TYPE).toString();
        BMap<BString, Object> eventDataRecord = getCdcEventDataRecord(eventData);
        for (MethodType function : attachedFunctions) {
            if (ON_CREATE.equals(function.getName()) && eventType.equals(CREATE)) {
                executeResourceOnEvent(eventDataRecord, ON_CREATE);
            }
            if (ON_UPDATE.equals(function.getName()) && eventType.equals(UPDATE)) {
                executeResourceOnEvent(eventDataRecord, ON_UPDATE);
            }
            if (ON_DELETE.equals(function.getName()) && eventType.equals(DELETE)) {
                executeResourceOnEvent(eventDataRecord, ON_DELETE);
            }
            if (ON_RESTORE.equals(function.getName()) && eventType.equals(UNDELETE)) {
                executeResourceOnEvent(eventDataRecord, ON_RESTORE);
            }
        }
    }

    private void executeResourceOnEvent(BMap<BString, Object> eventRecord, String functionName) {
        Object result = executeResource(functionName, eventRecord);
        if (result instanceof BError bError) {
            throw bError;
        }
    }

    private Object executeResource(String functionName, BMap<BString, Object> eventRecord) {
        ObjectType serviceType = (ObjectType) TypeUtils.getReferredType(TypeUtils.getType(service));
        boolean isIsolated = serviceType.isIsolated() && serviceType.isIsolated(functionName);
        return runtime.callMethod(service, functionName,
                new StrandMetadata(isIsolated, ModuleUtils.getProperties(functionName)), eventRecord);
    }

    private static BMap<BString, Object> getPlatformEventDataRecord(Map<String, Object> event) {
        ObjectMapper objectMapper = new ObjectMapper();
        BMap<BString, Object> record =
                ValueCreator.createRecordValue(ModuleUtils.getModule(), PLATFORM_EVENT_MESSAGE);
        Object payloadObj = event.get(EVENT_PAYLOAD);
        Map<?, ?> payloadMap = objectMapper.convertValue(payloadObj, Map.class);
        BMap<BString, Object> payloadBMap = toJson(payloadMap);
        Long replayId = null;
        Object eventEnvelope = event.get(EVENT_FIELD);
        if (eventEnvelope instanceof Map) {
            Object rid = ((Map<?, ?>) eventEnvelope).get(REPLAY_ID);
            if (rid instanceof Number) {
                replayId = ((Number) rid).longValue();
            }
        }
        return ValueCreator.createRecordValue(record, payloadBMap, replayId);
    }

    public static BMap<BString, Object> toBMap(Map<?, ?> map) {
        BMap<BString, Object> returnMap = ValueCreator.createMapValue();
        if (map != null) {
            for (Object aKey : map.keySet().toArray()) {
                returnMap.put(StringUtils.fromString(aKey.toString()),
                        StringUtils.fromString(map.get(aKey).toString()));
            }
        }
        return returnMap;
    }

    public static BMap<BString, Object> toJson(Map<?, ?> map) {
        BMap<BString, Object> returnMap = ValueCreator.createMapValue();
        if (map != null) {
            for (Object aKey : map.keySet().toArray()) {
                returnMap.put(StringUtils.fromString(aKey.toString()), JsonUtils.convertToJson(map.get(aKey)));
            }
        }
        return returnMap;
    }

    private static BMap<BString, Object> getCdcEventDataRecord(Map<String, Object> event) {
        Gson gson = new Gson();
        ObjectMapper oMapper = new ObjectMapper();
        Object[] eventData = new Object[2];
        Object[] metadata = new Object[9];

        Object eventPayload = event.get(EVENT_PAYLOAD);
        Map<?, ?> map = oMapper.convertValue(eventPayload, Map.class);
        BMap<BString, Object> eventDataRecord =
                ValueCreator.createRecordValue(ModuleUtils.getModule(), EVENT_DATA_RECORD);
        eventData[0] = toBMap(map);
        BMap<BString, Object> eventMetadataRecord =
                ValueCreator.createRecordValue(ModuleUtils.getModule(), EVENT_METADATA_RECORD);
        String commitTimestamp = new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).get(COMMIT_TIME_STAMP).toString();
        metadata[0] = commitTimestamp;
        String transactionKey = new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).get(TRANSACTION_KEY).toString();
        metadata[1] = transactionKey;
        String changeOrigin = (String) new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).get(CHANGE_ORIGIN);
        metadata[2] = changeOrigin;
        String changeType = new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).get(EVENT_CHANGE_TYPE).toString();
        metadata[3] = changeType;
        String entityName = (String) new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).get(ENTITY_NAME);
        metadata[4] = entityName;
        Integer sequenceNumber = (Integer) new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).get(SEQUENCE_NUMBER);
        metadata[5] = sequenceNumber;
        String commitUser = (String) new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).get(COMMIT_USER);
        metadata[6] = commitUser;
        String commitNumber = new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).get(COMMIT_NUMBER).toString();
        metadata[7] = commitNumber;
        String recordId = new JSONObject(gson.toJson(event.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER).getJSONArray(RECORD_IDS).get(0).toString();
        metadata[8] = recordId;
        eventData[1] = ValueCreator.createRecordValue(eventMetadataRecord, metadata);
        return ValueCreator.createRecordValue(eventDataRecord, eventData);
    }
}
