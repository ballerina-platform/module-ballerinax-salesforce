// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
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

import ballerina/url;
import ballerina/log;
# Returns the prepared URL.
#
# + paths - An array of paths prefixes
# + return - The prepared URL
public isolated function prepareUrl(string[] paths) returns string {
    string url = EMPTY_STRING;

    if paths.length() > 0 {
        foreach string path in paths {
            if !path.startsWith(FORWARD_SLASH) {
                url = url + FORWARD_SLASH;
            }
            url = url + path;
        }
    }
    return url;
}

# Returns the prepared URL with encoded query.
#
# + paths - An array of paths prefixes
# + queryParamNames - An array of query param names
# + queryParamValues - An array of query param values
# + return - The prepared URL with encoded query
public isolated function prepareQueryUrl(string[] paths, string[] queryParamNames, string[] queryParamValues) returns string {
    string url = prepareUrl(paths);

    url = url + QUESTION_MARK;
    boolean first = true;
    int i = 0;
    foreach string name in queryParamNames {
        string value = queryParamValues[i];
        string|url:Error encoded = url:encode(value, ENCODING_CHARSET);

        if encoded is string {
            if first {
                url = url + name + EQUAL_SIGN + encoded;
                first = false;
            } else {
                url = url + AMPERSAND + name + EQUAL_SIGN + encoded;
            }
        } else {
            log:printError("Unable to encode value: " + value, 'error = encoded);
            break;
        }
        i = i + 1;
    }
    return url;
}

public isolated function appendQueryParams(string[] fields) returns string {
    string appended = "?fields=";
    foreach string item in fields {
        appended = appended.concat(item.trim(), ",");
    }
    appended = appended.substring(0, appended.length() - 1);
    return appended;
}
