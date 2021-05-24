/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.sf;

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.Module;

import static io.ballerina.runtime.api.constants.RuntimeConstants.ORG_NAME_SEPARATOR;
import static io.ballerina.runtime.api.constants.RuntimeConstants.VERSION_SEPARATOR;

public class Constants {
    public static final String CONSUMER_SERVICES = "consumer_services";

    public static final String ORG = "ballerinax";
    public static final String MODULE = "sfdc";
    public static final String VERSION = "2.1.9-SNAPSHOT";
    public static final String PACKAGE = ORG + ORG_NAME_SEPARATOR + MODULE + VERSION_SEPARATOR + VERSION;
    public static final Module PACKAGE_ID_SFDC = new Module(ORG, MODULE, VERSION);

    public static final String SERVICE_CONFIG = "ServiceConfig";
    public static final String ON_EVENT = "onEvent";

    public static final BString TOPIC_NAME = StringUtils.fromString("topic");
    public static final BString REPLAY_FROM = StringUtils.fromString("replayFrom");

    public static final String SFDC_ERROR = "SFDC_Error";
}
