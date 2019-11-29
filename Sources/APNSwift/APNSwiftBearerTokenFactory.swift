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
import NIO
internal final class APNSwiftBearerTokenFactory {
    var updateTask: RepeatedTask?
    let eventLoop: EventLoop
    var currentBearerToken: String
    var cancelled = false
    let configuration: APNSwiftConfiguration

    init(eventLoop: EventLoop, configuration: APNSwiftConfiguration) throws {
        self.eventLoop = eventLoop
        self.eventLoop.assertInEventLoop()
        self.configuration = configuration
        self.configuration.logger?.debug("Creating a new APNS token")
        self.currentBearerToken = try APNSwiftBearerTokenFactory.makeNewBearerToken(configuration: configuration)
        self.updateTask = eventLoop.scheduleRepeatedTask(initialDelay: .minutes(55), delay: .minutes(55)) { _ in
            self.configuration.logger?.debug("Creating a new APNS token because old one expired")
            self.currentBearerToken = try APNSwiftBearerTokenFactory.makeNewBearerToken(configuration: configuration)
        }
    }

    func cancel() {
        self.eventLoop.assertInEventLoop()
        self.cancelled = true
        self.updateTask?.cancel()
        self.updateTask = nil
        self.configuration.logger?.debug("Destroying APNS bearer token")
    }

    deinit {
        assert(self.cancelled, "APNSwiftBearerTokenFactory not closed on deinit. You must call APNSwiftBearerTokenFactory.close when you no longer need it to make sure the library can discard the resources")
    }
    static func makeNewBearerToken(configuration: APNSwiftConfiguration) throws -> String {
        let jwt = APNSwiftJWT(keyID: configuration.keyIdentifier, teamID: configuration.teamIdentifier, issueDate: Date())
        let digestValues = try jwt.getDigest()
        var signature = try configuration.signer.sign(digest: digestValues.fixedDigest)
        let data = signature.readData(length: signature.readableBytes)!
        return digestValues.digest + "." + data.base64EncodedURLString()
    }
}
