package io.ballerinax.salesforce;

import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.values.BArray;

import java.util.Map;

import static io.ballerina.runtime.api.utils.StringUtils.fromString;

public class Utils {
    private Utils() {}

    public static BArray getMetadata(RecordType recordType) {
        ArrayType stringArrayType = TypeCreator.createArrayType(PredefinedTypes.TYPE_STRING);

        //TODO: use PredefinedTypes.TYPE_TYPEDESC once NPE issue is resolved
        BArray fieldsArray = ValueCreator.createArrayValue(stringArrayType);

        Map<String, Field> fieldsMap = recordType.getFields();
        for (Field field : fieldsMap.values()) {
                fieldsArray.append(fromString(field.getFieldName()));
        }

        return fieldsArray;
    }
}
