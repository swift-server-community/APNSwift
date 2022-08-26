[![sswg:incubating|94x20](https://img.shields.io/badge/sswg-incubating-yellow.svg)](https://github.com/swift-server/sswg/blob/master/process/incubation.md#sandbox-level)
[![Build](https://github.com/kylebrowning/APNSwift/workflows/test/badge.svg)](https://github.com/kylebrowning/APNSwift/actions)
[![Documentation](https://img.shields.io/badge/documentation-blueviolet.svg)](https://swiftpackageindex.com/swift-server-community/APNSwift/master/documentation/apnswift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fswift-server-community%2FAPNSwift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/swift-server-community/APNSwift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fswift-server-community%2FAPNSwift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/swift-server-community/APNSwift)

# APNSwift

A non-blocking Swift module for sending remote Apple Push Notification requests to [APNS](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server) built on http/2, SwiftNIO for use on server side swift platforms.

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
    .package(url: "https://github.com/swift-server-community/APNSwift.git", from: "5.0.0-alpha.4"),
]
```

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
    deadline: .distantFuture,
    logger: myLogger
)
```

## Logging
By default APNSwift has a no-op logger which will not log anything. However if you pass a logger in, you will see logs.

## Completely custom

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

/// or alittle safer but still raw
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


#### Original pitch and discussion on API

* Pitch discussion: [Swift Server Forums](https://forums.swift.org/t/apple-push-notification-service-implementation-pitch/20193)
* Proposal: [SSWG-0006](https://forums.swift.org/t/feedback-nioapns-nio-based-apple-push-notification-service/24393)
