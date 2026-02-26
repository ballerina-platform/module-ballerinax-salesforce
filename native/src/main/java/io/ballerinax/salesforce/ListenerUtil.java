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

package io.ballerinax.salesforce;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.types.TypeTags;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BDecimal;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import org.eclipse.jetty.util.ssl.SslContextFactory;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.GeneralSecurityException;
import java.security.KeyFactory;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.function.Consumer;

import static io.ballerinax.salesforce.Constants.CHANNEL_NAME;
import static io.ballerinax.salesforce.Constants.CONSUMER_SERVICES;
import static io.ballerinax.salesforce.Constants.DISPATCHERS;
import static io.ballerinax.salesforce.Constants.IS_SAND_BOX;
import static io.ballerinax.salesforce.Constants.REPLAY_FROM;

/**
 * Util class containing the java external functions for Ballerina Salesforce listener.
 */
public class ListenerUtil {
    public static final String IS_OAUTH2 = "isOAuth2";
    public static final String BASE_URL = "baseUrl";
    public static final String CONNECTION_TIMEOUT = "connectionTimeout";
    public static final String READ_TIMEOUT = "readTimeout";
    public static final String KEEP_ALIVE_INTERVAL = "keepAliveInterval";
    public static final String API_VERSION = "apiVersion";
    public static final String KEYSTORE_PATH = "secureSocket_keystore_path";
    public static final String KEYSTORE_PASSWORD = "secureSocket_keystore_password";
    public static final String KEYSTORE_CERT_FILE = "secureSocket_certkey_certFile";
    public static final String KEYSTORE_KEY_FILE = "secureSocket_certkey_keyFile";
    public static final String KEYSTORE_KEY_PASSWORD = "secureSocket_certkey_keyPassword";
    public static final String TRUSTSTORE_PATH = "secureSocket_truststore_path";
    public static final String TRUSTSTORE_PASSWORD = "secureSocket_truststore_password";
    public static final String TRUSTSTORE_CERT_FILE = "secureSocket_cert_file";
    private static final ArrayList<BObject> services = new ArrayList<>();
    private static final Map<BObject, DispatcherService> serviceDispatcherMap = new HashMap<>();
    public static final String GET_OAUTH2_TOKEN_METHOD = "getOAuth2Token";
    public static final BString FIELD_PATH = StringUtils.fromString("path");
    public static final BString FIELD_PASSWORD = StringUtils.fromString("password");
    public static final BString FIELD_CERT_FILE = StringUtils.fromString("certFile");
    public static final BString FIELD_KEY_FILE = StringUtils.fromString("keyFile");
    public static final BString FIELD_KEY_PASSWORD = StringUtils.fromString("keyPassword");
    public static final BString KEYSTORE_CONFIG = StringUtils.fromString("key");
    public static final BString TRUSTSTORE_CONFIG = StringUtils.fromString("cert");
    public static final String X_509 = "X.509";
    private static EmpConnector connector;
    private static TopicSubscription subscription;

    private static void extractBaseConfigs(BObject listener, int replayFrom,
            BDecimal connectionTimeout, BDecimal readTimeout, BDecimal keepAliveInterval,
            BString apiVersion) {
        listener.addNativeData(CONSUMER_SERVICES, services);
        listener.addNativeData(DISPATCHERS, serviceDispatcherMap);
        listener.addNativeData(REPLAY_FROM, replayFrom);
        listener.addNativeData(API_VERSION, apiVersion.getValue());
        long connectionTimeoutMs = connectionTimeout.value().multiply(BigDecimal.valueOf(1000)).longValue();
        long readTimeoutMs = readTimeout.value().multiply(BigDecimal.valueOf(1000)).longValue();
        long keepAliveIntervalMs = keepAliveInterval.value().multiply(BigDecimal.valueOf(1000)).longValue();
        listener.addNativeData(CONNECTION_TIMEOUT, connectionTimeoutMs);
        listener.addNativeData(READ_TIMEOUT, readTimeoutMs);
        listener.addNativeData(KEEP_ALIVE_INTERVAL, keepAliveIntervalMs);
        listener.addNativeData(CONNECTION_TIMEOUT + "_display",
            connectionTimeout.value().stripTrailingZeros().toPlainString());
    }

    public static void initListener(BObject listener, int replayFrom, boolean isSandBox,
            BDecimal connectionTimeout, BDecimal readTimeout, BDecimal keepAliveInterval, BString apiVersion,
            Object secureSocket) {
        extractBaseConfigs(listener, replayFrom, connectionTimeout, readTimeout, keepAliveInterval, apiVersion);
        listener.addNativeData(IS_OAUTH2, false);
        listener.addNativeData(IS_SAND_BOX, isSandBox);
        if (secureSocket != null) {
            extractSecureSocketConfig(listener, (BMap<?, ?>) secureSocket);
        }
    }

