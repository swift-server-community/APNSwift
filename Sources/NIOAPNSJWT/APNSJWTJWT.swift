//===----------------------------------------------------------------------===//
//
// This source file is part of the NIOApns open source project
//
// Copyright (c) 2019 the NIOApns project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of NIOApns project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import CAPNSOpenSSL

public struct APNSJWT: Codable {
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

    public init(keyID: String, teamID: String, issueDate: Date, expireDuration _: TimeInterval) {
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
    public func getDigest() throws -> (digest: String, fixedDigest: Data) {
        let digest = try self.digest()
        guard let digestAsData = digest.data(using: .utf8) else {
            throw APNSJWTError.encodingFailed
        }
        return (digest: digest, fixedDigest: sha256(message: digestAsData))
    }
    private func sha256(message: Data) -> Data {
        var context = SHA256_CTX()
        SHA256_Init(&context)

        var res = message.withUnsafeBytes { buffer in
            SHA256_Update(&context, buffer.baseAddress, buffer.count)
        }
        assert(res == 1, "SHA256_Update failed")

        var digest = Data(count: Int(SHA256_DIGEST_LENGTH))
        res = digest.withUnsafeMutableBytes { mptr in
            SHA256_Final(mptr.baseAddress?.assumingMemoryBound(to: UInt8.self), &context)
        }
        assert(res == 1, "SHA256_Final failed")

        return digest
    }

}
