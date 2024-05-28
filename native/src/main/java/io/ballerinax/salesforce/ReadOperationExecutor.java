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

import com.opencsv.CSVReader;
import com.opencsv.exceptions.CsvException;
import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Future;
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.ObjectType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.StreamType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BStream;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;

import java.io.IOException;
import java.io.StringReader;
import java.util.List;

import static io.ballerinax.salesforce.Utils.getMetadata;

/**
 * This class holds the utility methods involved with executing the read operations.
 *
 * @since 1.0.0
 */
public class ReadOperationExecutor {

    public static Object getRecord(Environment env, BObject client, BString path, BTypedesc targetType) {
        Object[] paramFeed = {targetType, true, path, true};
        return invokeClientMethod(env, client, "processGetRecord", paramFeed);
    }

    public static Object getInvocableActions(Environment env, BObject client, BString subContext,
                                             BTypedesc targetType) {
        Object[] paramFeed = {targetType, true, subContext, true};
        return invokeClientMethod(env, client, "processGetInvocableActions", paramFeed);
    }

    public static Object invokeActions(Environment env, BObject client, BString subContext, BMap<BString, ?> payload,
                                       BTypedesc targetType) {
        Object[] paramFeed = {targetType, true, subContext, true, payload, true};
        return invokeClientMethod(env, client, "processInvokeActions", paramFeed);
    }

    public static Object getRecordById(Environment env, BObject client, BString sobject, BString id,
                                       BTypedesc targetType) {
        RecordType recordType = (RecordType) targetType.getDescribingType();
        BArray fields = getMetadata(recordType);
        Object[] paramFeed = {targetType, true, sobject, true, id, true, fields, true};
        return invokeClientMethod(env, client, "processGetRecordById", paramFeed);
    }

    public static Object getNamedLayouts(Environment env, BObject client, BString sObject, BString name,
                                         BTypedesc targetType) {
        Object[] paramFeed = {targetType, true, sObject, true, name, true};
        return invokeClientMethod(env, client, "processGetNamedLayouts", paramFeed);
    }

    public static Object apexRestExecute(Environment env, BObject client, BString urlPath,
                                         BString methodType, BMap<BString, ?> payload,
                                         BTypedesc targetType) {
        Object[] paramFeed = {targetType, true, urlPath, true, methodType, true, payload, true};
        return invokeClientMethod(env, client, "processApexExecute", paramFeed);
    }

    public static Object getRecordByExtId(Environment env, BObject client, BString sObject, BString extIdField,
                                          BString extId, BTypedesc targetType) {
        RecordType recordType = (RecordType) targetType.getDescribingType();
        BArray fields = getMetadata(recordType);
        Object[] paramFeed = {targetType, true, sObject, true, extIdField, true, extId, true, fields, true};
        return invokeClientMethod(env, client, "processGetRecordByExtId", paramFeed);
    }

    public static Object getQueryResult(Environment env, BObject client, BString receivedQuery, BTypedesc targetType) {
        Object[] paramFeed = {targetType, true, receivedQuery, true};
        return invokeClientMethod(env, client, "processGetQueryResult", paramFeed);
    }

    public static Object searchSOSLString(Environment env, BObject client, BString searchString,
                                          BTypedesc targetType) {
        Object[] paramFeed = {targetType, true, searchString, true};
        return invokeClientMethod(env, client, "processSearchSOSLString", paramFeed);
    }

    private static Object invokeClientMethod(Environment env, BObject client, String methodName, Object[] paramFeed) {

        Future balFuture = env.markAsync();
        ObjectType objectType = (ObjectType) TypeUtils.getReferredType(TypeUtils.getType(client));
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

    public static Object parseCSVToStringArray(BString csvData) {
        try (CSVReader reader = new CSVReader(new StringReader(csvData.getValue()))) {
            List<String[]> records = reader.readAll();

            // Convert each row in records to BArray
            BArray[] bArrayData = new BArray[records.size()];
            for (int i = 0; i < records.size(); i++) {
                String[] row = records.get(i);
                BArray bArrayRow = StringUtils.fromStringArray(row);
                bArrayData[i] = bArrayRow;
            }
            BArray bArrayType = StringUtils.fromStringArray(new String[0]);
            ArrayType stringArrayType = TypeCreator.createArrayType(bArrayType.getType());
            return ValueCreator.createArrayValue(bArrayData, stringArrayType); // string[][]
        } catch (IOException | CsvException e) {
            return ErrorCreator.createError(StringUtils.fromString(e.getMessage()));
        }
    }
}
