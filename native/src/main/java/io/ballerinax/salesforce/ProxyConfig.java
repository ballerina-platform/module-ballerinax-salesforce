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

package io.ballerinax.salesforce;

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;

/**
 * Representation of the ProxyConfig record.
 *
 * @param scheme the transport protocol used to connect to the proxy server ({@code "http"} or {@code "https"})
 * @param host   proxy server hostname
 * @param port   proxy server port
 * @param auth   proxy authentication credentials, or {@code null} if the proxy requires no authentication
 */
record ProxyConfig(String scheme, String host, int port, ProxyAuthConfig auth) {

    static final String FIELD_SCHEME = "scheme";
    static final String FIELD_HOST = "host";
    static final String FIELD_PORT = "port";
    static final String FIELD_AUTH = "auth";

    boolean hasCredentials() {
        return auth != null;
    }

    boolean isSecure() {
        return "https".equals(scheme);
    }

    @SuppressWarnings("unchecked")
    static ProxyConfig fromBMap(Object obj) {
        BMap<BString, Object> map = (BMap<BString, Object>) obj;
        Object authObj = map.get(StringUtils.fromString(FIELD_AUTH));
        return new ProxyConfig(
                ((BString) map.get(StringUtils.fromString(FIELD_SCHEME))).getValue(),
                ((BString) map.get(StringUtils.fromString(FIELD_HOST))).getValue(),
                ((Long) map.get(StringUtils.fromString(FIELD_PORT))).intValue(),
                authObj != null ? ProxyAuthConfig.fromBMap(authObj) : null
        );
    }
}
