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
 * Copyright (c) 2016, salesforce.com, inc. All rights reserved. Licensed under the BSD 3-Clause license. For full
 * license text, see LICENSE.TXT file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
package io.ballerinax.salesforce;

import io.ballerina.runtime.api.values.BObject;
import org.eclipse.jetty.client.BasicAuthentication;
import org.eclipse.jetty.client.BytesRequestContent;
import org.eclipse.jetty.client.ContentResponse;
import org.eclipse.jetty.client.HttpClient;
import org.eclipse.jetty.client.HttpProxy;
import org.eclipse.jetty.client.ProxyConfiguration;
import org.eclipse.jetty.client.Request;
import org.xml.sax.Attributes;
import org.xml.sax.helpers.DefaultHandler;

import java.io.ByteArrayInputStream;
import java.io.UnsupportedEncodingException;
import java.net.ConnectException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.Collection;
import java.util.Collections;
import java.util.List;

import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import static io.ballerinax.salesforce.Constants.IS_SAND_BOX;
import static io.ballerinax.salesforce.ListenerUtil.PROXY_HOST;
import static io.ballerinax.salesforce.ListenerUtil.PROXY_PASSWORD;
import static io.ballerinax.salesforce.ListenerUtil.PROXY_PORT;
import static io.ballerinax.salesforce.ListenerUtil.PROXY_USERNAME;

/**
 * A helper to obtain the Authentication bearer token via login.
 *
 * @author hal.hildebrand
 * @since API v37.0
 */
public class LoginHelper {

    private static class LoginResponseParser extends DefaultHandler {

        private String buffer;
        private String faultstring;

        private boolean reading = false;
        private String serverUrl;
        private String sessionId;

        @Override
        public void characters(char[] ch, int start, int length) {
            if (reading) {
                buffer = new String(ch, start, length);
            }
        }

        @Override
        public void endElement(String uri, String localName, String qName) {
            reading = false;
            switch (localName) {
                case "sessionId":
                    sessionId = buffer;
                    break;
                case "serverUrl":
                    serverUrl = buffer;
                    break;
                case "faultstring":
                    faultstring = buffer;
                    break;
                default:
            }
            buffer = null;
        }

        @Override
        public void startElement(String uri, String localName, String qName, Attributes attributes) {
            switch (localName) {
                case "sessionId":
                    reading = true;
                    break;
                case "serverUrl":
                    reading = true;
                    break;
                case "faultstring":
                    reading = true;
                    break;
                default:
            }
        }
    }

    public static final String COMETD_REPLAY = "/cometd/";
    public static final String COMETD_REPLAY_OLD = "/cometd/replay/";
    static final String LOGIN_ENDPOINT = "https://login.salesforce.com";
    static final String TEST_LOGIN_ENDPOINT = "https://test.salesforce.com";
    private static final String ENV_END = "</soapenv:Body></soapenv:Envelope>";
    private static final String ENV_START =
            "<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' "
                    + "xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' "
                    + "xmlns:urn='urn:partner.soap.sforce.com'><soapenv:Body>";

    // The enterprise SOAP API endpoint used for the login call
    private static final String SERVICES_SOAP_PARTNER_ENDPOINT_PREFIX = "/services/Soap/u/";
    private static final String SERVICES_SOAP_PARTNER_ENDPOINT_SUFFIX = "/";

    public static BayeuxParameters login(String username, String password,
            BObject listener, String apiVersion) throws Exception {
        boolean isSandBox = (Boolean) listener.getNativeData(IS_SAND_BOX);
        String proxyHost = (String) listener.getNativeData(PROXY_HOST);
        int proxyPort = (Integer) listener.getNativeData(PROXY_PORT);
        String proxyUsername = (String) listener.getNativeData(PROXY_USERNAME);
        String proxyPassword = (String) listener.getNativeData(PROXY_PASSWORD);
        String endpoint = getLoginEndpoint(isSandBox);
        BayeuxParameters baseParams = buildProxyAwareParams(apiVersion, proxyHost, proxyPort,
                proxyUsername, proxyPassword);
        return login(new URL(endpoint), username, password, baseParams, apiVersion);
    }

    private static BayeuxParameters buildProxyAwareParams(String apiVersion, String proxyHost, int proxyPort,
            String proxyUsername, String proxyPassword) {
        return new BayeuxParameters() {
            @Override
            public String bearerToken() {
                throw new IllegalStateException("Have not authenticated");
            }

            @Override
            public URL endpoint() {
                throw new IllegalStateException("Have not established replay endpoint");
            }

            @Override
            public String version() {
                return apiVersion;
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
                if (proxyHost == null || proxyHost.isEmpty()
                        || proxyUsername == null || proxyUsername.isEmpty()) {
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
        };
    }

    public static BayeuxParameters login(URL loginEndpoint, String username, String password,
                                         BayeuxParameters parameters, String apiVersion) throws Exception {
        HttpClient client = new HttpClient();
        client.setSslContextFactory(parameters.sslContextFactory());
        try {
            parameters.proxies().forEach(client.getProxyConfiguration()::addProxy);
            parameters.configureAuthentication(client);
            client.start();
            URL endpoint = new URL(loginEndpoint, getSoapUri(apiVersion));
            Request post = client.POST(endpoint.toURI());
            post.body(new BytesRequestContent("text/xml", soapXmlForLogin(username, password)));
            post.headers(h -> h.put("SOAPAction", "''"));
            post.headers(h -> h.put("PrettyPrint", "Yes"));
            ContentResponse response = post.send();
            SAXParserFactory spf = SAXParserFactory.newInstance();
            spf.setFeature("http://xml.org/sax/features/external-general-entities", false);
            spf.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            spf.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
            spf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            spf.setNamespaceAware(true);
            SAXParser saxParser = spf.newSAXParser();

            LoginResponseParser parser = new LoginResponseParser();
            saxParser.parse(new ByteArrayInputStream(response.getContent()), parser);

            String sessionId = parser.sessionId;
            if (sessionId == null || parser.serverUrl == null) {
                throw new ConnectException(
                        String.format("Unable to login: %s", parser.faultstring));
            }

            URL soapEndpoint = new URL(parser.serverUrl);
            String cometdEndpoint = Float.parseFloat(parameters.version()) < 37 ? COMETD_REPLAY_OLD : COMETD_REPLAY;
            URL replayEndpoint = new URL(soapEndpoint.getProtocol(), soapEndpoint.getHost(), soapEndpoint.getPort(),
                    new StringBuilder().append(cometdEndpoint).append(parameters.version()).toString());
            return new DelegatingBayeuxParameters(parameters) {
                @Override
                public String bearerToken() {
                    return sessionId;
                }

                @Override
                public URL endpoint() {
                    return replayEndpoint;
                }
            };
        } finally {
            client.stop();
            client.destroy();
        }
    }

    private static String getSoapUri(String apiVersion) {
        return SERVICES_SOAP_PARTNER_ENDPOINT_PREFIX + apiVersion + SERVICES_SOAP_PARTNER_ENDPOINT_SUFFIX;
    }

    private static byte[] soapXmlForLogin(String username, String password) throws UnsupportedEncodingException {
        return (ENV_START + "  <urn:login>" + "    <urn:username>" + username + "</urn:username>" + "    <urn:password>"
                + password + "</urn:password>" + "  </urn:login>" + ENV_END).getBytes("UTF-8");
    }

    private static String getLoginEndpoint(boolean isSandBox) {
        if (isSandBox) {
            return TEST_LOGIN_ENDPOINT;
        }
        return LOGIN_ENDPOINT;
    }
}
