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

@testable import APNSCore
import APNS
import Crypto
import XCTest

final class APNSClientTests: XCTestCase {
    func testShutdown() async throws {
        let client = self.makeClient()
        try await client.shutdown()
    }

    // MARK: - Helper methods

    private func makeClient() -> APNSClient<JSONDecoder, JSONEncoder> {
        APNSClient(
            configuration: .init(
                authenticationMethod: .jwt(
                    privateKey: try! P256.Signing.PrivateKey(pemRepresentation: self.jwtPrivateKey),
                    keyIdentifier: "MY_KEY_ID",
                    teamIdentifier: "MY_TEAM_ID"
                ),
                environment: .development
            ),
            eventLoopGroupProvider: .createNew,
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder()
        )
    }

    private let jwtPrivateKey = """
    -----BEGIN PRIVATE KEY-----
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg2sD+kukkA8GZUpmm
    jRa4fJ9Xa/JnIG4Hpi7tNO66+OGgCgYIKoZIzj0DAQehRANCAATZp0yt0btpR9kf
    ntp4oUUzTV0+eTELXxJxFvhnqmgwGAm1iVW132XLrdRG/ntlbQ1yzUuJkHtYBNve
    y+77Vzsd
    -----END PRIVATE KEY-----
    """
}

// This doesn't perform any runtime tests, it just ensures the call to sendAlertNotification
// compiles when called within an actor's isolation context.
actor TestActor {
    func sendAlert(client: APNSClient<JSONDecoder, JSONEncoder>) async throws {
        let notification = APNSAlertNotification(
            alert: .init(title: .raw("title")),
            expiration: .immediately,
            priority: .immediately,
            topic: "",
            payload: ""
        )
        try await client.sendAlertNotification(notification, deviceToken: "")
    }
}
