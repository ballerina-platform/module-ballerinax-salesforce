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

import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BError;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.function.Supplier;

/**
 * Implementation of BayeuxParameters for OAuth2 authentication.
 */
public class OAuth2BayeuxParameters implements BayeuxParameters {
    private final Supplier<String> tokenSupplier;
    private final String baseUrl;

    public OAuth2BayeuxParameters(Supplier<String> tokenSupplier, String baseUrl) {
        this.tokenSupplier = tokenSupplier;
        this.baseUrl = baseUrl;
    }

    @Override
    public String bearerToken() {
        return tokenSupplier.get();
    }

    @Override
    public URL endpoint() {
        try {
            String cometdPath = LoginHelper.COMETD_REPLAY + version();
            return new URL(baseUrl + cometdPath);
        } catch (MalformedURLException e) {
            throw createSfdcError("Invalid instance URL: " + baseUrl);
        }
    }

    private BError createSfdcError(String errorMessage) {
        return ErrorCreator.createError(StringUtils.fromString(errorMessage));
    }
}
