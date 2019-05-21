[![License](https://img.shields.io/badge/License-Apache%202.0-yellow.svg)](https://www.apache.org/licenses/LICENSE-2.0.html)
[![Build](https://img.shields.io/circleci/project/github/kylebrowning/swift-nio-apns/master.svg?logo=circleci)](https://circleci.com/gh/kylebrowning/swift-nio-apns/tree/master)
[![Swift](https://img.shields.io/badge/Swift-5.0-brightgreen.svg?colorA=orange&colorB=4E4E4E)](https://swift.org)

# NIOApns

A non-blocking Swift module for sending remote Apple Push Notification requests to [APNS](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server) built on http/2, SwiftNIO for use on server side swift platforms.

* Pitch discussion: [Swift Server Forums](https://forums.swift.org/t/apple-push-notification-service-implementation-pitch/20193)
* Proposal: [SSWG-0006](https://forums.swift.org/t/feedback-nioapns-nio-based-apple-push-notification-service/24393)

## Installation

To install `NIOSAPNS`, just add the package as a dependency in your [**Package.swift**](https://github.com/apple/swift-package-manager/blob/master/Documentation/PackageDescriptionV4.md#dependencies). Though you may want to consider using master branch until approved by the SSWG.

```swift
dependencies: [
    .package(url: "https://github.com/kylebrowning/swift-nio-http2-apns.git", .upToNextMinor(from: "0.1.0")
]
```

## Getting Started

```swift
let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let url = URL(fileURLWithPath: "/Users/kylebrowning/Downloads/AuthKey_9UC9ZLQ8YW.p8")
let data: Data
do {
    data = try Data(contentsOf: url)
} catch {
    throw APNSError.SigningError.certificateFileDoesNotExist
}
var byteBuffer = ByteBufferAllocator().buffer(capacity: data.count)
byteBuffer.writeBytes(data)
let signer = try! APNSSigner.init(buffer: byteBuffer)

let apnsConfig = APNSConfiguration(keyIdentifier: "9UC9ZLQ8YW",
                                       teamIdentifier: "ABBM6U9RM5",
                                       signer: signer,
                                       topic: "com.grasscove.Fern",
                                       environment: .sandbox)

let apns = try APNSConnection.connect(configuration: apnsConfig, on: group.next()).wait()
let alert = Alert(title: "Hey There", subtitle: "Full moon sighting", body: "There was a full moon last night did you see it")
let aps = APSPayload(alert: alert, badge: 1, sound: .normal("cow.wav"))
let notification = APNSNotification(aps: aps)
let res = try apns.send(notification, to: "de1d666223de85db0186f654852cc960551125ee841ca044fdf5ef6a4756a77e").wait()
try apns.close().wait()
try group.syncShutdownGracefully()
```


### APNSConfiguration

[`APNSConfiguration`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/NIOAPNS/APNSConfiguration.swift) is a structure that provides the system with common configuration.

```swift
public struct APNSConfiguration {
    public var keyIdentifier: String
    public var teamIdentifier: String
    public var signer: APNSSigner
    public var topic: String
    public var environment: Environment
    public var tlsConfiguration: TLSConfiguration

    public var url: URL {
        switch environment {
        case .production:
            return URL(string: "https://api.push.apple.com")!
        case .sandbox:
            return URL(string: "https://api.development.push.apple.com")!
        }
    }
```
#### Example `APNSConfiguration`
```swift
let signer = ...
let apnsConfig = try APNSConfiguration(keyIdentifier: "9UC9ZLQ8YW",
                                   teamIdentifier: "ABBM6U9RM5",
                                   signer: signer),
                                   topic: "com.grasscove.Fern",
                                   environment: .sandbox)
```

### Signer

[`APNSSigner`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/NIOAPNS/APNSSigner.swift) provides a structure to sign the payloads with. This should be loaded into memory at the configuration level. It requires the data to be in a ByteBuffer format.

```swift
let url = URL(fileURLWithPath: "/Users/kylebrowning/Downloads/AuthKey_9UC9ZLQ8YW.p8")
let data: Data
do {
    data = try Data(contentsOf: url)
} catch {
    throw APNSError.SigningError.certificateFileDoesNotExist
}
var byteBuffer = ByteBufferAllocator().buffer(capacity: data.count)
byteBuffer.writeBytes(data)
let signer = try! APNSSigner.init(buffer: byteBuffer)
```
### APNSConnection

[`APNSConnection`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/NIOAPNS/APNSConnection.swift) is a class with methods thats provides a wrapper to NIO's ClientBootstrap. The `swift-nio-http2` dependency is utilized here. It also provides a function to send a notification to a specific device token string.


#### Example `APNSConnection`
```swift
let apnsConfig = ...
let apns = try APNSConnection.connect(configuration: apnsConfig, on: group.next()).wait()
```

### Alert

[`Alert`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/NIOAPNS/APNSRequest.swift) is the actual meta data of the push notification alert someone wishes to send. More details on the specifics of each property are provided [here](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). They follow a 1-1 naming scheme listed in Apple's documentation


#### Example `Alert`
```swift
let alert = Alert(title: "Hey There", subtitle: "Full moon sighting", body: "There was a full moon last night did you see it")
```

### APSPayload

[`APSPayload`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/NIOAPNS/APNSRequest.swift) is the meta data of the push notification. Things like the alert, badge count. More details on the specifics of each property are provided [here](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). They follow a 1-1 naming scheme listed in Apple's documentation


#### Example `APSPayload`
```swift
let alert = ...
let aps = APSPayload(alert: alert, badge: 1, sound: .normal("cow.wav"))
```

## Putting it all together

```swift
let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let url = URL(fileURLWithPath: "/Users/kylebrowning/Downloads/AuthKey_9UC9ZLQ8YW.p8")
let data: Data
do {
    data = try Data(contentsOf: url)
} catch {
    throw APNSError.SigningError.certificateFileDoesNotExist
}
var byteBuffer = ByteBufferAllocator().buffer(capacity: data.count)
byteBuffer.writeBytes(data)
let signer = try! APNSSigner.init(buffer: byteBuffer)

let apnsConfig = APNSConfiguration(keyIdentifier: "9UC9ZLQ8YW",
                                       teamIdentifier: "ABBM6U9RM5",
                                       signer: signer,
                                       topic: "com.grasscove.Fern",
                                       environment: .sandbox)

let apns = try APNSConnection.connect(configuration: apnsConfig, on: group.next()).wait()
let alert = Alert(title: "Hey There", subtitle: "Full moon sighting", body: "There was a full moon last night did you see it")
let aps = APSPayload(alert: alert, badge: 1, sound: .normal("cow.wav"))
let notification = BasicNotification(aps: aps)
let res = try apns.send(notification, to: "de1d666223de85db0186f654852cc960551125ee841ca044fdf5ef6a4756a77e").wait()
try apns.close().wait()
try group.syncShutdownGracefully()
```

### Custom Notification Data

Apple provides engineers with the ability to add custom payload data to each notification. In order to facilitate this we have the `APNSNotification`.

#### Example
```swift
struct AcmeNotification: APNSNotification {
    let acme2: [String]
    let aps: APSPayload

    init(acme2: [String], aps: APSPayload) {
        self.acme2 = acme2
        self.aps = aps
    }
}

let apns: APNSConnection: = ...
let aps: APSPayload = ...
let notification = AcmeNotification(acme2: ["bang", "whiz"], aps: aps)
let res = try apns.send(notification, to: "de1d666223de85db0186f654852cc960551125ee841ca044fdf5ef6a4756a77e").wait()
```

