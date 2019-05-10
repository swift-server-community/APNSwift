[![License](https://img.shields.io/badge/License-Apache%202.0-yellow.svg)](https://www.apache.org/licenses/LICENSE-2.0.html)
[![Build](https://img.shields.io/circleci/project/github/kylebrowning/swift-nio-apns/master.svg?logo=circleci)](https://circleci.com/gh/kylebrowning/swift-nio-apns/tree/master)
[![Swift](https://img.shields.io/badge/Swift-5.0-brightgreen.svg?colorA=orange&colorB=4E4E4E)](https://swift.org)

# NIOApns

A non-blocking Swift module for sending remote Apple Push Notification requests to [APNS](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server) built on http/2, SwiftNIO for use on server side swift platforms.

* Pitch discussion: [Swift Server Forums](https://forums.swift.org/t/apple-push-notification-service-implementation-pitch/20193)
* Proposal: [SSWG-0005](https://forums.swift.org/t/discussion-nioapns-nio-based-apple-push-notification-service/23384)

## Installation

To install `NIOSAPNS`, just add the package as a dependency in your [**Package.swift**](https://github.com/apple/swift-package-manager/blob/master/Documentation/PackageDescriptionV4.md#dependencies)

```swift
dependencies: [
    .package(url: "https://github.com/kylebrowning/swift-nio-http2-apns.git", .upToNextMinor(from: "0.1.0")
]
```

## Getting Started

```swift
let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let apnsConfig = try APNSConfiguration(keyIdentifier: "9UC9ZLQ8YW",
                                   teamIdentifier: "ABBM6U9RM5",
                                   signingMode: .file(path: "/Users/kylebrowning/Downloads/AuthKey_9UC9ZLQ8YW.p8"),
                                   topic: "com.grasscove.Fern",
                                   environment: .sandbox)

let apns = try APNSConnection.connect(configuration: apnsConfig, on: group.next()).wait()
let alert = Alert(title: "Hey There", subtitle: "Full moon sighting", body: "There was a full moon last night did you see it")
let aps = APSPayload(alert: alert, badge: 1, sound: "cow.wav")
let notification = APNSNotification(aps: aps)
let res = try apns.send(notification, to: "de1d666223de85db0186f654852cc960551125ee841ca044fdf5ef6a4756a77e").wait()
try apns.close().wait()
try group.syncShutdownGracefully()
```


### APNSConfiguration

[`APNSConfiguration`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/NIOAPNS/APNSConfiguration.swift) is a structure that provides the system with common configuration.

```swift
public struct APNSConfiguration {
    public let keyIdentifier: String
    public let teamIdentifier: String
    public let signingMode: SigningMode
    public let topic: String
    public let environment: APNSEnvironment
    public let tlsConfiguration: TLSConfiguration

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
let apnsConfig = try APNSConfiguration(keyIdentifier: "9UC9ZLQ8YW",
                                   teamIdentifier: "ABBM6U9RM5",
                                   signingMode: .file(path: "/Users/kylebrowning/Downloads/AuthKey_9UC9ZLQ8YW.p8"),
                                   topic: "com.grasscove.Fern",
                                   environment: .sandbox)
```

### SigningMode

[`SigningMode`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/NIOAPNSJWT/SigningMode.swift) provides a method by which engineers can choose how their certificates are signed. Since security is important keeping we extracted this logic into three options. `file`, `data`, or `custom`.

```swift
public struct SigningMode {
    public let signer: APNSSigner
    init(signer: APNSSigner) {
        self.signer = signer
    }
}

extension SigningMode {
    public static func file(path: String) throws -> SigningMode {
        return .init(signer: try FileSigner(url: URL(fileURLWithPath: path)))
    }
    public static func data(data: Data) throws -> SigningMode {
        return .init(signer: try DataSigner(data: data))
    }
    public static func custom(signer: APNSSigner) -> SigningMode {
        return .init(signer: signer)
    }
}
```
#### Example Custom SigningMode that uses AWS for private keystorage
```swift
public class CustomSigner: APNSSigner {
   public func sign(digest: Data) throws -> Data {
     return try AWSKeyStore.sign(digest: digest)
   }
   public func verify(digest: Data, signature: Data) -> Bool {
      // verification
   }
}
let customSigner = CustomSigner()
let apnsConfig = APNSConfig(keyId: "9UC9ZLQ8YW",
                      teamId: "ABBM6U9RM5",
                      signingMode: .custom(signer: customSigner),
                      topic: "com.grasscove.Fern",
                      env: .sandbox)
```
### APNSConnection

[`APNSConnection`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/NIOAPNS/APNSConnection.swift) is a class with methods thats provides a wrapper to NIO's ClientBootstrap. The `swift-nio-http2` dependency is utilized here. It also provides a function to send a notification to a specific device token string.


#### Example `APNSConnection`
```swift
let apnsConfig = ...
let apns = try APNSConnection.connect(configuration: apnsConfig, on: group.next()).wait()
```

### Alert

[`Alert`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/NIOAPNS/APNSRequest.swift) is the actual meta data of the push notification alert someone wishes to send. More details on the specifcs of each property are provided [here](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). THey follow a 1-1 naming scheme listed in Apple's documentation


#### Example `Alert`
```swift
let alert = Alert(title: "Hey There", subtitle: "Full moon sighting", body: "There was a full moon last night did you see it")
```

### APSPayload

[`APSPayload`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/NIOAPNS/APNSRequest.swift) is the meta data of the push notification. Things like the alert, badge count. More details on the specifcs of each property are provided [here](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). THey follow a 1-1 naming scheme listed in Apple's documentation


#### Example `APSPayload`
```swift
let alert = ...
let aps = APSPayload(alert: alert, badge: 1, sound: "cow.wav")
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
