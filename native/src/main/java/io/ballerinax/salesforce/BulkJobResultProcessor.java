/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

import com.fasterxml.jackson.databind.ObjectMapper;
import com.opencsv.CSVReaderHeaderAware;
import com.opencsv.exceptions.CsvValidationException;
import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Future;
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.JsonUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.ValueUtils;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;

import java.io.IOException;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * This class holds the methods involved with data binding the bulk job result content.
 *
 * @since 8.0.3
 */
public class BulkJobResultProcessor {
    public static Object parseResultsToInputType(Environment env, BObject client, BString bulkJobId, Object maxRecords,
                                                 BTypedesc bTypedesc) {
        return invokeClientMethod(env, client, "processGetBulkJobResults", bTypedesc,
                bulkJobId, true, maxRecords, true);
    }

    private static String[] convertCsvToJsonStrings(String csvContent) throws IOException {
        List<String> jsonStrings = new ArrayList<>();
        ObjectMapper mapper = new ObjectMapper();

        try (StringReader reader = new StringReader(csvContent);
             CSVReaderHeaderAware csvReader = new CSVReaderHeaderAware(reader)) {

            Map<String, String> record;
            while ((record = csvReader.readMap()) != null) {
                String jsonString = mapper.writeValueAsString(record);
                jsonStrings.add(jsonString);
            }
        } catch (CsvValidationException e) {
            throw new RuntimeException(e);
        }

        return jsonStrings.toArray(new String[0]);
    }

    private static Object invokeClientMethod(Environment env, BObject client, String methodName, BTypedesc bTypedesc,
                                             Object... paramFeed) {
        Future balFuture = env.markAsync();
        env.getRuntime().invokeMethodAsync(client, methodName, null, null, new Callback() {
            @Override
            public void notifySuccess(Object result) {

                Object payload = createPayload((BString) result, bTypedesc.getDescribingType());
                balFuture.complete(payload);
            }

            @Override
            public void notifyFailure(BError bError) {
                balFuture.complete(bError);
            }
        }, null, PredefinedTypes.TYPE_STRING, paramFeed);
        return null;
    }

    private static Object createPayload(BString csvData, Type type) {
        if (type.getTag() != TypeTags.ARRAY_TAG) {
            return ErrorCreator.createError(StringUtils.fromString(
                    "Unsupported data type for data binding query results"));
        }

        try {
            String[] jsonStrings = convertCsvToJsonStrings(csvData.getValue());
            // Convert each row in records to BArray
            Object[] bArrayData = new Object[jsonStrings.length];
            for (int i = 0; i < jsonStrings.length; i++) {
                bArrayData[i] = createRecordValue(jsonStrings[i], ((ArrayType) type).getElementType());
            }
            return ValueCreator.createArrayValue(bArrayData, (ArrayType) type); // string[][]
        } catch (IOException e) {
            return ErrorCreator.createError(StringUtils.fromString(e.getMessage()));
        }
    }

    private static Object createRecordValue(String jsonString, Type type) {
        return ValueUtils.convert(JsonUtils.parse(jsonString), type);
    }
}
