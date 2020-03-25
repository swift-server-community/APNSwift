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
import NIO

internal struct APNSwiftJWTPayload: JWTPayload {
    /// iss
    let teamID: String

    /// iat
    let issueDate: Int

    // kid
    let keyID: JWKIdentifier

    enum CodingKeys: String, CodingKey {
        case teamID = "iss"
        case issueDate = "iat"
        case keyID = "kid"
    }

    internal init(teamID: String, keyID: JWKIdentifier, issueDate: Date) {
        self.teamID = teamID
        self.keyID = keyID
        self.issueDate = Int(issueDate.timeIntervalSince1970.rounded())
    }

    func verify(using signer: JWTSigner) throws {
        // No verifications needed.
    }
}
