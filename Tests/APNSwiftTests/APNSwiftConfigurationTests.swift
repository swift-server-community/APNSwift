//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2022 the APNSwift project authors
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

class APNSConfigurationTests: XCTestCase {
    let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)

    func configuration(environment: APNSConfiguration.Environment) throws {
        let privateKey: APNSConfiguration.APNSPrivateKey = try .loadFrom(string: appleECP8PrivateKey)
        let authenticationConfig: APNSConfiguration.Authentication = .init(
            privateKey: privateKey,
            teamIdentifier: "MY_TEAM_ID",
            keyIdentifier: "MY_KEY_ID"
        )

        let apnsConfiguration = APNSConfiguration(
            authenticationConfig: authenticationConfig,
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

        let loadedKey: APNSConfiguration.APNSPrivateKey = try .loadFrom(string: appleECP8PrivateKey)
        XCTAssertEqual(loadedKey.rawRepresentation, authenticationConfig.privateKey.rawRepresentation)
        XCTAssertEqual("MY_KEY_ID", authenticationConfig.keyIdentifier)
        XCTAssertEqual("MY_TEAM_ID", authenticationConfig.teamIdentifier)

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
