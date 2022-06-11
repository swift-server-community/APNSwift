//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2022-2020 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Crypto
import Foundation

internal final actor APNSSigner {

    internal init(
        privateKey: P256.Signing.PrivateKey, teamIdentifier: String, keyIdentifier: String
    ) {
        self.privateKey = privateKey
        self.teamIdentifier = teamIdentifier
        self.keyIdentifier = keyIdentifier
    }

    private let privateKey: P256.Signing.PrivateKey
    private let teamIdentifier: String
    private let keyIdentifier: String

    internal func sign() throws -> String {
        let head = #"{"alg":"ES256","kid":"\#(keyIdentifier)","typ":"JWT"}"#
        let header = Base64.encodeString(
            bytes: head.utf8, options: [.base64UrlAlphabet, .omitPaddingCharacter])
        let pay =
            "{\"iss\":\"\(teamIdentifier)\",\"iat\":\(Int(Date().timeIntervalSince1970.rounded())),\"kid\":\"\(keyIdentifier)\"}"
        let payload = Base64.encodeString(
            bytes: pay.utf8, options: [.base64UrlAlphabet, .omitPaddingCharacter])
        let signature = try self.privateKey.signature(for: Array("\(header).\(payload)".utf8))
        let sign = Base64.encodeString(
            bytes: signature.rawRepresentation,
            options: [.base64UrlAlphabet, .omitPaddingCharacter])
        return "\(header).\(payload).\(sign)"
    }
}
