/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
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
 */

package io.ballerinax.salesforce.mock;

import org.cometd.bayeux.MarkedReference;
import org.cometd.bayeux.Promise;
import org.cometd.bayeux.server.BayeuxServer;
import org.cometd.bayeux.server.ConfigurableServerChannel;
import org.cometd.bayeux.server.LocalSession;
import org.cometd.bayeux.server.ServerChannel;
import org.cometd.bayeux.server.ServerMessage;
import org.cometd.bayeux.server.ServerSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicLong;

/**
 * CometD service that handles subscriptions to Salesforce CDC channels
 * and provides methods to publish mock Change Data Capture events.
 */
public class MockStreamingService {

    private static final Logger log = LoggerFactory.getLogger(MockStreamingService.class);
    // Start with a value larger than Integer.MAX_VALUE so JSON parsers
    // deserialize it as Long rather than Integer (required by ReplayExtension)
    private static final AtomicLong replayIdCounter = new AtomicLong(2147483648L);
    private static MockStreamingService instance;

    private final BayeuxServer bayeuxServer;
    private final LocalSession localSession;

    public MockStreamingService(BayeuxServer bayeuxServer) {
        this.bayeuxServer = bayeuxServer;
        this.localSession = bayeuxServer.newLocalSession("mock-streaming");
        this.localSession.handshake();
        instance = this;

        // Add extension to support replay and log message delivery
        bayeuxServer.addExtension(new BayeuxServer.Extension.Adapter() {
            @Override
            public boolean rcvMeta(ServerSession from, ServerMessage.Mutable message) {
                return true;
            }

            @Override
            public boolean sendMeta(ServerSession to, ServerMessage.Mutable message) {
                if ("/meta/handshake".equals(message.getChannel())) {
                    Map<String, Object> ext = message.getExt(true);
                    ext.put("replay", true);
                }
                return true;
            }

            @Override
            public boolean send(ServerSession from, ServerSession to, ServerMessage.Mutable message) {
                if (!message.getChannel().startsWith("/meta/")) {
                    log.info("Delivering event on channel {} to session {}", message.getChannel(),
                            to != null ? to.getId() : "null");
                }
                return true;
            }
        });

        // Listen for subscriptions to /data/** channels
        bayeuxServer.addListener(new BayeuxServer.SubscriptionListener() {
            @Override
            public void subscribed(ServerSession session, ServerChannel channel, ServerMessage message) {
                log.info("Client subscribed to channel: {}", channel.getId());
            }

            @Override
            public void unsubscribed(ServerSession session, ServerChannel channel, ServerMessage message) {
                log.info("Client unsubscribed from channel: {}", channel.getId());
            }
        });

        log.info("MockStreamingService initialized");
    }

    static MockStreamingService getInstance() {
        return instance;
    }

    /**
     * Publishes a Change Data Capture event to the specified channel.
     *
     * @param channel    the CDC channel (e.g., "/data/ChangeEvents")
     * @param changeType the type of change: CREATE, UPDATE, DELETE, or UNDELETE
     * @param entityName the SObject name (e.g., "Account")
     * @param recordId   the record ID
     * @param changedFields  map of changed field names to values
     */
    public void publishEvent(String channel, String changeType, String entityName,
                             String recordId, Map<String, Object> changedFields) {
        long replayId = replayIdCounter.getAndIncrement();

        Map<String, Object> changeEventHeader = new HashMap<>();
        changeEventHeader.put("commitTimestamp", System.currentTimeMillis());
        changeEventHeader.put("transactionKey", UUID.randomUUID().toString());
        changeEventHeader.put("changeOrigin", "com/salesforce/api/soap/44.0;client=SfdcInternalAPI/");
        changeEventHeader.put("changeType", changeType);
        changeEventHeader.put("entityName", entityName);
        changeEventHeader.put("sequenceNumber", 1);
        changeEventHeader.put("commitUser", "005000000000001");
        changeEventHeader.put("commitNumber", replayId);

        List<String> recordIds = new ArrayList<>();
        recordIds.add(recordId);
        changeEventHeader.put("recordIds", recordIds);

        Map<String, Object> payload = new HashMap<>(changedFields);
        payload.put("ChangeEventHeader", changeEventHeader);

        Map<String, Object> eventData = new HashMap<>();
        eventData.put("payload", payload);

        Map<String, Object> event = new HashMap<>();
        event.put("replayId", replayId);
        eventData.put("event", event);

        // Create the channel if it doesn't exist and publish
        MarkedReference<ServerChannel> channelRef = bayeuxServer.createChannelIfAbsent(channel,
                new ConfigurableServerChannel.Initializer() {
                    @Override
                    public void configureChannel(ConfigurableServerChannel ch) {
                        ch.setPersistent(true);
                        ch.setLazy(false);
                    }
                });

        ServerChannel serverChannel = channelRef.getReference();

        // Deliver directly to each subscriber for reliable delivery
        for (ServerSession subscriber : serverChannel.getSubscribers()) {
            log.info("Delivering {} event to subscriber {} on channel {}",
                    changeType, subscriber.getId(), channel);
            subscriber.deliver(localSession.getServerSession(), channel, eventData, Promise.noop());
        }

        log.info("Published {} event for {} on channel {} with replayId {}",
                changeType, entityName, channel, replayId);
    }
}
