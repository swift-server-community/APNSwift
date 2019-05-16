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

import XCTest
@testable import NIOAPNS
import NIOAPNSJWT

class APNSConfigurationTests: XCTestCase {

    func configuration(environment: APNSConfiguration.Environment) throws {
        guard let pk = appleECP8PrivateKey.data(using: .utf8) else { XCTFail("Can't convert private key string to Data"); return}
        let signer = APNSSigners.SigningMode.data(pk)

        let apnsConfiguration = APNSConfiguration(keyIdentifier: "MY_KEY_ID", teamIdentifier: "MY_TEAM_ID", signingMode: signer, topic: "MY_TOPIC", environment: environment)

        switch environment {
        case .production:
            XCTAssertEqual(apnsConfiguration.url, URL(string: "https://api.push.apple.com"))
        case .sandbox:
            XCTAssertEqual(apnsConfiguration.url, URL(string: "https://api.development.push.apple.com"))
        }

        XCTAssertEqual(apnsConfiguration.keyIdentifier, "MY_KEY_ID")
        XCTAssertEqual(apnsConfiguration.teamIdentifier, "MY_TEAM_ID")
        XCTAssertEqual(apnsConfiguration.topic, "MY_TOPIC")

    }

    func testSandboxConfiguration() throws {
       try configuration(environment: .sandbox)
    }

    func testProductionConfiguration() throws {
        try configuration(environment: .production)
    }
    func testSignature() throws {
        guard let pk = appleECP8PrivateKey.data(using: .utf8) else { XCTFail("Can't convert private key string to Data"); return}
        let signer = APNSSigners.SigningMode.data(pk)
        let teamID = "8RX5AF8F6Z"
        let keyID = "9N8238KQ6Z"
        let date = Date()
        let jwt = APNSJWT(keyID: keyID, teamID: teamID, issueDate: date, expireDuration: 10.0)
        let digestValues = try jwt.getDigest()
        let _ = try signer.sign(digest: digestValues.fixedDigest)

    }

    static var allTests = [
        ("testSandboxConfiguration", testSandboxConfiguration),
        ("testProductionConfiguration", testProductionConfiguration),
        ("testSignature", testSignature)
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
