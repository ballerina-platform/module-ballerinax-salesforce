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

import java.net.MalformedURLException;
import java.net.URL;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;

/**
 * Implementation of BayeuxParameters for OAuth2 authentication.
 */
public class OAuth2BayeuxParameters implements BayeuxParameters {
    private final Supplier<String> tokenSupplier;
    private final String baseUrl;
    private final long readTimeoutMs;
    private final long keepAliveIntervalMs;

    public OAuth2BayeuxParameters(Supplier<String> tokenSupplier, String baseUrl, 
        long readTimeoutMs, long keepAliveIntervalMs) {
        this.tokenSupplier = tokenSupplier;
        this.baseUrl = baseUrl;
        this.readTimeoutMs = readTimeoutMs;
        this.keepAliveIntervalMs = keepAliveIntervalMs;
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
        } catch (MalformedURLException exception) {
            throw new RuntimeException("Invalid instance URL: " + baseUrl, exception);
        }
    }

    @Override
    public int maxNetworkDelay() {
        return (int) readTimeoutMs;
    }

    @Override
    public long keepAlive() {
        return keepAliveIntervalMs;
    }

    @Override
    public TimeUnit keepAliveUnit() {
        return TimeUnit.MILLISECONDS;
    }
}
