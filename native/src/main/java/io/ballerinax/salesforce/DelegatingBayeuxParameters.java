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

/*
 * Copyright (c) 2016, salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.TXT file in the repo root  or https://opensource.org/licenses/BSD-3-Clause
 */

package io.ballerinax.salesforce;

import org.eclipse.jetty.client.ProxyConfiguration.Proxy;
import org.eclipse.jetty.util.ssl.SslContextFactory;

import java.net.URL;
import java.util.Collection;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * @author hal.hildebrand
 * @since API v37.0
 */
public class DelegatingBayeuxParameters implements BayeuxParameters {
    private final BayeuxParameters parameters;

    public DelegatingBayeuxParameters(BayeuxParameters parameters) {
        this.parameters = parameters;
    }

    @Override
    public String bearerToken() {
        return parameters.bearerToken();
    }

    @Override
    public URL endpoint() {
        return parameters.endpoint();
    }

    @Override
    public long keepAlive() {
        return parameters.keepAlive();
    }

    @Override
    public TimeUnit keepAliveUnit() {
        return parameters.keepAliveUnit();
    }

    @Override
    public Map<String, Object> longPollingOptions() {
        return parameters.longPollingOptions();
    }

    @Override
    public int maxBufferSize() {
        return parameters.maxBufferSize();
    }

    @Override
    public int maxNetworkDelay() {
        return parameters.maxNetworkDelay();
    }

    @Override
    public Collection<? extends Proxy> proxies() {
        return parameters.proxies();
    }

    @Override
    public SslContextFactory sslContextFactory() {
        return parameters.sslContextFactory();
    }

    @Override
    public String version() {
        return parameters.version();
    }
}
