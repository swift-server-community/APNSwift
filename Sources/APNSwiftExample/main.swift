//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2019 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import APNSwift
import AsyncHTTPClient
import Foundation
import Logging
import NIO
import NIOHTTP1
import NIOHTTP2
import NIOSSL

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
var verbose = true

// optional
var logger = Logger(label: "com.apnswift")
logger.logLevel = .debug
let httpClient = HTTPClient(eventLoopGroupProvider: .shared(group))
let apnsConfig = try APNSwiftConfiguration(
    httpClient: httpClient,
    authenticationMethod: .jwt(
        key: .private(filePath: "/Users/kylebrowning/Documents/AuthKey_9UC9ZLQ8YW.p8"),
        keyIdentifier: "9UC9ZLQ8YW",
        teamIdentifier: "ABBM6U9RM5"
    ),
    topic: "com.grasscove.Fern",
    environment: .sandbox,
    logger: logger
)

let apnsProdConfig = try APNSwiftConfiguration(
    httpClient: httpClient,
    authenticationMethod: .jwt(
        key: .private(filePath: "/Users/kylebrowning/Documents/AuthKey_9UC9ZLQ8YW.p8"),
        keyIdentifier: "9UC9ZLQ8YW",
        teamIdentifier: "ABBM6U9RM5"
    ),
    topic: "com.grasscove.Fern",
    environment: .production,
    logger: logger
)


struct AcmeNotification: APNSwiftNotification {
    let acme2: [String]
    let aps: APNSwiftPayload

    init(acme2: [String], aps: APNSwiftPayload) {
        self.acme2 = acme2
        self.aps = aps
    }
}

let alert = APNSwiftAlert(title: "Hey There", subtitle: "Subtitle", body: "Body")
let apsSound = APNSSoundDictionary(isCritical: true, name: "cow.wav", volume: 0.8)
let aps = APNSwiftPayload(alert: alert, badge: 0, sound: .critical(apsSound), hasContentAvailable: true)
let temp = try! JSONEncoder().encode(aps)
let string = String(bytes: temp, encoding: .utf8)
let notification = AcmeNotification(acme2: ["bang", "whiz"], aps: aps)
let dt = "80745890ac499fa0c61c2348b56cdf735343963e085dd2283fb48a9fa56b0527759ed783ae6278f4f09aa3c4cc9d5b9f5ac845c3648e655183e2318404bc254ffcd1eea427ad528c3d0b253770422a80"
let apns = APNSwiftConnection(configuration: apnsConfig, logger: logger)
let apnsProd = APNSwiftConnection(configuration: apnsProdConfig, logger: logger)
let expiry = Date().addingTimeInterval(5)
do {
    try await apns.send(notification, pushType: .alert, to: dt, expiration: expiry, priority: 10)
    try await apns.send(notification, pushType: .alert, to: dt, expiration: expiry, priority: 10)
    try await apns.send(notification, pushType: .alert, to: dt, expiration: expiry, priority: 10)
    /// Overriden environment
    try await apnsProd.send(aps, to: dt, on: .sandbox)
} catch {
    print(error)
}

try await httpClient.shutdown()
try group.syncShutdownGracefully()
exit(0)
