// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/log;
import ballerina/time;
import ballerina/io;
import ballerina/lang.'string as strings;

isolated string csvContent = EMPTY_STRING;

# remove decimal places from a civil seconds value
# 
# + civilTime - a time:civil record
# + return - a time:civil record with decimal places removed
# 
isolated function removeDecimalPlaces(time:Civil civilTime) returns time:Civil {
    time:Civil result = civilTime;
    time:Seconds seconds= (result.second is ())? 0 : <time:Seconds>result.second;
    decimal floor = decimal:floor(seconds);
    result.second = floor;
    return result;
} 


# Convert ReadableByteChannel to string.
#
# + rbc - ReadableByteChannel
# + return - converted string
isolated function convertToString(io:ReadableByteChannel rbc) returns string|error {
    byte[] readContent;
    string textContent = EMPTY_STRING;
    while (true) {
        byte[]|io:Error result = rbc.read(1000);
        if result is io:EofError {
            break;
        } else if result is io:Error {
            string errMsg = "Error occurred while reading from Readable Byte Channel.";
            log:printError(errMsg, 'error = result);
            return error(errMsg, result);
        } else {
            readContent = result;
            string|error readContentStr = strings:fromBytes(readContent);
            if readContentStr is string {
                textContent = textContent + readContentStr;
            } else {
                string errMsg = "Error occurred while converting readContent byte array to string.";
                log:printError(errMsg, 'error = readContentStr);
                return error(errMsg, readContentStr);
            }
        }
    }
    return textContent;
}


# Convert string[][] to string.
#
# + stringCsvInput - Multi dimentional array of strings
# + return - converted string
isolated function convertStringListToString(string[][]|stream<string[], error?> stringCsvInput) returns string|error {
    lock {
        csvContent = EMPTY_STRING;
    }
    if stringCsvInput is string[][] {
        foreach var row in stringCsvInput {
            lock {
                csvContent += row.reduce(isolated function (string s, string t) returns string { 
                    return s.concat(",", t);
                }, EMPTY_STRING).substring(1) + NEW_LINE;
            }
        }
    } else {
        check stringCsvInput.forEach(isolated function(string[] row) {
            lock {
                csvContent += row.reduce(isolated function (string s, string t) returns string { 
                    return s.concat(",", t);
                }, EMPTY_STRING).substring(1) + NEW_LINE;

            }
        });
    }
    lock {
        return csvContent;
    }
}

isolated function convertStringToStringList(string content) returns string[][]|error {
    string[][] result = [];
    string[] lines = re `\n`.split(content);
    foreach string item in lines {
        string processedItem = re `"`.replaceAll(item, EMPTY_STRING);
        if item == "" {
            continue;
        }
        string[] row = re `,`.split(processedItem);
        result.push(row);
    }
    return result;
};
