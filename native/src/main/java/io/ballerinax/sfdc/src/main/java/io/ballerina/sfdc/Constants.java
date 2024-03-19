/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
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

package io.ballerina.sfdc;

/**
 * Constants for sfdc trigger implementation
 */
public class Constants {
    public static final String CONSUMER_SERVICES = "consumer_services";
    public static final String REPLAY_FROM = "replay_from";
    public static final String CHANNEL_NAME = "channel_name";

    /* Event Record type names */
    public static final String EVENT_DATA_RECORD = "EventData";
    public static final String EVENT_METADATA_RECORD = "ChangeEventMetadata";

    /* EventData payload fields */
    public static final String COMMIT_TIME_STAMP = "commitTimestamp";
    public static final String TRANSACTION_KEY = "transactionKey";
    public static final String CHANGE_ORIGIN = "changeOrigin";
    public static final String ENTITY_NAME = "entityName";
    public static final String SEQUENCE_NUMBER = "sequenceNumber";
    public static final String COMMIT_USER = "commitUser";
    public static final String COMMIT_NUMBER = "commitNumber";
    public static final String RECORD_IDS = "recordIds";
    public static final String EVENT_PAYLOAD = "payload";
    public static final String EVENT_HEADER = "ChangeEventHeader";
    public static final String EVENT_CHANGE_TYPE = "changeType";

    /* Events */
    public static final String ON_CREATE = "onCreate";
    public static final String ON_UPDATE = "onUpdate";
    public static final String ON_DELETE = "onDelete";
    public static final String ON_RESTORE = "onRestore";
    public static final String UPDATE = "UPDATE";
    public static final String CREATE = "CREATE";
    public static final String DELETE = "DELETE";
    public static final String UNDELETE = "UNDELETE";

    public static final String SFDC_ERROR = "SFDC_Error";

    public static final String ENVIRONMENT = "environment";
    public static final String PRODUCTION = "Production";
    public static final String SANDBOX = "Sandbox";
    public static final String DEVELOPMENT = "Developer";
}
