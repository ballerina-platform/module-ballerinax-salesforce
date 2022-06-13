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
