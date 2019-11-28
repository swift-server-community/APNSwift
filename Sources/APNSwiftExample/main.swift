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

import Foundation
import Logging
import NIO
import APNSwift
import NIOHTTP1
import NIOHTTP2
import NIOSSL

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
var verbose = true

let signer = try! APNSwiftSigner(filePath: "/Users/kylebrowning/Desktop/AuthKey_9UC9ZLQ8YW.p8")

// optional
var logger = Logger(label: "com.apnswift")
logger.logLevel = .debug
let apnsConfig = APNSwiftConfiguration(keyIdentifier: "9UC9ZLQ8YW",
                                       teamIdentifier: "ABBM6U9RM5",
                                       signer: signer,
                                       topic: "com.grasscove.Fern",
                                       environment: .sandbox,
                                       logger: logger)


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
