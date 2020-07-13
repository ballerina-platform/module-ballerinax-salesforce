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

import org.ballerinalang.jvm.StringUtils;
import org.ballerinalang.jvm.types.BPackage;
import org.ballerinalang.jvm.values.api.BString;

import static org.ballerinalang.jvm.util.BLangConstants.ORG_NAME_SEPARATOR;
import static org.ballerinalang.jvm.util.BLangConstants.VERSION_SEPARATOR;

public class Constants {
    public static final String CONSUMER_SERVICES = "consumer_services";

    public static final String ORG = "ballerinax";
    public static final String MODULE = "sfdc";
    public static final String VERSION = "1.3.1";
    public static final String PACKAGE = ORG + ORG_NAME_SEPARATOR + MODULE + VERSION_SEPARATOR + VERSION;
    public static final BPackage PACKAGE_ID_SFDC = new BPackage(ORG, MODULE, VERSION);

    public static final String SERVICE_CONFIG = "ServiceConfig";
    public static final String ON_EVENT = "onEvent";

    public static final String TOPIC_NAME = "topic";
    public static final String REPLAY_FROM = "replayFrom";

    public static final String SFDC_ERROR = "SFDC_Error";
}
