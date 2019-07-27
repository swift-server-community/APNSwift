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

public struct APNSwiftBearerToken {
    let configuration: APNSwiftConfiguration
    let timeout: TimeInterval
    var createdAt: TimeInterval?
    private var cachedToken: String?
    
    public init(configuration: APNSwiftConfiguration, timeout: TimeInterval) {
        self.configuration = configuration
        self.timeout = timeout
    }
    
    public var token: String? {
        mutating get {
            let now = Date().timeIntervalSince1970
            guard let existingToken = cachedToken, let timeCreated = createdAt, (now - timeCreated) <= timeout else {
                cachedToken = try? createToken()
                createdAt = now
                return cachedToken
            }
            return existingToken
        }
    }
    
    private func createToken() throws -> String {
        let jwt = APNSwiftJWT(keyID: configuration.keyIdentifier, teamID: configuration.teamIdentifier, issueDate: Date(), expireDuration: timeout)
        var token: String
        let digestValues = try jwt.getDigest()
        var signature = try configuration.signer.sign(digest: digestValues.fixedDigest)
        guard let data = signature.readData(length: signature.readableBytes) else {
            throw APNSwiftError.SigningError.invalidSignatureData
        }
        token = digestValues.digest + "." + data.base64EncodedURLString()
        return token
    }
}
