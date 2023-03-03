# ``APNSwift``
A non-blocking Swift package for sending remote Apple Push Notification requests to Apple's APNS.

## Installation

To install `APNSwift`, just add the package as a dependency in your [**Package.swift**](https://github.com/apple/swift-package-manager/blob/master/Documentation/PackageDescriptionV4.md#dependencies).

```swift
dependencies: [
    .package(url: "https://github.com/swift-server-community/APNSwift.git", from: "4.0.0"),
]
```
If youd like to give our bleeding edge release a try, which is what the Readme is expecting use `5.0.0-alpha.N`. If you need the old Readme, see [here](https://github.com/swift-server-community/APNSwift/tree/4.0.0)

```swift
dependencies: [
    .package(url: "https://github.com/swift-server-community/APNSwift.git", from: "5.0.0-alpha.5"),
]
```

## Foundations
`APNSwift` is built with a layered approach. It exposes three tiers of API's.
1. A [raw API](https://github.com/swift-server-community/APNSwift/blob/d60241fe2b6eb193331567a871697d3f4bdf70fb/Sources/APNSwift/APNSClient.swift#L254) that takes basic types such as `String`'s
2. A slightly more [semantically safe API](https://github.com/swift-server-community/APNSwift/blob/d60241fe2b6eb193331567a871697d3f4bdf70fb/Sources/APNSwift/APNSClient.swift#L183), which takes types, like [`APNSPriority`](https://github.com/swift-server-community/APNSwift/blob/main/Sources/APNSwift/APNSPriority.swift), [`APNSPushType`](https://github.com/swift-server-community/APNSwift/blob/main/Sources/APNSwift/APNSPushType.swift), [`APNSNotificationExpiration`](https://github.com/swift-server-community/APNSwift/blob/main/Sources/APNSwift/APNSNotificationExpiration.swift), etc.
3. The [safest API](https://github.com/swift-server-community/APNSwift/blob/d60241fe2b6eb193331567a871697d3f4bdf70fb/Sources/APNSwift/Alert/APNSClient%2BAlert.swift#L32) which takes fully semantic types such as [`APNSAlertNotification`](https://github.com/swift-server-community/APNSwift/blob/d60241fe2b6eb193331567a871697d3f4bdf70fb/Sources/APNSwift/Alert/APNSAlertNotification.swift#L177)

**We recommened using number 3, the semantically safest API to ensure your push notification is delivered correctly**. *This README assumes that you are using number 3.* However if you need more granular approach, or something doesn't exist in this library, please use 2 or 1. (Also please open an issue if we missed something so we can get a semantically correct version!)

## Getting Started
APNSwift aims to provide sementically correct structures to sending push notifications. You first need to setup a [`APNSClient`](https://github.com/swift-server-community/APNSwift/blob/main/Sources/APNSwift/APNSClient.swift). To do that youll need to know your authentication method 

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
Take a look at [Program.swift](https://github.com/swift-server-community/APNSwift/blob/main/Sources/APNSwiftExample/Program.swift)

## iOS Examples

For an iOS example, open the example project within this repo. 

Once inside configure your App Bundle ID and assign your development team. Build and run the ExampleApp to iOS Simulator, grab your device token, and plug it in to server example above. Background the app and run Program.swift

## Original pitch and discussion on API

* Pitch discussion: [Swift Server Forums](https://forums.swift.org/t/apple-push-notification-service-implementation-pitch/20193)
* Proposal: [SSWG-0006](https://forums.swift.org/t/feedback-nioapns-nio-based-apple-push-notification-service/24393)
