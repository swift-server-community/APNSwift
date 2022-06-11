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

import Crypto
import Logging
import NIOCore

internal final actor APNSBearerTokenFactory {

    private var cachedBearerToken: String?

    internal func getCurrentBearerToken() async throws -> String {

        guard !isTokenStale, let cachedBearerToken = cachedBearerToken else {
            tokenCreated = NIODeadline.now()
            let newToken = try await makeNewBearerToken()
            cachedBearerToken = newToken
            return newToken
        }

        logger?.debug("APNS cached token \(cachedBearerToken.prefix(8))...")
        return cachedBearerToken
    }

    private var isTokenStale: Bool {
        NIODeadline.now() - tokenCreated > TimeAmount.minutes(55)
    }

    private let signer: APNSSigner
    private let logger: Logger?
    private var tokenCreated: NIODeadline = NIODeadline.now()

    internal init(
        authenticationConfig: APNSConfiguration.Authentication,
        logger: Logger? = nil
    ) {
        self.signer = APNSSigner(
            privateKey: authenticationConfig.privateKey,
            teamIdentifier: authenticationConfig.teamIdentifier,
            keyIdentifier: authenticationConfig.keyIdentifier
        )
        self.logger = logger
    }

    private func makeNewBearerToken() async throws -> String {
        let newToken = try await signer.sign()
        logger?.debug("APNS new token \(newToken.prefix(8))...")
        return newToken
    }

}
