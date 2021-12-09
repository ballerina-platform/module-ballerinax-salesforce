// ************************************ Salesforce bulk client constants ***********************************************

# Constant field `BULK_API_VERSION`. Holds the value for the Salesforce Bulk API version.
const string BULK_API_VERSION = "48.0";

# Constant field `SERVICES`. Holds the value of "services".
const string SERVICES = "services";

# Constant field `ASYNC`. Holds the value of "async".
const string ASYNC = "async";

# Constant field `JOB`. Holds the value of "job".
const string JOB = "job";

# Constant field `BATCH`. Holds the value of "batch".
const string BATCH = "batch";

# Constant field `REQUEST`. Holds the value of "request".
const string REQUEST = "request";

# Constant field `RESULT`. Holds the value of "result".
const string RESULT = "result";

# Constant field `STATUS_CODE`. Header name for bulk API response .
const string STATUS_CODE = "STATUS_CODE";

# Constant field `TEXT_CSV`. Holds the value of "text/csv".
const TEXT_CSV = "text/csv";

# Constant field `APP_JSON`. Holds the value of "application/xml".
const string APP_JSON = "application/json";

# Constant field `APP_XML`. Holds the value of "application/xml".
const string APP_XML = "application/xml";

# Constant field `ENCODING_CHARSET`. Holds the value for the encoding charset.
const string ENCODING_CHARSET = "utf-8";

# Constant field `CONTENT_TYPE`. Holds the value of "Content-Type".
const string CONTENT_TYPE = "Content-Type";

# Holds the value of "X-SFDC-Session" which used as Authorization header name of bulk API.
const string X_SFDC_SESSION = "X-SFDC-Session";

# Holds the value of "InvalidSessionId" which used to identify Unauthorized 401 response.
const string INVALID_SESSION_ID = "InvalidSessionId";

# Constant field `EMPTY_STRING`. Holds the value of "".
const string EMPTY_STRING = "";

# Constant field `AMPERSAND`. Holds the value of "&".
const string AMPERSAND = "&";

# Constant field `COMMA`. Holds the value of ",".
const string COMMA = ",";

# Constant field `NEW_LINE`. Holds the value of "\n".
const string NEW_LINE = "\n";

# Constant field `FORWARD_SLASH`. Holds the value of "/".
const string FORWARD_SLASH = "/";

// Payloads

# Constant field `JSON_STATE_CLOSED_PAYLOAD`. Holds the value of JSON body which needs to close the job.
final json JSON_STATE_CLOSED_PAYLOAD = {state: "Closed"};
