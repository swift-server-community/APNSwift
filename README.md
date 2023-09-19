[![sswg:incubating|94x20](https://img.shields.io/badge/sswg-incubating-yellow.svg)](https://github.com/swift-server/sswg/blob/master/process/incubation.md#sandbox-level)
[![Build](https://github.com/kylebrowning/APNSwift/workflows/test/badge.svg)](https://github.com/kylebrowning/APNSwift/actions)
[![Documentation](https://img.shields.io/badge/documentation-blueviolet.svg)](https://swiftpackageindex.com/swift-server-community/APNSwift/main/documentation/apnswift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fswift-server-community%2FAPNSwift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/swift-server-community/APNSwift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fswift-server-community%2FAPNSwift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/swift-server-community/APNSwift)
<h1> APNSwift</h1>

A non-blocking Swift module for sending remote Apple Push Notification requests to [APNS](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server) built on AsyncHttpClient.

- [Installation](#installation)
- [Foundations](#foundations)
- [Getting Started](#getting-started)
- [Sending a simple notification](#sending-a-simple-notification)
- [Sending Live Activity Update](#sending-live-activity-update)
- [Authentication](#authentication)
- [Logging](#logging)
    - [**Background Activity Logger**](#background-activity-logger)
    - [**Notification Send Logger**](#notification-send-logger)
- [Using the non semantic safe APIs](#using-the-non-semantic-safe-apis)
- [Server Example](#server-example)
- [iOS Examples](#ios-examples)
- [Original pitch and discussion on API](#original-pitch-and-discussion-on-api)

## Installation

To install `APNSwift`, just add the package as a dependency in your [**Package.swift**](https://github.com/apple/swift-package-manager/blob/master/Documentation/PackageDescriptionV4.md#dependencies).

```swift
dependencies: [
    .package(url: "https://github.com/swift-server-community/APNSwift.git", from: "5.0.0"),
]
```

## Foundations
`APNSwift` is built with a layered approach. It exposes three tiers of API's.
1. A [raw API](https://github.com/swift-server-community/APNSwift/blob/d60241fe2b6eb193331567a871697d3f4bdf70fb/Sources/APNSwift/APNSClient.swift#L254) that takes basic types such as `String`'s
2. A slightly more [semantically safe API](https://github.com/swift-server-community/APNSwift/blob/d60241fe2b6eb193331567a871697d3f4bdf70fb/Sources/APNSwift/APNSClient.swift#L183), which takes types, like [`APNSPriority`](https://github.com/swift-server-community/APNSwift/blob/main/Sources/APNSwift/APNSPriority.swift), [`APNSPushType`](https://github.com/swift-server-community/APNSwift/blob/main/Sources/APNSwift/APNSPushType.swift), [`APNSNotificationExpiration`](https://github.com/swift-server-community/APNSwift/blob/main/Sources/APNSwift/APNSNotificationExpiration.swift), etc.
3. The [safest API](https://github.com/swift-server-community/APNSwift/blob/d60241fe2b6eb193331567a871697d3f4bdf70fb/Sources/APNSwift/Alert/APNSClient%2BAlert.swift#L32) which takes fully semantic types such as [`APNSAlertNotification`](https://github.com/swift-server-community/APNSwift/blob/d60241fe2b6eb193331567a871697d3f4bdf70fb/Sources/APNSwift/Alert/APNSAlertNotification.swift#L177)

**We recommened using number 3, the semantically safest API to ensure your push notification is delivered correctly**. *This README assumes that you are using number 3.* However if you need more granular approach, or something doesn't exist in this library, please use 2 or 1. (Also please open an issue if we missed something so we can get a semantically correct version!)

## Getting Started
APNSwift aims to provide semantically correct structures to sending push notifications. You first need to setup a [`APNSClient`](https://github.com/swift-server-community/APNSwift/blob/main/Sources/APNSwift/APNSClient.swift). To do that youll need to know your authentication method 

```swift
let client = APNSClient(
    configuration: .init(
        authenticationMethod: .jwt(
            privateKey: try .init(pemRepresentation: privateKey),
            keyIdentifier: keyIdentifier,
            teamIdentifier: teamIdentifier
        ),
        environment: .sandbox
    ),
    eventLoopGroupProvider: .createNew,
    responseDecoder: JSONDecoder(),
    requestEncoder: JSONEncoder(),
    byteBufferAllocator: .init(),
    backgroundActivityLogger: logger
)
defer {
    client.shutdown { _ in
        logger.error("Failed to shutdown APNSClient")
    }
}
```

## Sending a simple notification
All notifications require a payload, but that payload can be empty. Payload just needs to conform to `Encodable`

```swift
struct Payload: Codable {}

try await client.sendAlertNotification(
    .init(
        alert: .init(
            title: .raw("Simple Alert"),
            subtitle: .raw("Subtitle"),
            body: .raw("Body"),
            launchImage: nil
        ),
        expiration: .immediately,
        priority: .immediately,
        topic: "com.app.bundle",
        payload: Payload()
    ),
    deviceToken: "device-token",
    deadline: .nanoseconds(Int64.max),
    logger: myLogger
)
```

## Sending Live Activity Update / End
It requires sending `ContentState` matching with the live activity configuration to successfully update activity state. `ContentState` needs to conform to `Encodable`

```swift
        try await client.sendLiveActivityNotification(
            .init(
                  expiration: .immediately,
                  priority: .immediately,
                  appID: "com.app.bundle",
                  contentState: ContentState,
                  event: .update,
                  timestamp: Int(Date().timeIntervalSince1970)
            ),
            activityPushToken: activityPushToken,
            deadline: .distantFuture
        )
```

```swift
        try await client.sendLiveActivityNotification(
            .init(
                  expiration: .immediately,
                  priority: .immediately,
                  appID: "com.app.bundle",
                  contentState: ContentState,
                  event: .end,
                  timestamp: Int(Date().timeIntervalSince1970),
                  dismissalDate: .dismissImmediately // Optional to alter default behaviour
            ),
            activityPushToken: activityPushToken,
            deadline: .distantFuture
        )
```
## Authentication
`APNSwift` provides two authentication methods. `jwt`, and `TLS`. 

**`jwt` is preferred and recommend by Apple** 
These can be configured when created your `APNSClientConfiguration`

*Notes: `jwt` requires an encrypted version of your .p8 file from Apple which comes in a `pem` format. If you're having trouble with your key being invalid please confirm it is a PEM file*
```
 openssl pkcs8 -nocrypt -in /path/to/my/key.p8 -out ~/Downloads/key.pem
 ```

## Logging
By default APNSwift has a no-op logger which will not log anything. However if you pass a logger in, you will see logs.

There are currently two kinds of loggers.
#### **Background Activity Logger**
This logger can be passed into the `APNSClient` and will log background things like connection pooling, auth token refreshes, etc. 

#### **Notification Send Logger**
This logger can be passed into any of the `send:` methods and will log everything related to a single send request. 

## Using the non semantic safe APIs

APNSwift provides the ability to send raw payloads. You can use `Data`, `ByteBuffer`, `DispatchData`, `Array`
Though this is to be used with caution. APNSwift cannot gurantee delivery if you do not have the correct payload.
For more information see: [Creating APN Payload](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html)

```swift
/// Extremely Raw,
try await client.send(
    payload: payload, 
    deviceToken: token, 
    pushType: "alert", deadline: .distantFuture
)

/// or a little safer but still raw
try await client.send(
    payload: payload, 
    deviceToken: token, 
    pushType: .alert, 
    expiration: .immediatly, 
    priority: .immediatly, 
    deadline: .distantFuture
)
```

## Server Example
Take a look at [Program.swift](https://github.com/swift-server-community/APNSwift/blob/main/Sources/APNSExample/Program.swift)

## iOS Examples

For an iOS example, open the example project within this repo. 

Once inside configure your App Bundle ID and assign your development team. Build and run the ExampleApp to iOS Simulator, grab your device token, and plug it in to server example above. Background the app and run Program.swift

## Original pitch and discussion on API

* Pitch discussion: [Swift Server Forums](https://forums.swift.org/t/apple-push-notification-service-implementation-pitch/20193)
* Proposal: [SSWG-0006](https://forums.swift.org/t/feedback-nioapns-nio-based-apple-push-notification-service/24393)
* 5.0 breaking changings: [Swift Server Forums]([Blog post here on breaking changing](https://forums.swift.org/t/apnswift-5-0-0-beta-release/60075/3))