    public static void initListener(BObject listener, int replayFrom, BString baseUrl, BDecimal connectionTimeout,
                                    BDecimal readTimeout, BDecimal keepAliveInterval, BString apiVersion,
                                    Object secureSocket) {
        extractBaseConfigs(listener, replayFrom, connectionTimeout, readTimeout, keepAliveInterval, apiVersion);
        listener.addNativeData(IS_OAUTH2, true);
        listener.addNativeData(BASE_URL, baseUrl.getValue());
        if (secureSocket != null) {
            extractSecureSocketConfig(listener, (BMap<?, ?>) secureSocket);
        }
    }

    private static void extractSecureSocketConfig(BObject listener, BMap<?, ?> secureSocketMap) {
        BMap<?, ?> keyField = secureSocketMap.getMapValue(KEYSTORE_CONFIG);
        if (keyField != null && keyField.containsKey(FIELD_PATH)) {
            BString path = keyField.getStringValue(FIELD_PATH);
            BString password = keyField.getStringValue(FIELD_PASSWORD);
            listener.addNativeData(KEYSTORE_PATH, path.getValue());
            listener.addNativeData(KEYSTORE_PASSWORD, password.getValue());
        } else if (keyField != null && keyField.containsKey(FIELD_CERT_FILE)) {
            BString certFile = keyField.getStringValue(FIELD_CERT_FILE);
            BString keyFile = keyField.getStringValue(FIELD_KEY_FILE);
            listener.addNativeData(KEYSTORE_CERT_FILE, certFile.getValue());
            listener.addNativeData(KEYSTORE_KEY_FILE, keyFile.getValue());
            BString keyPassword = keyField.getStringValue(FIELD_KEY_PASSWORD);
            if (keyPassword != null) {
                listener.addNativeData(KEYSTORE_KEY_PASSWORD, keyPassword.getValue());
            }
        }
        Object certField = secureSocketMap.get(TRUSTSTORE_CONFIG);
        if (TypeUtils.getType(certField).getTag() == TypeTags.MAP_TAG) {
            BString path = ((BMap<?, ?>) certField).getStringValue(FIELD_PATH);
            BString password = ((BMap<?, ?>) certField).getStringValue(FIELD_PASSWORD);
            listener.addNativeData(TRUSTSTORE_PATH, path.getValue());
            listener.addNativeData(TRUSTSTORE_PASSWORD, password.getValue());
        } else if (TypeUtils.getType(certField).getTag() == TypeTags.STRING_TAG) {
            listener.addNativeData(TRUSTSTORE_CERT_FILE, ((BString) certField).getValue());
        }
    }

    private static SslContextFactory buildSslContextFactory(BObject listener) {
        SslContextFactory.Client factory = new SslContextFactory.Client();
        factory.setEndpointIdentificationAlgorithm("HTTPS");
        String keystorePath = (String) listener.getNativeData(KEYSTORE_PATH);
        if (keystorePath != null) {
            factory.setKeyStorePath(keystorePath);
            factory.setKeyStorePassword((String) listener.getNativeData(KEYSTORE_PASSWORD));
        }
        String certKeyFile = (String) listener.getNativeData(KEYSTORE_CERT_FILE);
        if (certKeyFile != null) {
            String keyFile = (String) listener.getNativeData(KEYSTORE_KEY_FILE);
            String keyPassword = (String) listener.getNativeData(KEYSTORE_KEY_PASSWORD);
            char[] keyPasswordChars = keyPassword != null ? keyPassword.toCharArray() : new char[0];
            try {
                KeyStore keystore = buildKeyStoreFromPem(certKeyFile, keyFile, keyPasswordChars);
                factory.setKeyStore(keystore);
                factory.setKeyStorePassword(keyPassword != null ? keyPassword : "");
            } catch (GeneralSecurityException | IOException e) {
                throw new IllegalArgumentException("Failed to load the keystore: " + e.getMessage(), e);
            }
        }

        String truststorePath = (String) listener.getNativeData(TRUSTSTORE_PATH);
        if (truststorePath != null) {
            factory.setTrustStorePath(truststorePath);
            factory.setTrustStorePassword((String) listener.getNativeData(TRUSTSTORE_PASSWORD));
        }
        String certFilePath = (String) listener.getNativeData(TRUSTSTORE_CERT_FILE);
        if (certFilePath != null) {
            try {
                KeyStore ts = buildTrustStoreFromPem(certFilePath);
                factory.setTrustStore(ts);
            } catch (GeneralSecurityException | IOException e) {
                throw new IllegalArgumentException("Failed to load the truststore: " + e.getMessage(), e);
            }
        }

        return factory;
    }

