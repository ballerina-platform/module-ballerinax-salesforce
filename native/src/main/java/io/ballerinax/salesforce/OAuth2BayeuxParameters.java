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

import org.eclipse.jetty.client.BasicAuthentication;
import org.eclipse.jetty.client.HttpClient;
import org.eclipse.jetty.client.HttpProxy;
import org.eclipse.jetty.client.ProxyConfiguration;

import java.net.MalformedURLException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
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
    private final String apiVersion;
    private final String proxyHost;
    private final int proxyPort;
    private final String proxyUsername;
    private final String proxyPassword;

    public OAuth2BayeuxParameters(Supplier<String> tokenSupplier, String baseUrl,
            long readTimeoutMs, long keepAliveIntervalMs, String apiVersion,
            String proxyHost, int proxyPort, String proxyUsername, String proxyPassword) {
        this.tokenSupplier = tokenSupplier;
        this.baseUrl = baseUrl;
        this.readTimeoutMs = readTimeoutMs;
        this.keepAliveIntervalMs = keepAliveIntervalMs;
        this.apiVersion = apiVersion;
        this.proxyHost = proxyHost;
        this.proxyPort = proxyPort;
        this.proxyUsername = proxyUsername;
        this.proxyPassword = proxyPassword;
    }

    @Override
    public String version() {
        return apiVersion;
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

    @Override
    public Collection<? extends ProxyConfiguration.Proxy> proxies() {
        if (proxyHost == null || proxyHost.isEmpty() || proxyPort <= 0) {
            return Collections.emptyList();
        }
        return List.of(new HttpProxy(proxyHost, proxyPort));
    }

    @Override
    public void configureAuthentication(HttpClient httpClient) {
        if (proxyHost == null || proxyHost.isEmpty() || proxyUsername == null || proxyUsername.isEmpty()) {
            return;
        }
        try {
            URI proxyUri = new URI("http", null, proxyHost, proxyPort, null, null, null);
            httpClient.getAuthenticationStore().addAuthentication(
                    new BasicAuthentication(proxyUri, BasicAuthentication.ANY_REALM,
                            proxyUsername, proxyPassword));
        } catch (URISyntaxException e) {
            throw new RuntimeException("Invalid proxy URI: " + proxyHost + ":" + proxyPort, e);
        }
    }
}
