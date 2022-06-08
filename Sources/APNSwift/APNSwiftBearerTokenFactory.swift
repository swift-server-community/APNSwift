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

public final class APNSwiftBearerTokenFactory {
    static func makeNewBearerToken(
        signers: JWTSigners,
        teamIdentifier: String,
        keyIdentifier: JWKIdentifier
    ) throws -> String {

        let payload = APNSwiftJWTPayload(
            teamID: teamIdentifier,
            keyID: keyIdentifier,
            issueDate: Date()
        )
        return try signers.sign(payload, kid: keyIdentifier)
    }

    var updateTask: Task<(), Error>?
    public var currentBearerToken: String?
    var cancelled: Bool
    var logger: Logger?

    init(
        signers: JWTSigners,
        teamIdentifier: String,
        keyIdentifier: String,
        logger: Logger?
    ) {
        self.logger = logger
        logger?.debug("Creating a new APNS token")
        self.cancelled = false

        @Sendable
        func generateToken() -> String? {
            do {
                return try APNSwiftBearerTokenFactory.makeNewBearerToken(
                    signers: signers,
                    teamIdentifier: teamIdentifier,
                    keyIdentifier: .init(string: keyIdentifier)
                )
            } catch {
                logger?.error("Failed to generate token: \(error)")
                return nil
            }
        }

        self.currentBearerToken = generateToken()
        self.updateTask = Task {
            try await Task.sleep(nanoseconds: 3_300_000_000_000)
            logger?.debug("Creating a new APNS token because old one expired")
            self.currentBearerToken = generateToken()
        }
    }

    func cancel() {
        self.cancelled = true
        self.updateTask?.cancel()
        self.updateTask = nil
        self.logger?.debug("Destroying APNS bearer token")
    }

    deinit {
        assert(self.cancelled, "APNSwiftBearerTokenFactory not closed on deinit. You must call APNSwiftBearerTokenFactory.close when you no longer need it to make sure the library can discard the resources")
    }
}