    private static KeyStore buildKeyStoreFromPem(String certFilePath, String keyFilePath, char[] keyPassword)
            throws GeneralSecurityException, IOException {
        CertificateFactory cf = CertificateFactory.getInstance(X_509);
        Certificate cert;
        try (InputStream certIn = new FileInputStream(certFilePath)) {
            cert = cf.generateCertificate(certIn);
        }
        byte[] keyBytes = readPemKey(keyFilePath);
        PrivateKey privateKey = loadPrivateKey(keyBytes);
        KeyStore keystore = KeyStore.getInstance(KeyStore.getDefaultType());
        keystore.load(null, null);
        keystore.setKeyEntry("client", privateKey, keyPassword, new Certificate[]{cert});
        return keystore;
    }

    private static PrivateKey loadPrivateKey(byte[] keyBytes) throws GeneralSecurityException {
        PKCS8EncodedKeySpec spec = new PKCS8EncodedKeySpec(keyBytes);
        for (String algorithm : new String[]{"RSA", "EC", "DSA"}) {
            try {
                return KeyFactory.getInstance(algorithm).generatePrivate(spec);
            } catch (InvalidKeySpecException ignored) { // ignore and try next algorithm
            }
        }
        throw new InvalidKeySpecException("The private key algorithm is not supported." +
                " Only RSA, EC, and DSA are supported.");
    }

    private static KeyStore buildTrustStoreFromPem(String certFilePath)
            throws GeneralSecurityException, IOException {
        CertificateFactory cf = CertificateFactory.getInstance(X_509);
        KeyStore truststore = KeyStore.getInstance(KeyStore.getDefaultType());
        truststore.load(null, null);
        try (InputStream certIn = new FileInputStream(certFilePath)) {
            int index = 0;
            for (Certificate cert : cf.generateCertificates(certIn)) {
                truststore.setCertificateEntry("trusted-" + index++, cert);
            }
        } catch (CertificateException | IOException exception) {
            throw new IOException("Failed to read certificates from " + certFilePath + ": " + exception.getMessage(),
                    exception);
        }
        if (truststore.size() == 0) {
            throw new IllegalArgumentException("No certificates found in: " + certFilePath);
        }
        return truststore;
    }

    private static byte[] readPemKey(String filePath) throws IOException {
        String content = Files.readString(Paths.get(filePath));
        String stripped = content.replaceAll("-----[^-]+-----", "").replaceAll("\\s+", "");
        return Base64.getDecoder().decode(stripped);
    }

    public static Object attachService(Environment environment, BObject listener, BObject service, Object channelName) {
        listener.addNativeData(CHANNEL_NAME, ((BString) channelName).getValue());

        @SuppressWarnings("unchecked")
        ArrayList<BObject> services = (ArrayList<BObject>) listener.getNativeData(CONSUMER_SERVICES);
        @SuppressWarnings("unchecked")
        Map<BObject, DispatcherService> serviceDispatcherMap =
                (Map<BObject, DispatcherService>) listener.getNativeData(DISPATCHERS);

        if (service == null) {
            return null;
        }

        DispatcherService dispatcherService = new DispatcherService(service, environment.getRuntime());
        services.add(service);
        serviceDispatcherMap.put(service, dispatcherService);

        return null;
    }

    public static Object startListener(Environment env, BString username, BString password, BObject listener) {
        long readTimeoutMs = (Long) listener.getNativeData(READ_TIMEOUT);
        long keepAliveIntervalMs = (Long) listener.getNativeData(KEEP_ALIVE_INTERVAL);
        String apiVersion = (String) listener.getNativeData(API_VERSION);
        SslContextFactory sslContextFactory;
        try {
            sslContextFactory = buildSslContextFactory(listener);
        } catch (IllegalArgumentException e) {
            return sfdcError(e.getMessage(), e.getCause());
        }

        BearerTokenProvider tokenProvider = new BearerTokenProvider(() -> {
            try {
                return LoginHelper.login(username.getValue(), password.getValue(), listener, apiVersion,
                        sslContextFactory);
            } catch (Exception e) {
                throw sfdcError(e.getMessage(), e.getCause());
            }
        });

        BayeuxParameters params;
        try {
            BayeuxParameters loginParams = tokenProvider.login();
            params = new TimeoutBayeuxParameters(loginParams, readTimeoutMs, keepAliveIntervalMs);
        } catch (Exception e) {
            throw sfdcError(e.getMessage(), e.getCause());
        }

        return startConnector(params, tokenProvider, listener);
    }

