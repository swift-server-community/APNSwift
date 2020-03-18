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

import JWTKit
import Foundation
import Logging
import NIO

internal final class APNSwiftBearerTokenFactory {
    static func makeNewBearerToken(signers: JWTSigners, teamIdentifier: String) throws -> String {
        let payload = APNSwiftJWTPayload(
            // keyID: configuration.keyIdentifier,
            teamID: teamIdentifier,
            issueDate: Date()
        )
        return try signers.sign(payload)
    }

    var updateTask: RepeatedTask?
    let eventLoop: EventLoop
    var currentBearerToken: String?
    var cancelled: Bool
    var logger: Logger?

    init(eventLoop: EventLoop, signers: JWTSigners, teamIdentifier: String, logger: Logger?) {
        self.eventLoop = eventLoop
        self.eventLoop.assertInEventLoop()
        self.logger = logger
        logger?.debug("Creating a new APNS token")
        self.cancelled = false

        func generateToken() -> String? {
            do {
                return try APNSwiftBearerTokenFactory.makeNewBearerToken(
                    signers: signers,
                    teamIdentifier: teamIdentifier
                )
            } catch {
                logger?.error("Failed to generate token: \(error)")
                return nil
            }
        }

        self.currentBearerToken = generateToken()
        self.updateTask = eventLoop.scheduleRepeatedTask(initialDelay: .minutes(55), delay: .minutes(55)) { _ in
            logger?.debug("Creating a new APNS token because old one expired")
            self.currentBearerToken = generateToken()
        }
    }

    func cancel() {
        self.eventLoop.assertInEventLoop()
        self.cancelled = true
        self.updateTask?.cancel()
        self.updateTask = nil
        self.logger?.debug("Destroying APNS bearer token")
    }

    deinit {
        assert(self.cancelled, "APNSwiftBearerTokenFactory not closed on deinit. You must call APNSwiftBearerTokenFactory.close when you no longer need it to make sure the library can discard the resources")
    }
}
