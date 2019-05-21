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
import XCTest
@testable import NIOAPNSJWT

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
        let jwt = APNSJWT(keyID: keyID, teamID: teamID, issueDate: date, expireDuration: 10.0)
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
    static var allTests = [
        ("testJWTEncodingAndSign", testJWTEncoding),
    ]
}

