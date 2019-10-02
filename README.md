[![sswg:sandbox|94x20](https://img.shields.io/badge/sswg-sandbox-lightgrey.svg)](https://github.com/swift-server/sswg/blob/master/process/incubation.md#sandbox-level)
[![License](https://img.shields.io/badge/License-Apache%202.0-yellow.svg)](https://www.apache.org/licenses/LICENSE-2.0.html)
[![Build](https://img.shields.io/circleci/project/github/kylebrowning/APNSwift/master.svg?logo=circleci)](https://circleci.com/gh/kylebrowning/APNSwift/tree/master)
[![Swift](https://img.shields.io/badge/Swift-5.0-brightgreen.svg?colorA=orange&colorB=4E4E4E)](https://swift.org)

# APNSwift

A non-blocking Swift module for sending remote Apple Push Notification requests to [APNS](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server) built on http/2, SwiftNIO for use on server side swift platforms.

## Installation

To install `APNSwift`, just add the package as a dependency in your [**Package.swift**](https://github.com/apple/swift-package-manager/blob/master/Documentation/PackageDescriptionV4.md#dependencies).

```swift
dependencies: [
    .package(url: "https://github.com/kylebrowning/APNSwift.git", .upToNextMinor(from: "1.2.0"))
]
```

## Getting Started

```swift
let signer = try! APNSwiftSigner(filePath: "/Users/kylebrowning/Downloads/AuthKey_9UC9ZLQ8YW.p8")

let apnsConfig = APNSwiftConfiguration(keyIdentifier: "9UC9ZLQ8YW",
                                       teamIdentifier: "ABBM6U9RM5",
                                       signer: signer,
                                       topic: "com.grasscove.Fern",
                                       environment: .sandbox)

struct BasicNotification: APNSwiftNotification {
    var aps: APNSwiftPayload
}
let apns = try APNSwiftConnection.connect(configuration: apnsConfig, on: group.next()).wait()
let alert = APNSwiftPayload.APNSwiftAlert(title: "Hey There", subtitle: "Full moon sighting", body: "There was a full moon last night did you see it")
let aps = APNSwiftPayload(alert: alert, badge: 1, sound: .normal("cow.wav"))
let notification = BasicNotification(aps: aps)
let res = apns.send(notification, pushType: .alert, to: "de1d666223de85db0186f654852cc960551125ee841ca044fdf5ef6a4756a77e")
try apns.close().wait()
try group.syncShutdownGracefully()
exit(0)
```


### APNSwiftConfiguration

[`APNSwiftConfiguration`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/APNSwift/APNSwiftConfiguration.swift) is a structure that provides the system with common configuration.

```swift
public struct APNSwiftConfiguration {
    public var keyIdentifier: String
    public var teamIdentifier: String
    public var signer: APNSwiftSigner
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
#### Example `APNSwiftConfiguration`
```swift
let signer = ...
let apnsConfig = try APNSwiftConfiguration(keyIdentifier: "9UC9ZLQ8YW",
                                   teamIdentifier: "ABBM6U9RM5",
                                   signer: signer),
                                   topic: "com.grasscove.Fern",
                                   environment: .sandbox)
```

### Signer

[`APNSwiftSigner`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/APNSwift/APNSwiftSigner.swift) provides a structure to sign the payloads with. This should be loaded into memory at the configuration level. It requires the data to be in a ByteBuffer format.

```swift
let url = URL(fileURLWithPath: "/Users/kylebrowning/Downloads/AuthKey_9UC9ZLQ8YW.p8")
let data: Data
do {
    data = try Data(contentsOf: url)
} catch {
    throw APNSwiftError.SigningError.certificateFileDoesNotExist
}
var byteBuffer = ByteBufferAllocator().buffer(capacity: data.count)
byteBuffer.writeBytes(data)
let signer = try! APNSwiftSigner.init(buffer: byteBuffer)
```
### APNSwiftConnection

[`APNSwiftConnection`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/APNSwift/APNSwiftConnection.swift) is a class with methods thats provides a wrapper to NIO's ClientBootstrap. The `swift-nio-http2` dependency is utilized here. It also provides a function to send a notification to a specific device token string.


#### Example `APNSwiftConnection`
```swift
let apnsConfig = ...
let apns = try APNSwiftConnection.connect(configuration: apnsConfig, on: group.next()).wait()
```

### Alert

[`Alert`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/APNSwift/APNSRequest.swift) is the actual meta data of the push notification alert someone wishes to send. More details on the specifics of each property are provided [here](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). They follow a 1-1 naming scheme listed in Apple's documentation


#### Example `Alert`
```swift
let alert = Alert(title: "Hey There", subtitle: "Full moon sighting", body: "There was a full moon last night did you see it")
```

### APNSwiftPayload

[`APNSwiftPayload`](https://github.com/kylebrowning/swift-nio-http2-apns/blob/master/Sources/APNSwift/APNSRequest.swift) is the meta data of the push notification. Things like the alert, badge count. More details on the specifics of each property are provided [here](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html). They follow a 1-1 naming scheme listed in Apple's documentation


#### Example `APNSwiftPayload`
```swift
let alert = ...
let aps = APNSwiftPayload(alert: alert, badge: 1, sound: .normal("cow.wav"))
```

## Putting it all together

```swift
let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
var verbose = true

let signer = try! APNSwiftSigner(filePath: "/Users/kylebrowning/Desktop/AuthKey_9UC9ZLQ8YW.p8")

let apnsConfig = APNSwiftConfiguration(keyIdentifier: "9UC9ZLQ8YW",
                                       teamIdentifier: "ABBM6U9RM5",
                                       signer: signer,
                                       topic: "com.grasscove.Fern",
                                       environment: .sandbox)

let apns = try APNSwiftConnection.connect(configuration: apnsConfig, on: group.next()).wait()

if verbose {
    print("* Connected to \(apnsConfig.url.host!) (\(apns.channel.remoteAddress!)")
}

struct AcmeNotification: APNSwiftNotification {
    let acme2: [String]
    let aps: APNSwiftPayload

    init(acme2: [String], aps: APNSwiftPayload) {
        self.acme2 = acme2
        self.aps = aps
    }
}

let alert = APNSwiftPayload.APNSwiftAlert(title: "Hey There", subtitle: "Subtitle", body: "Body")
let apsSound = APNSwiftPayload.APNSSoundDictionary(isCritical: true, name: "cow.wav", volume: 0.8)
let aps = APNSwiftPayload(alert: alert, badge: 0, sound: .critical(apsSound), hasContentAvailable: true)
let temp = try! JSONEncoder().encode(aps)
let string = String(bytes: temp, encoding: .utf8)
let notification = AcmeNotification(acme2: ["bang", "whiz"], aps: aps)

do {
    let expiry = Date().addingTimeInterval(5)
    for _ in 1...5 {
        try apns.send(notification, pushType: .alert, to: "98AAD4A2398DDC58595F02FA307DF9A15C18B6111D1B806949549085A8E6A55D", expiration: expiry, priority: 10).wait()
        try apns.send(notification, pushType: .alert, to: "98AAD4A2398DDC58595F02FA307DF9A15C18B6111D1B806949549085A8E6A55D", expiration: expiry, priority: 10).wait()
        try apns.send(notification, pushType: .alert, to: "98AAD4A2398DDC58595F02FA307DF9A15C18B6111D1B806949549085A8E6A55D", expiration: expiry, priority: 10).wait()
        try apns.send(notification, pushType: .alert, to: "98AAD4A2398DDC58595F02FA307DF9A15C18B6111D1B806949549085A8E6A55D", expiration: expiry, priority: 10).wait()
    }
} catch {
    print(error)
}

try apns.close().wait()
try group.syncShutdownGracefully()
exit(0)
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

let apns: APNSwiftConnection: = ...
let aps: APNSwiftPayload = ...
let notification = AcmeNotification(acme2: ["bang", "whiz"], aps: aps)
let res = try apns.send(notification, to: "de1d666223de85db0186f654852cc960551125ee841ca044fdf5ef6a4756a77e").wait()
```

### Using PEM instead of P8
```swift
var apnsConfig = try APNSwiftConfiguration(keyIdentifier: "9UC9ZLQ8YW",
                                       teamIdentifier: "ABBM6U9RM5",
                                       signer: APNSwiftSigner.init(buffer: ByteBufferAllocator().buffer(capacity: Data().count)),
                                       topic: "com.grasscove.Fern",
                                       environment: .sandbox)

let key = try NIOSSLPrivateKey(file: "/Users/kylebrowning/Projects/swift/Fern/development_com.grasscove.Fern.pkey", format: .pem)
apnsConfig.tlsConfiguration.privateKey = NIOSSLPrivateKeySource.privateKey(key)
apnsConfig.tlsConfiguration.certificateVerification = .noHostnameVerification
apnsConfig.tlsConfiguration.certificateChain = try! [.certificate(.init(file: "/Users/kylebrowning/Projects/swift/Fern/development_com.grasscove.Fern.pem", format: .pem))]
```
### Need a completely custom arbtirary payload and dont like being typecast?
APNSwift provides the ability to send rawBytes `ByteBuffer` as a payload.
This is to be used with caution. APNSwift cannot gurantee delivery if you do not have the correct payload.
For more information see: [Creating APN Payload](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html)
```swift
let notificationJsonPayload = ...
let data: Data = try! encoder.encode(notificationJsonPayload)
var buffer = ByteBufferAllocator().buffer(capacity: data.count)
buffer.writeBytes(data)
try apns.send(rawBytes: buffer, pushType: .alert, to: "<DEVICETOKEN>")
```

#### Original pitch and discussion on API

* Pitch discussion: [Swift Server Forums](https://forums.swift.org/t/apple-push-notification-service-implementation-pitch/20193)
* Proposal: [SSWG-0006](https://forums.swift.org/t/feedback-nioapns-nio-based-apple-push-notification-service/24393)
