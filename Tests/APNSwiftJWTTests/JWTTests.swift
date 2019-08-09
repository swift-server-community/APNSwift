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
import XCTest
import NIO
@testable import APNSwift

final class JWTTests: XCTestCase {
    func createDecodedData(with string: String) -> Data? {
        let paddingLength = 4 - string.count % 4
        let padding = (paddingLength < 4) ? String(repeating: "=", count: paddingLength) : ""
        let base64EncodedString = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            + padding
        return Data(base64Encoded: base64EncodedString)
    }
    func testJWTEncoding() throws {
        let teamID = "8RX5AF8F6Z"
        let keyID = "9N8238KQ6Z"
        let date = Date()
        let jwt = APNSwiftJWT(keyID: keyID, teamID: teamID, issueDate: date, expireDuration: 10.0)
        let token = try jwt.getDigest()

        let part = token.digest.split(separator: ".")

        XCTAssertEqual(part.count, 2)

        let header = String(part[0])
        if let headerData = createDecodedData(with: header),  let headerObj = try JSONSerialization.jsonObject(with: headerData, options: []) as? [String: Any] {
            XCTAssertEqual(headerObj["kid"] as? String, keyID)
            XCTAssertEqual(headerObj["alg"] as? String, "ES256")
        } else {
            XCTFail("Header can't be decoded")
        }

        let payload = String(part[1])
        if let payloadData = createDecodedData(with: payload),  let payloadObj = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] {
            XCTAssertEqual(payloadObj["iss"] as? String, teamID)
            XCTAssertEqual(payloadObj["iat"] as? Int, Int(date.timeIntervalSince1970.rounded()))
        } else {
            XCTFail("Payload can't be decoded")
        }
    }
    
    func testJWTSigning() throws {
        let teamID = "8RX5AF8F6Z"
        let keyID = "9N8238KQ6Z"
        let date = Date()
        let jwt = APNSwiftJWT(keyID: keyID, teamID: teamID, issueDate: date, expireDuration: 10.0)
        
        let privateKey = """
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIEY5/amzr1QgHrLNZ8eHu926YERGWqB6QaDpNFcGxjsToAoGCCqGSM49
AwEHoUQDQgAEdbP7WQ/U4e5/CAqoBxatQb/5CEgJ070yMNGmWg5O6v2Q4M0l4CXK
cc94a66VttRZgVg6jE/ju+2mdHP7JWLmcQ==
-----END EC PRIVATE KEY-----
"""
        
        var buffer = ByteBufferAllocator().buffer(capacity: privateKey.count)
        buffer.writeString(privateKey)
        
        let signer = try APNSwiftSigner(buffer: buffer)
        let sig = try signer.sign(digest: try jwt.getDigest().fixedDigest)
        XCTAssertEqual(sig.readableBytes, 64) // len(r) + len(s) == 64 byte
    }
    
    static var allTests = [
        ("testJWTEncodingAndSign", testJWTEncoding),
        ("testJWTSigning", testJWTSigning),
    ]
}

