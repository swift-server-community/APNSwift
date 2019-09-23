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

public class APNSwiftBearerToken {
    let configuration: APNSwiftConfiguration
    let timeout: TimeInterval
    var createdAt: TimeInterval?
    private var deadline: TimeAmount
    private var tokenCreatedAt: TimeAmount?
    private var cachedToken: String?
    
    public init(configuration: APNSwiftConfiguration, deadline: TimeAmount) {
        self.configuration = configuration
        self.deadline = deadline
        self.timeout = TimeInterval(deadline.nanoseconds / 1000000000)
    }
    convenience init(configuration: APNSwiftConfiguration, timeout: TimeInterval) {
        self.init(configuration: configuration, deadline: TimeAmount.seconds(Int64(timeout)))
    }
    
    public var token: String? {
        let now = TimeAmount.nanoseconds(Int64(NIODeadline.now().uptimeNanoseconds))
        guard let existingToken = cachedToken, let timeCreated = tokenCreatedAt, (now - timeCreated) >= deadline else {
            cachedToken = try? createToken()
            createdAt = Date().timeIntervalSince1970
            tokenCreatedAt = now
            return cachedToken
        }
        return existingToken
    }
    
    private func createToken() throws -> String {
        let jwt = APNSwiftJWT(keyID: configuration.keyIdentifier, teamID: configuration.teamIdentifier, issueDate: Date())
        let digestValues = try jwt.getDigest()
        var signature = try configuration.signer.sign(digest: digestValues.fixedDigest)
        guard let data = signature.readData(length: signature.readableBytes) else {
            throw APNSwiftError.SigningError.invalidSignatureData
        }
        return digestValues.digest + "." + data.base64EncodedURLString()
    }
}
