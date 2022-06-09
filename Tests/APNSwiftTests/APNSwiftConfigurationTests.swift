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
import AsyncHTTPClient
import Logging
import NIO
import NIOSSL

class APNSwiftConfigurationTests: XCTestCase {
    let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)

    func configuration(environment: APNSwiftConfiguration.Environment) throws {

        let apnsConfiguration = try APNSwiftConfiguration(
            httpClient: httpClient,
            authenticationMethod: .jwt(
                key: .private(pem: Data(appleECP8PrivateKey.utf8)),
                keyIdentifier: "MY_KEY_ID",
                teamIdentifier: "MY_TEAM_ID"
            ),
            topic: "MY_TOPIC",
            environment: environment,
            timeout: .seconds(5)
        )

        switch environment {
        case .production:
            XCTAssertEqual(apnsConfiguration.environment.url, URL(string: "https://api.push.apple.com"))
        case .sandbox:
            XCTAssertEqual(apnsConfiguration.environment.url, URL(string: "https://api.development.push.apple.com"))
        }

        switch apnsConfiguration.authenticationMethod {
        case .jwt(let signers, let teamIdentifier, let keyIdentifier):
            XCTAssertNotNil(signers.get(kid: "MY_KEY_ID"))
            XCTAssertEqual(teamIdentifier, "MY_TEAM_ID")
            XCTAssertEqual(keyIdentifier, "MY_KEY_ID")
        }
        XCTAssertEqual(apnsConfiguration.topic, "MY_TOPIC")
        XCTAssertEqual(apnsConfiguration.timeout, .seconds(5))

    }

    func testSandboxConfiguration() throws {
        try configuration(environment: .sandbox)
    }

    func testProductionConfiguration() throws {
        try configuration(environment: .production)
    }

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
