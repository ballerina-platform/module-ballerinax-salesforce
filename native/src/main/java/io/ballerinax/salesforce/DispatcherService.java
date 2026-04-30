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
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Arrays;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

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
import static io.ballerinax.salesforce.Constants.RECORD_EVENT_DISPATCHED;
import static io.ballerinax.salesforce.Constants.RECORD_IDS;
import static io.ballerinax.salesforce.Constants.SEQUENCE_NUMBER;
import static io.ballerinax.salesforce.Constants.TRANSACTION_KEY;
import static io.ballerinax.salesforce.Constants.UNDELETE;
import static io.ballerinax.salesforce.Constants.UPDATE;

/**
 * Dispatcher Service class to dispatch the event data obtained through the streaming API.
 *
 * <p>After each successful user-handler invocation, {@link #notifyCheckpoint(long)} calls
 * {@code Listener.recordEventDispatched(channel, replayId)} on the Ballerina listener so
 * that the Active-Standby coordinator can persist the high-water mark and resume correctly
 * after a leader failover.
 */
public class DispatcherService {
    private static final Logger log = LoggerFactory.getLogger(DispatcherService.class);

    public static final String ON_MESSAGE = "onMessage";
    public static final String PLATFORM_EVENT_MESSAGE = "PlatformEventsMessage";
    private static final String PLATFORM_EVENT_CHANNEL_PREFIX = "/event/";
    public static final String EVENT_FIELD = "event";
    public static final String REPLAY_ID = "replayId";

    /**
     * Strand metadata used when invoking {@code recordEventDispatched} on the Ballerina
     * listener. The method is {@code public isolated} on an {@code isolated class}, so
     * concurrent invocations are safe — hence {@code isConcurrentSafe = true}.
     */
    private static final StrandMetadata CHECKPOINT_STRAND_META = new StrandMetadata(true, null);

    private final BObject service;
    private final Runtime runtime;
    private final String channelName;
    private final Set<String> methodNames;

    /**
     * The Ballerina {@code Listener} BObject. Used to invoke
     * {@code recordEventDispatched(channel, replayId)} after each successful dispatch.
     * {@code null} for legacy callers that do not supply the listener reference (e.g.
     * direct test construction via the 2-arg constructor).
     */
    private final BObject listener;

    /** Legacy constructor — no checkpoint callback. Used by existing tests. */
    public DispatcherService(BObject service, Runtime runtime) {
        this(service, runtime, null, null);
    }

    /** Channel-aware constructor — no checkpoint callback. */
    public DispatcherService(BObject service, Runtime runtime, String channelName) {
        this(service, runtime, channelName, null);
    }

    /**
     * Full constructor used by {@link ListenerUtil#attachService} to wire the checkpoint
     * callback. The {@code listener} BObject is retained so that after each successful
     * user-handler execution the dispatcher can call
     * {@code listener.recordEventDispatched(channel, replayId)}.
     *
     * @param service     the Ballerina service BObject ({@code CdcService} or
     *                    {@code PlatformEventsService})
     * @param runtime     the Ballerina runtime used to invoke service methods
     * @param channelName fully-qualified Salesforce channel (e.g. {@code /event/Foo__e})
     * @param listener    the Ballerina {@code Listener} BObject; may be {@code null} if
     *                    checkpointing is not required
     */
    public DispatcherService(BObject service, Runtime runtime, String channelName, BObject listener) {
        this.service = service;
        this.runtime = runtime;
        this.channelName = channelName;
        this.listener = listener;
        this.methodNames = Arrays.stream(service.getType().getMethods())
                .map(MethodType::getName)
                .collect(Collectors.toSet());
    }

    public String getChannelName() {
        return channelName;
    }

    /**
     * Entry point for a single CometD event. Extracts the {@code replayId} from the
     * envelope, dispatches to the appropriate user handler, and — if the handler
     * completes without throwing — notifies the checkpoint so the coordinator can
     * persist the high-water mark.
     *
     * <p>The checkpoint notification is a best-effort fire-and-forget: any exception
     * it raises is logged and swallowed so that a checkpoint failure never disrupts
     * normal event delivery.
     *
     * @param eventData raw CometD message payload
     */
    public void handleDispatch(Map<String, Object> eventData) {
        // Extract replayId before dispatching so we have it regardless of which
        // handler path (platform event vs. CDC) is taken below.
        Long replayId = extractReplayId(eventData);

        boolean isPlatformEvent = channelName != null &&
                channelName.startsWith(PLATFORM_EVENT_CHANNEL_PREFIX);
        if (isPlatformEvent) {
            handlePlatformEvent(eventData);
        } else {
            handleCdcEvent(eventData);
        }

        // Only reached when the user handler returned successfully (no BError thrown).
        // Notify the Ballerina listener so it can persist the checkpoint replayId.
        if (replayId != null) {
            notifyCheckpoint(replayId);
        }
    }