    public static Object startListener(Environment env, BObject listener) {
        String baseUrl = (String) listener.getNativeData(BASE_URL);
        long readTimeoutMs = (Long) listener.getNativeData(READ_TIMEOUT);
        long keepAliveIntervalMs = (Long) listener.getNativeData(KEEP_ALIVE_INTERVAL);
        String apiVersion = (String) listener.getNativeData(API_VERSION);
        SslContextFactory sslContextFactory;
        try {
            sslContextFactory = buildSslContextFactory(listener);
        } catch (IllegalArgumentException e) {
            return sfdcError(e.getMessage(), e.getCause());
        }

        BearerTokenProvider tokenProvider = new BearerTokenProvider(() ->
            new OAuth2BayeuxParameters(() -> getOAuth2Token(env, listener), baseUrl,
                readTimeoutMs, keepAliveIntervalMs, apiVersion, sslContextFactory));

        BayeuxParameters params;
        try {
            params = tokenProvider.login();
        } catch (Exception e) {
            throw sfdcError(e.getMessage(), e.getCause());
        }

        return startConnector(params, tokenProvider, listener);
    }

    private static Object startConnector(BayeuxParameters params, BearerTokenProvider tokenProvider,
            BObject listener) {
        long connectionTimeoutMs = (Long) listener.getNativeData(CONNECTION_TIMEOUT);
        String connectionTimeoutDisplay = (String) listener.getNativeData(CONNECTION_TIMEOUT + "_display");

        connector = new EmpConnector(params);
        connector.setBearerTokenProvider(tokenProvider);
        try {
            connector.start().get(connectionTimeoutMs, TimeUnit.MILLISECONDS);
        } catch (TimeoutException exception) {
            connector.stop();
            return sfdcError("Connection timed out after " + connectionTimeoutDisplay + " seconds.", null);
        } catch (Exception e) {
            return sfdcError(e.getMessage(), e.getCause());
        }

        return subscribeServices(listener, connectionTimeoutMs);
    }

    private static Object subscribeServices(BObject listener, long connectionTimeoutMs) {
        @SuppressWarnings("unchecked")
        ArrayList<BObject> services = (ArrayList<BObject>) listener.getNativeData(CONSUMER_SERVICES);
        @SuppressWarnings("unchecked")
        Map<BObject, DispatcherService> serviceDispatcherMap =
                (Map<BObject, DispatcherService>) listener.getNativeData(DISPATCHERS);

        for (BObject service : services) {
            Object channelNameObj = listener.getNativeData(CHANNEL_NAME);
            if (channelNameObj == null) {
                return sfdcError("Channel name is not set. Please attach a service before starting the listener.",
                        null);
            }
            String channelName = channelNameObj.toString();
            long replayFrom = (Integer) listener.getNativeData(REPLAY_FROM);

            DispatcherService dispatcherService = serviceDispatcherMap.get(service);
            if (dispatcherService == null) {
                return sfdcError("DispatcherService not found for service.", null);
            }

            Consumer<Map<String, Object>> consumer = event -> injectEvent(dispatcherService, event);

            try {
                subscription = connector.subscribe(channelName, replayFrom, consumer)
                        .get(connectionTimeoutMs, TimeUnit.MILLISECONDS);
            } catch (Exception e) {
                connector.stop();
                return sfdcError(e.getMessage(), e.getCause());
            }
        }
        return null;
    }

    public static Object detachService(BObject listener, BObject service) {
        String channel = listener.getNativeData(CHANNEL_NAME).toString();
        connector.unsubscribe(channel);
        @SuppressWarnings("unchecked")
        ArrayList<BObject> services = (ArrayList<BObject>) listener.getNativeData(CONSUMER_SERVICES);
        @SuppressWarnings("unchecked")
        Map<BObject, DispatcherService> serviceDispatcherMap =
                (Map<BObject, DispatcherService>) listener.getNativeData(DISPATCHERS);
        services.remove(service);
        serviceDispatcherMap.remove(service);
        return null;
    }

    public static Object stopListener() {
        if (subscription != null) {
            subscription.cancel();
        }
        if (connector != null) {
            connector.stop();
        }
        return null;
    }

    private static void injectEvent(DispatcherService dispatcherService, Map<String, Object> eventData) {
        dispatcherService.handleDispatch(eventData);
    }

    private static String getOAuth2Token(Environment env, BObject listener) {
        Object result = env.getRuntime().callMethod(listener, GET_OAUTH2_TOKEN_METHOD, null);
        if (TypeUtils.getType(result).getTag() == TypeTags.ERROR_TAG) {
            throw sfdcError(((BError) result).getMessage(), ((BError) result).getCause());
        }
        return ((BString) result).getValue();
    }

    private static BError sfdcError(String errorMessage, Throwable cause) {
        String message = errorMessage != null ? errorMessage : "Unknown error";
        return (cause != null)
                ? ErrorCreator.createError(StringUtils.fromString(message), cause)
                : ErrorCreator.createError(StringUtils.fromString(message));
    }
}
