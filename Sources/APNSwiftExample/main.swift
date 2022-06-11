//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2022 the APNSwift project authors
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

/// optional
var logger = Logger(label: "com.apnswift")
logger.logLevel = .debug

let authenticationConfig: APNSConfiguration.Authentication = .init(
    privateKey: try .loadFrom(filePath: "/Users/kylebrowning/Documents/AuthKey_9UC9ZLQ8YW.p8"),
    teamIdentifier: "ABBM6U9RM5",
    keyIdentifier: "9UC9ZLQ8YW"
)

let apnsConfig = APNSConfiguration(
    authenticationConfig: authenticationConfig,
    topic: "com.grasscove.Fern",
    environment: .sandbox,
    eventLoopGroupProvider: .createNew,
    logger: logger
)

let apnsProdConfig = APNSConfiguration(
    authenticationConfig: authenticationConfig,
    topic: "com.grasscove.Fern",
    environment: .production,
    eventLoopGroupProvider: .createNew,
    logger: logger
)

struct AcmeNotification: APNSNotification {
    let acme2: [String]
    let aps: APNSPayload

    init(acme2: [String], aps: APNSPayload) {
        self.acme2 = acme2
        self.aps = aps
    }
}

let alert = APNSAlert(title: "Hey There", subtitle: "Subtitle", body: "Body")
let apsSound = APNSSoundDictionary(isCritical: true, name: "cow.wav", volume: 0.8)
let aps = APNSPayload(
    alert: alert, badge: 0, sound: .critical(apsSound), hasContentAvailable: true)

let notification = AcmeNotification(acme2: ["bang", "whiz"], aps: aps)

let dt =
    "80745890ac499fa0c61c2348b56cdf735343963e085dd2283fb48a9fa56b0527759ed783ae6278f4f09aa3c4cc9d5b9f5ac845c3648e655183e2318404bc254ffcd1eea427ad528c3d0b253770422a80"
let apns = APNSClient(configuration: apnsConfig)
let apnsProd = APNSClient(configuration: apnsProdConfig)
let expiry = Date().addingTimeInterval(5)
let dispatchGroup = DispatchGroup()
dispatchGroup.enter()
Task {
    do {
        try await apns.send(notification, pushType: .alert, to: dt)
        try await apns.send(
            notification, pushType: .alert, to: dt, expiration: expiry, priority: 10)
        try await apns.send(
            notification, pushType: .alert, to: dt, expiration: expiry, priority: 10)
        /// Overriden environment
        try await apnsProd.send(aps, to: dt, on: .sandbox)
        try await apns.shutdown()
        try await apnsProd.shutdown()
        dispatchGroup.leave()

    } catch {
        print(error)
        dispatchGroup.leave()
    }
}
let _ = dispatchGroup.wait(timeout: .now() + 5)
exit(0)