    private void handlePlatformEvent(Map<String, Object> eventData) {
        if (methodNames.contains(ON_MESSAGE)) {
            BMap<BString, Object> record = getPlatformEventDataRecord(eventData);
            executeResourceOnEvent(record, ON_MESSAGE);
        }
    }

    private void handleCdcEvent(Map<String, Object> eventData) {
        Gson gson = new Gson();
        String eventType = new JSONObject(gson.toJson(eventData.get(EVENT_PAYLOAD)))
                .getJSONObject(EVENT_HEADER)
                .get(EVENT_CHANGE_TYPE).toString();
        BMap<BString, Object> eventDataRecord = getCdcEventDataRecord(eventData);
        if (methodNames.contains(ON_CREATE) && eventType.equals(CREATE)) {
            executeResourceOnEvent(eventDataRecord, ON_CREATE);
        } else if (methodNames.contains(ON_UPDATE) && eventType.equals(UPDATE)) {
            executeResourceOnEvent(eventDataRecord, ON_UPDATE);
        } else if (methodNames.contains(ON_DELETE) && eventType.equals(DELETE)) {
            executeResourceOnEvent(eventDataRecord, ON_DELETE);
        } else if (methodNames.contains(ON_RESTORE) && eventType.equals(UNDELETE)) {
            executeResourceOnEvent(eventDataRecord, ON_RESTORE);
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

    /**
     * Extracts the Salesforce {@code replayId} from the raw CometD event envelope.
     * Both platform events and CDC events carry the replayId under
     * {@code event.replayId} at the top level of the message data map.
     *
     * @param eventData raw CometD message payload
     * @return the replayId, or {@code null} if it cannot be found
     */
    private static Long extractReplayId(Map<String, Object> eventData) {
        Object eventEnvelope = eventData.get(EVENT_FIELD);
        if (eventEnvelope instanceof Map<?, ?> envelope) {
            Object rid = envelope.get(REPLAY_ID);
            if (rid instanceof Number number) {
                return number.longValue();
            }
        }
        return null;
    }

    /**
     * Invokes {@code Listener.recordEventDispatched(channel, replayId)} on the Ballerina
     * listener after a successful user-handler execution. This persists the high-water
     * mark so that an Active-Standby failover replica resumes from the correct position.
     *
     * <p>All exceptions are caught and logged. A checkpoint failure must never
     * propagate into the event-dispatch path — the worst outcome is that a failover
     * replica re-delivers a handful of recent events, which is consistent with
     * Salesforce's at-least-once delivery guarantee.
     *
     * @param replayId the Salesforce-issued, monotonically increasing replay ID
     */
    private void notifyCheckpoint(long replayId) {
        if (listener == null || channelName == null) {
            return;
        }
        try {
            runtime.callMethod(
                    listener,
                    RECORD_EVENT_DISPATCHED,
                    CHECKPOINT_STRAND_META,
                    StringUtils.fromString(channelName),
                    replayId
            );
        } catch (Exception e) {
            // Swallow: checkpoint failure must never disrupt event dispatch.
            log.warn("Failed to notify checkpoint for channel '{}', replayId {}: {}",
                    channelName, replayId, e.getMessage());
        }
    }

    private static BMap<BString, Object> getPlatformEventDataRecord(Map<String, Object> event) {
        ObjectMapper objectMapper = new ObjectMapper();
        BMap<BString, Object> record =
                ValueCreator.createRecordValue(ModuleUtils.getModule(), PLATFORM_EVENT_MESSAGE);
        Object payloadObj = event.get(EVENT_PAYLOAD);
        Map<?, ?> payloadMap = objectMapper.convertValue(payloadObj, Map.class);
        BMap<BString, Object> payloadBMap = toBMap(payloadMap);
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
