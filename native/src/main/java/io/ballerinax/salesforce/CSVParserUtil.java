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

import com.opencsv.CSVReader;
import com.opencsv.exceptions.CsvException;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BString;

import java.io.IOException;
import java.io.StringReader;
import java.util.List;

/**
 * This class holds the utility methods involved with parsing csv content.
 *
 * @since 8.0.1
 */
public class CSVParserUtil {
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
