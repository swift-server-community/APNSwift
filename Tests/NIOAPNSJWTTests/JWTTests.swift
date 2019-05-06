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

    func testJWTEncodingAndSign() throws {
        let teamID = "8RX5AF8F6Z"
        let keyID = "9N8238KQ6Z"
        let date = Date()

        guard let pk = appleECP8PrivateKey.data(using: .utf8) else { XCTFail("Can't convert private key string to Data"); return}
        let signer = try SigningMode.data(data: pk)
        let jwt = JWT(keyID: keyID, teamID: teamID, issueDate: date, expireDuration: 10.0)
        let token = try jwt.sign(with: signer)

        let part = token.split(separator: ".")

        XCTAssertEqual(part.count, 3)

        let header = String(part[0])
        if let headerData = Data(base64EncodedURL: header),  let headerObj = try JSONSerialization.jsonObject(with: headerData, options: []) as? [String: Any] {
            XCTAssertEqual(headerObj["kid"] as? String, keyID)
            XCTAssertEqual(headerObj["alg"] as? String, "ES256")
        } else {
            XCTFail("Header can't be decoded")
        }

        let payload = String(part[1])
        if let payloadData = Data(base64EncodedURL: payload),  let payloadObj = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] {
            XCTAssertEqual(payloadObj["iss"] as? String, teamID)
            XCTAssertEqual(payloadObj["iat"] as? Int, Int(date.timeIntervalSince1970.rounded()))
        } else {
            XCTFail("Payload can't be decoded")
        }
    }


    static var allTests = [
        ("testJWTEncodingAndSign", testJWTEncodingAndSign),
    ]

    let appleECP8PrivateKey = """
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg2sD+kukkA8GZUpmm
jRa4fJ9Xa/JnIG4Hpi7tNO66+OGgCgYIKoZIzj0DAQehRANCAATZp0yt0btpR9kf
ntp4oUUzTV0+eTELXxJxFvhnqmgwGAm1iVW132XLrdRG/ntlbQ1yzUuJkHtYBNve
y+77Vzsd
-----END PRIVATE KEY-----
"""
    let appleECP8PublicKey = """
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE2adMrdG7aUfZH57aeKFFM01dPnkx
C18ScRb4Z6poMBgJtYlVtd9ly63URv57ZW0Ncs1LiZB7WATb3svu+1c7HQ==
-----END PUBLIC KEY-----
"""
}

