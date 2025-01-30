/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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
import io.ballerina.runtime.api.concurrent.StrandMetadata;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.ObjectType;
import io.ballerina.runtime.api.types.PredefinedTypes;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.StreamType;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BStream;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;

import static io.ballerinax.salesforce.Utils.getMetadata;


/**
 * This class holds the utility methods involved with executing the read operations.
 *
 * @since 1.0.0
 */
public class ReadOperationExecutor {

    public static Object getRecord(Environment env, BObject client, BString path, BTypedesc targetType) {
        Object[] paramFeed = {targetType, path};
        return invokeClientMethod(env, client, "processGetRecord", paramFeed);
    }

    public static Object getInvocableActions(Environment env, BObject client, BString subContext,
                                             BTypedesc targetType) {
        Object[] paramFeed = {targetType, subContext};
        return invokeClientMethod(env, client, "processGetInvocableActions", paramFeed);
    }

    public static Object invokeActions(Environment env, BObject client, BString subContext, BMap<BString, ?> payload,
                                       BTypedesc targetType) {
        Object[] paramFeed = {targetType, subContext, payload};
        return invokeClientMethod(env, client, "processInvokeActions", paramFeed);
    }

    public static Object getRecordById(Environment env, BObject client, BString sobject, BString id,
                                       BTypedesc targetType) {
        RecordType recordType = (RecordType) targetType.getDescribingType();
        BArray fields = getMetadata(recordType);
        Object[] paramFeed = {targetType, sobject, id, fields};
        return invokeClientMethod(env, client, "processGetRecordById", paramFeed);
    }

    public static Object getNamedLayouts(Environment env, BObject client, BString sObject, BString name,
                                         BTypedesc targetType) {
        Object[] paramFeed = {targetType, sObject, name};
        return invokeClientMethod(env, client, "processGetNamedLayouts", paramFeed);
    }

    public static Object apexRestExecute(Environment env, BObject client, BString urlPath,
                                         BString methodType, BMap<BString, ?> payload,
                                         BTypedesc targetType) {
        Object[] paramFeed = {targetType, urlPath, methodType, payload};
        return invokeClientMethod(env, client, "processApexExecute", paramFeed);
    }

    public static Object getRecordByExtId(Environment env, BObject client, BString sObject, BString extIdField,
                                          BString extId, BTypedesc targetType) {
        RecordType recordType = (RecordType) targetType.getDescribingType();
        BArray fields = getMetadata(recordType);
        Object[] paramFeed = {targetType, sObject, extIdField, extId, fields};
        return invokeClientMethod(env, client, "processGetRecordByExtId", paramFeed);
    }

    public static Object getQueryResult(Environment env, BObject client, BString receivedQuery, BTypedesc targetType) {
        ArrayType bArrayType = TypeCreator.createArrayType(targetType.getDescribingType());
        BTypedesc typedesc = ValueCreator.createTypedescValue(bArrayType);
        Object[] paramFeed = {typedesc, receivedQuery};
        return invokeClientMethod(env, client, "processGetQueryResult", paramFeed);
    }

    public static Object searchSOSLString(Environment env, BObject client, BString searchString,
                                          BTypedesc targetType) {
        Object[] paramFeed = {targetType, searchString};
        return invokeClientMethod(env, client, "processSearchSOSLString", paramFeed);
    }

    private static Object invokeClientMethod(Environment env, BObject client, String methodName, Object[] paramFeed) {

        return env.yieldAndRun(() -> {
            ObjectType objectType = (ObjectType) TypeUtils.getReferredType(TypeUtils.getType(client));
            boolean isIsolated = objectType.isIsolated() && objectType.isIsolated(methodName);
            try {
                return env.getRuntime().callMethod(client, methodName, new StrandMetadata(isIsolated, null), paramFeed);
            } catch (BError bError) {
                return bError;
            }

        });
    }

    public static BStream streamConverter(Environment env, BObject client, BStream data, BTypedesc returnType) {

        RecordType recordType = (RecordType) returnType.getDescribingType();
        StreamType bStream = TypeCreator.createStreamType(recordType, PredefinedTypes.TYPE_NULL);
        return ValueCreator.createStreamValue(bStream, data.getIteratorObj());
    }


    public static BStream streamQueryConverter(Environment env, BObject client, BStream data, BTypedesc returnType) {
        ArrayType recordType = (ArrayType) returnType.getDescribingType();
        StreamType bStream = TypeCreator.createStreamType(recordType.getElementType(), PredefinedTypes.TYPE_NULL);
        return ValueCreator.createStreamValue(bStream, data.getIteratorObj());
    }
}
