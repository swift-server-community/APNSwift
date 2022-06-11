[![sswg:incubating|94x20](https://img.shields.io/badge/sswg-incubating-yellow.svg)](https://github.com/swift-server/sswg/blob/master/process/incubation.md#sandbox-level)
[![License](https://img.shields.io/badge/License-Apache%202.0-yellow.svg)](https://www.apache.org/licenses/LICENSE-2.0.html)
[![Build](https://github.com/kylebrowning/APNSwift/workflows/test/badge.svg)](https://github.com/kylebrowning/APNSwift/actions)
[![Swift](https://img.shields.io/badge/Swift-5.2-brightgreen.svg?colorA=orange&colorB=4E4E4E)](https://swift.org)

# APNSwift

A non-blocking Swift module for sending remote Apple Push Notification requests to [APNS](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server) built on http/2, SwiftNIO for use on server side swift platforms.

## Installation

To install `APNSwift`, just add the package as a dependency in your [**Package.swift**](https://github.com/apple/swift-package-manager/blob/master/Documentation/PackageDescriptionV4.md#dependencies).

```swift
dependencies: [
    .package(url: "https://github.com/swift-server-community/APNSwift.git", from: "5.0.0"),
]
```

## Getting Started

```swift
struct BasicNotification: APNSwiftNotification {
    let aps: APNSwiftPayload
}

var logger = Logger(label: "com.apnswift")
logger.logLevel = .debug

/// Create your `APNSwiftConfiguration.Authentication`

let authenticationConfig: APNSwiftConfiguration.Authentication = .init(
    privateKey: try .loadFrom(filePath: "/Users/kylebrowning/Documents/AuthKey_9UC9ZLQ8YW.p8"),
    teamIdentifier: "ABBM6U9RM5",
    keyIdentifier: "9UC9ZLQ8YW"
)

/// If you need to use an a secrets manager instead of read from disk, use
/// `loadfrom(string:)`

let apnsConfig = try APNSwiftConfiguration(
    authenticationConfig: authenticationConfig,
    topic: "com.grasscove.Fern",
    environment: .sandbox,
    logger: logger
)
let apns = APNSwiftClient(configuration: apnsConfig)

let aps = APNSwiftPayload(alert: .init(title: "Hey There", subtitle: "Subtitle", body: "Body"), hasContentAvailable: true)
let deviceToken = "myDeviceToken"
try await apns.send(notification, pushType: .alert, to: deviceToken)
try await httpClient.shutdown()
exit(0)
```

### APNSwiftConfiguration

[`APNSwiftConfiguration`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/APNSwift/APNSwiftConfiguration.swift) is a structure that provides the system with common configuration.

```swift
let apnsConfig = try APNSwiftConfiguration(
    authenticationConfig: authenticationConfig,
    topic: "com.grasscove.Fern",
    environment: .sandbox,
    logger: logger
)
```

#### APNSwiftConfiguration.Authentication
[`APNSwiftConfiguration.Authentication`](https://github.com/swift-server-community/APNSwift/blob/master/Sources/APNSwift/APNSwiftConfiguration.swift#L26) is a struct that provides authentication keys and metadata to the signer.


```swift
let authenticationConfig: APNSwiftConfiguration.Authentication = .init(
    privateKey: try .loadFrom(filePath: "/Users/kylebrowning/Documents/AuthKey_9UC9ZLQ8YW.p8"),
    teamIdentifier: "ABBM6U9RM5",
    keyIdentifier: "9UC9ZLQ8YW"
)
```

### APNSwiftClient

[`APNSwiftClient`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/APNSwift/APNSwiftClient.swift) provides functions to send a notification to a specific device token string.


#### Example `APNSwiftClient`
```swift
let apns = APNSwiftClient(configuration: apnsConfig)
```

### APNSwiftAlert

[`APNSwiftAlert`](https://github.com/kylebrowning/APNSwift/blob/tn-concise-naming/Sources/APNSwift/APNSwiftAlert.swift) is the actual meta data of the push notification alert someone wishes to send. More details on the specifics of each property are provided [here](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). They follow a 1-1 naming scheme listed in Apple's documentation


#### Example `APNSwiftAlert`
```swift
let alert = APNSwiftAlert(title: "Hey There", subtitle: "Full moon sighting", body: "There was a full moon last night did you see it")
```

### APNSwiftPayload

[`APNSwiftPayload`](https://github.com/kylebrowning/APNSwift/blob/tn-concise-naming/Sources/APNSwift/APNSwiftPayload.swift) is the meta data of the push notification. Things like the alert, badge count. More details on the specifics of each property are provided [here](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). They follow a 1-1 naming scheme listed in Apple's documentation


#### Example `APNSwiftPayload`
```swift
let alert = ...
let aps = APNSwiftPayload(alert: alert, badge: 1, sound: .normal("cow.wav"))
```

### Custom Notification Data

Apple provides engineers with the ability to add custom payload data to each notification. In order to facilitate this we have the `APNSwiftNotification`.

#### Example
```swift
struct AcmeNotification: APNSwiftNotification {
    let acme2: [String]
    let aps: APNSwiftPayload

    init(acme2: [String], aps: APNSwiftPayload) {
        self.acme2 = acme2
        self.aps = aps
    }
}

let apns: APNSwiftClient: = ...
let aps: APNSwiftPayload = ...
let notification = AcmeNotification(acme2: ["bang", "whiz"], aps: aps)
let res = try apns.send(notification, to: "de1d666223de85db0186f654852cc960551125ee841ca044fdf5ef6a4756a77e")
```

### Need a completely custom arbtirary payload and dont like being typecast?

APNSwift provides the ability to send raw payloads. You can use `Data`, `ByteBuffer`, `DispatchData`, `Array`
Though this is to be used with caution. APNSwift cannot gurantee delivery if you do not have the correct payload.
For more information see: [Creating APN Payload](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html)

```swift
let notificationJsonPayload = ...
let data: Data = try! encoder.encode(notificationJsonPayload)
try apns.send(raw: data, pushType: .alert, to: "<DEVICETOKEN>")
```

#### Original pitch and discussion on API

* Pitch discussion: [Swift Server Forums](https://forums.swift.org/t/apple-push-notification-service-implementation-pitch/20193)
* Proposal: [SSWG-0006](https://forums.swift.org/t/feedback-nioapns-nio-based-apple-push-notification-service/24393)
