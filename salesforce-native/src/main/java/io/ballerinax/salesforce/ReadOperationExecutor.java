/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerinax.salesforce;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Future;
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ObjectType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.StreamType;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BStream;
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
        Object[] paramFeed = new Object[4];
        paramFeed[0] = targetType;
        paramFeed[1] = true;
        paramFeed[2] = path;
        paramFeed[3] = true;
        return invokeClientMethod(env, client, methodName, paramFeed);
    }
    private static Object invokeClientMethodForId(Environment env, BObject client, BString sobject, BString id, BArray fields, BTypedesc targetType,
                                                  String methodName) {
        Object[] paramFeed = new Object[8];
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
        Object[] paramFeed = new Object[4];
        paramFeed[0] = targetType;
        paramFeed[1] = true;
        paramFeed[2] = receivedQuery;
        paramFeed[3] = true;
        return invokeClientMethod(env, client, methodName, paramFeed);
    }

    private static Object invokeClientMethod(Environment env, BObject client, String methodName, Object[] paramFeed) {
        Future balFuture = env.markAsync();
        ObjectType objectType = (ObjectType) TypeUtils.getReferredType(client.getType());
        if (objectType.isIsolated() && objectType.isIsolated(methodName)) {
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

    public static BStream streamConverter(Environment env, BObject client, BStream data, BTypedesc returnType) {
        RecordType recordType = (RecordType) returnType.getDescribingType();
        StreamType bStream = TypeCreator.createStreamType(recordType, PredefinedTypes.TYPE_NULL);
        return ValueCreator.createStreamValue(bStream, data.getIteratorObj());
    }
}
