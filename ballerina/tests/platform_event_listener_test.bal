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

const int INVALID_REPLAY_ID = -100;

isolated boolean isPlatformEventReceived = false;
isolated boolean onErrorCalledForOnMessage = false;
isolated string onErrorMessageForOnMessage = "";
isolated boolean onErrorCalledForSubscription = false;

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

    error? attachResult = peListener.attach(peService, []);
    test:assertTrue(attachResult is error, "Passing an empty path as the channel name should return an error");
    if attachResult is error {
        test:assertEquals(attachResult.message(), "Invalid channel name: '[]'");
    }
}

// Asserts the channel a listener got bound to by attaching it, then trying to
// attach a second, different channel and reading the coordination guard error.
isolated function assertBoundChannel(Service s, string[]|string name, string expectedChannel) returns error? {
    Listener lis = check new ({
        auth: {token: "test-bearer-token"},
        baseUrl: "https://example.my.salesforce.com"
    });
    check lis.attach(s, name);
    error? result = lis.attach(s, "/data/SomeOtherChannel__ChangeEvent");
    if result is () {
        return error("Expected the coordination guard to reject a second channel");
    }
    test:assertTrue(result.message().includes(string `already bound to channel '${expectedChannel}'`),
            result.message());
}

@test:Config {
    groups: ["unit"]
}
function testCdcChannelFromUnquotedServicePath() returns error? {
    Service cdcService = service object {
        remote function onCreate(EventData payload) returns error? {
        }

        remote function onUpdate(EventData payload) returns error? {
        }

        remote function onDelete(EventData payload) returns error? {
        }

        remote function onRestore(EventData payload) returns error? {
        }
    };
    check assertBoundChannel(cdcService, ["data", "ChangeEvents"], "/data/ChangeEvents");
    check assertBoundChannel(cdcService, ["ChangeEvents"], "/data/ChangeEvents");
    check assertBoundChannel(cdcService, "/data/ChangeEvents", "/data/ChangeEvents");
    check assertBoundChannel(cdcService, "ChangeEvents", "/data/ChangeEvents");
}

@test:Config {
    groups: ["unit"]
}
function testPlatformEventChannelFromUnquotedServicePath() returns error? {
    check assertBoundChannel(makeNoopService(), ["event", "MyEvent__e"], "/event/MyEvent__e");
    check assertBoundChannel(makeNoopService(), ["MyEvent__e"], "/event/MyEvent__e");
    check assertBoundChannel(makeNoopService(), "/MyEvent__e", "/event/MyEvent__e");
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
            "Salesforce base URL cannot be empty. Please verify and provide a valid URL.");
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
            "Salesforce base URL cannot be empty. Please verify and provide a valid URL.");
    }
}

// Test: onError is invoked when onMessage returns an error
@test:Config {
    groups: ["platform-events"]
}
function testOnErrorInvokedWhenOnMessageFails() returns error? {
    lock { onErrorCalledForOnMessage = false; }
    lock { onErrorMessageForOnMessage = ""; }

    Listener peListener = check new ({
        auth: {clientId, clientSecret, refreshToken, refreshUrl},
        baseUrl,
        replayFrom: REPLAY_FROM_TIP
    });

    Service peService = service object {
        remote function onMessage(PlatformEventsMessage message) returns error? {
            return error("simulated-onMessage-failure");
        }

        remote function onError(error err) returns error? {
            lock { onErrorCalledForOnMessage = true; }
            lock { onErrorMessageForOnMessage = err.message(); }
        }
    };

    check peListener.attach(peService, platformEventApiName);
    check peListener.'start();
    runtime:registerListener(peListener);

    string eventSObjectName = platformEventApiName.startsWith("/event/")
        ? platformEventApiName.substring("/event/".length())
        : platformEventApiName;
    CreationResponse _ = check sfdc->create(eventSObjectName, {});
    runtime:sleep(10);

    lock {
        test:assertTrue(onErrorCalledForOnMessage,
            "onError was not invoked when onMessage returned an error");
    }
    lock {
        test:assertEquals(onErrorMessageForOnMessage, "simulated-onMessage-failure");
    }
    check peListener.gracefulStop();
}

// Test: subscription failure (stale replayId) invokes onError and returns error from start()
@test:Config {
    groups: ["platform-events"]
}
function testOnErrorInvokedOnSubscriptionFailure() returns error? {
    lock {
        onErrorCalledForSubscription = false;
    }

    Listener peListener = check new ({
        auth: {clientId, clientSecret, refreshToken, refreshUrl},
        baseUrl,
        replayFrom: INVALID_REPLAY_ID
    });

    Service peService = service object {
        remote function onMessage(PlatformEventsMessage message) returns error? {}

        remote function onError(error err) returns error? {
            lock {
                onErrorCalledForSubscription = true;
            }
        }
    };

    check peListener.attach(peService, platformEventApiName);
    error? startResult = peListener.'start();

    test:assertTrue(startResult is error,
        "Expected start() to return an error on stale replayId");
    lock {
        test:assertTrue(onErrorCalledForSubscription,
            "onError was not invoked on subscription failure");
    }
}

// Test: subscription failure without onError returns error from start() without panicking
@test:Config {
    groups: ["platform-events"]
}
function testSubscriptionFailureReturnedWithoutOnError() returns error? {
    Listener peListener = check new ({
        auth: {clientId, clientSecret, refreshToken, refreshUrl},
        baseUrl,
        replayFrom: INVALID_REPLAY_ID
    });

    Service peService = service object {
        remote function onMessage(PlatformEventsMessage message) returns error? {}
    };

    check peListener.attach(peService, platformEventApiName);
    error? startResult = peListener.'start();

    test:assertTrue(startResult is error,
        "Expected start() to return an error on stale replayId when no onError is defined");
}
