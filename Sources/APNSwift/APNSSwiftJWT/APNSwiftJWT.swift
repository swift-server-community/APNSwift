//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2020 the APNSwift project authors
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
import NIO

internal struct APNSwiftJWT: Codable {
    private struct Payload: Codable {
        /// iss
        public let teamID: String

        /// iat
        public let issueDate: Int

        enum CodingKeys: String, CodingKey {
            case teamID = "iss"
            case issueDate = "iat"
        }
    }

    private struct Header: Codable {
        /// alg
        let algorithm: String = "ES256"

        /// kid
        let keyID: String

        enum CodingKeys: String, CodingKey {
            case keyID = "kid"
            case algorithm = "alg"
        }
    }

    private let header: Header

    private let payload: Payload

    internal init(keyID: String, teamID: String, issueDate: Date) {
        header = Header(keyID: keyID)
        let iat = Int(issueDate.timeIntervalSince1970.rounded())
        payload = Payload(teamID: teamID, issueDate: iat)
    }

    /// Combine header and payload as digest for signing.
    private func digest() throws -> String {
        let headerString = try JSONEncoder().encode(header.self).base64EncodedURLString()
        let payloadString = try JSONEncoder().encode(payload.self).base64EncodedURLString()
        return "\(headerString).\(payloadString)"
    }

    /// Sign digest with SigningMode. Use the result in your request authorization header.
    internal func getDigest() throws -> (digest: String, fixedDigest: ByteBuffer) {
        let digest = try self.digest()
        guard let digestData = digest.data(using: .utf8) else {
            throw APNSwiftError.DigestError.cannotConvertToData
        }
        let hash = SHA256.hash(data: digestData)
        var buffer = ByteBufferAllocator().buffer(capacity: SHA256Digest.byteCount)
        buffer.writeBytes(hash)
        return (digest: digest, fixedDigest: buffer)
    }
}
