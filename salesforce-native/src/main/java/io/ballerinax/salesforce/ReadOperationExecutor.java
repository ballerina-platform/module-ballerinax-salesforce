package io.ballerinax.salesforce;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Future;
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;

public class ReadOperationExecutor {

    public static Object getRecord(Environment env, BObject client, BString path, BTypedesc targetType) {
        return invokeClientMethod(env, client, path, targetType,
                "processGetRecord");
    }

    public static Object getRecordById(Environment env, BObject client, BString sobject, BString id, BArray fields, BTypedesc targetType) {
        return invokeClientMethodForId(env, client, sobject, id, fields, targetType,
                "processGetRecordById");
    }

    public static Object getRecordByExtId(Environment env, BObject client, BString sobject, BString extIdField, BString extId, BArray fields, BTypedesc targetType) {
        return invokeClientMethodForExtId(env, client, sobject, extIdField, extId, fields, targetType,
                "processGetRecordByExtId");
    }

    public static Object getQueryResult(Environment env, BObject client, BString receivedQuery, BTypedesc targetType) {
        return invokeClientMethodForQuery(env, client, receivedQuery, targetType,
                "processGetQueryResult");
    }

    public static Object searchSOSLString(Environment env, BObject client, BString searchString, BTypedesc targetType) {
        return invokeClientMethodForQuery(env, client, searchString, targetType,
                "processSearchSOSLString");
    }

    private static Object invokeClientMethod(Environment env, BObject client, BString path, BTypedesc targetType,
                                             String methodName) {
        Object[] paramFeed = new Object[10];
        paramFeed[0] = targetType;
        paramFeed[1] = true;
        paramFeed[2] = path;
        paramFeed[3] = true;
        return invokeClientMethod(env, client, methodName, paramFeed);
    }
    private static Object invokeClientMethodForId(Environment env, BObject client, BString sobject, BString id, BArray fields, BTypedesc targetType,
                                                  String methodName) {
        Object[] paramFeed = new Object[10];
        paramFeed[0] = targetType;
        paramFeed[1] = true;
        paramFeed[2] = sobject;
        paramFeed[3] = true;
        paramFeed[4] = id;
        paramFeed[5] = true;
        paramFeed[6] = fields;
        paramFeed[7] = true;
        return invokeClientMethod(env, client, methodName, paramFeed);
    }

    private static Object invokeClientMethodForExtId(Environment env, BObject client, BString sobject, BString extIdField, BString extId, BArray fields, BTypedesc targetType,
                                                  String methodName) {
        Object[] paramFeed = new Object[10];
        paramFeed[0] = targetType;
        paramFeed[1] = true;
        paramFeed[2] = sobject;
        paramFeed[3] = true;
        paramFeed[4] = extIdField;
        paramFeed[5] = true;
        paramFeed[8] = extId;
        paramFeed[9] = true;
        paramFeed[6] = fields;
        paramFeed[7] = true;
        return invokeClientMethod(env, client, methodName, paramFeed);
    }

    private static Object invokeClientMethodForQuery(Environment env, BObject client, BString receivedQuery, BTypedesc targetType,
                                                  String methodName) {
        Object[] paramFeed = new Object[10];
        paramFeed[0] = targetType;
        paramFeed[1] = true;
        paramFeed[2] = receivedQuery;
        paramFeed[3] = true;
        return invokeClientMethod(env, client, methodName, paramFeed);
    }

    private static Object invokeClientMethod(Environment env, BObject client, String methodName, Object[] paramFeed) {
        Future balFuture = env.markAsync();

        if (client.getType().isIsolated() && client.getType().isIsolated(methodName)) {
            env.getRuntime().invokeMethodAsyncConcurrently(client, methodName,
                    null, null, new Callback() {
                        @Override
                        public void notifySuccess(Object result) {
                            balFuture.complete(result);
                        }

                        @Override
                        public void notifyFailure(BError bError) {
                            balFuture.complete(bError);
                        }
                    }, null, PredefinedTypes.TYPE_NULL, paramFeed);
        } else {
            env.getRuntime().invokeMethodAsyncSequentially(client, methodName,
                    null, null, new Callback() {
                        @Override
                        public void notifySuccess(Object result) {
                            balFuture.complete(result);
                        }

                        @Override
                        public void notifyFailure(BError bError) {
                            balFuture.complete(bError);
                        }
                    }, null, PredefinedTypes.TYPE_NULL, paramFeed);
        }
        return null;
    }
}
