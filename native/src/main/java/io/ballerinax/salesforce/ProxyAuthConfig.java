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
 * Representation of the ProxyAuthConfig record.
 *
 * @param username proxy username for basic authentication
 * @param password proxy password for basic authentication
 */
record ProxyAuthConfig(String username, String password) {

    static final String FIELD_USERNAME = "username";
    static final String FIELD_PASSWORD = "password";

    @SuppressWarnings("unchecked")
    static ProxyAuthConfig fromBMap(Object obj) {
        BMap<BString, Object> map = (BMap<BString, Object>) obj;
        return new ProxyAuthConfig(
                ((BString) map.get(StringUtils.fromString(FIELD_USERNAME))).getValue(),
                ((BString) map.get(StringUtils.fromString(FIELD_PASSWORD))).getValue()
        );
    }
}
