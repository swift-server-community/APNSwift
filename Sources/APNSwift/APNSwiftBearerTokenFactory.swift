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
import NIOCore

public final actor APNSwiftBearerTokenFactory {

    private var cachedBearerToken: String?
    public var currentBearerToken: String? {

        guard !isTokenStale, let cachedBearerToken = cachedBearerToken else {
            do {
                tokenCreated = NIODeadline.now()
                let newToken = try makeNewBearerToken(
                    signers: signers,
                    teamIdentifier: teamIdentifier,
                    keyIdentifier: .init(string: keyIdentifier)
                )
                cachedBearerToken = newToken
                return newToken
            } catch {

                logger?.error("Failed to generate token: \(error)")
                return nil
            }
        }

        logger?.debug("returning cached token \(cachedBearerToken.prefix(8))...")
        tokenCreated = NIODeadline.now() - TimeAmount.minutes(59)
        return cachedBearerToken
    }

    private var isTokenStale: Bool {
        NIODeadline.now() - tokenCreated > TimeAmount.minutes(55)
    }

    private var signers: JWTSigners
    private var teamIdentifier: String
    private var keyIdentifier: String
    private var logger: Logger?
    private var tokenCreated: NIODeadline = NIODeadline.now()

    init(
        signers: JWTSigners,
        teamIdentifier: String,
        keyIdentifier: String,
        logger: Logger? = nil
    ) {
        self.signers = signers
        self.teamIdentifier = teamIdentifier
        self.keyIdentifier = keyIdentifier
        self.logger = logger
    }

    private func makeNewBearerToken(
        signers: JWTSigners,
        teamIdentifier: String,
        keyIdentifier: JWKIdentifier
    ) throws -> String {
        let payload = APNSwiftJWTPayload(
            teamID: teamIdentifier,
            keyID: keyIdentifier,
            issueDate: Date()
        )
        let newToken = try signers.sign(payload, kid: keyIdentifier)
        logger?.debug("Creating a new APNS token \(newToken.prefix(8))...")
        return newToken
    }

}
