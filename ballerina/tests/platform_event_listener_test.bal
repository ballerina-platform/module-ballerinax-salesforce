// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
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

import ballerina/lang.runtime;
import ballerina/os;
import ballerina/test;

configurable string platformEventApiName = os:getEnv("PLATFORM_EVENT_API_NAME");

isolated boolean isPlatformEventReceived = false;

@test:Config {
    groups: ["platform-events"]
}
function testPlatformEventListenerWithOAuth2() returns error? {
    lock {
        isPlatformEventReceived = false;
    }

    Listener peListener = check new ({
        auth: {
            clientId,
            clientSecret,
            refreshToken,
            refreshUrl
        },
        baseUrl
    });

    Service peService = service object {
        remote function onMessage(PlatformEventsMessage message) returns error? {
            lock {
                isPlatformEventReceived = true;
            }
        }
    };

    check peListener.attach(peService, platformEventApiName);
    check peListener.'start();
    runtime:registerListener(peListener);

    CreationResponse _ = check sfdc->create(platformEventApiName, {});
    runtime:sleep(10);

    lock {
        test:assertTrue(isPlatformEventReceived, "onMessage was not triggered after publishing a platform event");
    }
    check peListener.gracefulStop();
}

@test:Config {
    groups: ["platform-events"]
}
function testPlatformEventChannel() returns error? {
    Listener peListener = check new ({
        auth: {
            clientId,
            clientSecret,
            refreshToken,
            refreshUrl
        },
        baseUrl
    });

    Service peService = service object {
        remote function onMessage(PlatformEventsMessage message) returns error? {
        }
    };

    string rawName = platformEventApiName.startsWith("/event/")
        ? platformEventApiName.substring("/event/".length())
        : platformEventApiName;

    error? attachResult = peListener.attach(peService, rawName);
    test:assertEquals(attachResult, ());
}

@test:Config {
    groups: ["platform-events"]
}
function testPlatformEventChannelWithPrefixNotDuplicated() returns error? {
    Listener peListener = check new ({
        auth: {
            clientId,
            clientSecret,
            refreshToken,
            refreshUrl
        },
        baseUrl
    });

    Service peService = service object {
        remote function onMessage(PlatformEventsMessage message) returns error? {
        }
    };

    string rawName = platformEventApiName.startsWith("/event/")
        ? platformEventApiName.substring("/event/".length())
        : platformEventApiName;
    string channelWithPrefix = "/event/" + rawName;

    error? attachResult = peListener.attach(peService, channelWithPrefix);
    test:assertEquals(attachResult, ());
}

@test:Config {
    groups: ["platform-events"]
}
function testAmbiguousServiceTypeError() returns error? {
    Listener peListener = check new ({
        auth: {
            clientId,
            clientSecret,
            refreshToken,
            refreshUrl
        },
        baseUrl
    });

    Service ambiguousService = service object {
        remote function onMessage(PlatformEventsMessage message) returns error? {
        }

        remote function onCreate(EventData payload) returns error? {
        }

        remote function onUpdate(EventData payload) returns error? {
        }

        remote function onDelete(EventData payload) returns error? {
        }

        remote function onRestore(EventData payload) returns error? {
        }
    };

    error? attachResult = peListener.attach(ambiguousService, platformEventApiName);
    test:assertTrue(attachResult is error);
    if attachResult is error {
        test:assertTrue(attachResult.message().includes("Ambiguous service"));
    }
}

@test:Config {
    groups: ["platform-events"]
}
function testPlatformEventInvalidChannelName() returns error? {
    Listener peListener = check new ({
        auth: {
            clientId,
            clientSecret,
            refreshToken,
            refreshUrl
        },
        baseUrl
    });

    Service peService = service object {
        remote function onMessage(PlatformEventsMessage message) returns error? {
        }
    };

    error? attachResult = peListener.attach(peService, [platformEventApiName]);
    test:assertTrue(attachResult is error, "Passing a string[] as the channel name should return an error");
    if attachResult is error {
        test:assertEquals(attachResult.message(), string `Invalid channel name: '[${platformEventApiName}]'`);
    }
}

@test:Config {
    groups: ["unit"]
}
function testListenerInitWithEmptyBaseUrl() returns error? {
    Listener|error result = new ({
        auth: {
            clientId,
            clientSecret,
            refreshToken,
            refreshUrl
        },
        baseUrl: ""
    });
    test:assertTrue(result is error, "Expected an error when baseUrl is empty");
    if result is error {
        test:assertEquals(result.message(),
            "Invalid or missing authentication configuration. Please verify your Salesforce URL and credentials.");
    }
}

@test:Config {
    groups: ["unit"]
}
function testListenerInitWithWhitespaceBaseUrl() returns error? {
    Listener|error result = new ({
        auth: {
            clientId,
            clientSecret,
            refreshToken,
            refreshUrl
        },
        baseUrl: "   "
    });
    test:assertTrue(result is error, "Expected an error when baseUrl is whitespace-only");
    if result is error {
        test:assertEquals(result.message(),
            "Invalid or missing authentication configuration. Please verify your Salesforce URL and credentials.");
    }
}
