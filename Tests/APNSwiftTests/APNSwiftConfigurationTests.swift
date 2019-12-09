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

import XCTest
@testable import APNSwift
import Logging
import NIO

class APNSwiftConfigurationTests: XCTestCase {

    func configuration(environment: APNSwiftConfiguration.Environment) throws {
        var buffer = ByteBufferAllocator().buffer(capacity: appleECP8PrivateKey.count)
        buffer.writeString(appleECP8PrivateKey)
        let signer = try APNSwiftSigner.init(buffer: buffer)

        let apnsConfiguration = APNSwiftConfiguration(keyIdentifier: "MY_KEY_ID", teamIdentifier: "MY_TEAM_ID", signer: signer, topic: "MY_TOPIC", environment: environment)

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
        var buffer = ByteBufferAllocator().buffer(capacity: appleECP8PrivateKey.count)
        buffer.writeString(appleECP8PrivateKey)
        let signer = try APNSwiftSigner.init(buffer: buffer)
        let teamID = "8RX5AF8F6Z"
        let keyID = "9N8238KQ6Z"
        let date = Date()
        let jwt = APNSwiftJWT(keyID: keyID, teamID: teamID, issueDate: date)
        let digestValues = try jwt.getDigest()
        let _ = try signer.sign(digest: digestValues.fixedDigest)

    }

    static var allTests = [
        ("testSandboxConfiguration", testSandboxConfiguration),
        ("testProductionConfiguration", testProductionConfiguration),
        ("testSignature", testSignature),
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
