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

public isolated function appendQueryParams(string[] fields) returns string {
    string appended = "?fields=";
    foreach string item in fields {
        appended = appended.concat(item.trim(), ",");
    }
    appended = appended.substring(0, appended.length() - 1);
    return appended;
}
