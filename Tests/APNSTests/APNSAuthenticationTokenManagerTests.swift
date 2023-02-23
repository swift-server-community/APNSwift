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
import Crypto
import Logging
import XCTest

final class APNSAuthenticationTokenManagerTests: XCTestCase {
    private static let signingKey = """
    -----BEGIN EC PRIVATE KEY-----
    MHcCAQEEIPnrjgMs/LOp9W5R2kQtdBfzyjCe2wICBOWgyCA6OwRDoAoGCCqGSM49
    AwEHoUQDQgAEbWmxH/HLvIJIVUt8bB42ntiBZUSb6Bxx7F36mDSHssBaRBU0BYYj
    NVeBKbgP2rVE/nOAexjhmWE2S5G98nkEPg==
    -----END EC PRIVATE KEY-----

    """
    private var currentTime: DispatchWallTime!
    private var tokenManager: APNSAuthenticationTokenManager!

    override func setUp() {
        super.setUp()

        tokenManager = APNSAuthenticationTokenManager(
            privateKey: try! .init(pemRepresentation: Self.signingKey),
            teamIdentifier: "foo",
            keyIdentifier: "bar",
            logger: Logger(label: "tests"),
            currentTimeFactory: { self.currentTime }
        )
    }

    override func tearDown() {
        super.tearDown()

        tokenManager = nil
        currentTime = nil
    }

    func testToken() async throws {
        currentTime = .init(timespec: .init(tv_sec: 1_647_530_000, tv_nsec: 0))

        let token = try tokenManager.nextValidToken

        // We need to split twice here since the expected format of the token is
        // "bearer encodedHeader.encodedPayload.ecnodedSignature"
        let splitToken = try XCTUnwrap(token.split(separator: " ").last)
            .split(separator: ".")

        let decodedHeader = try Base64.decode(
            string: String(splitToken[0]),
            options: [.base64UrlAlphabet, .omitPaddingCharacter]
        )
        let header = String(bytes: decodedHeader, encoding: .utf8)
        let expectedHeader = """
        {
            "alg": "ES256",
            "typ": "JWT",
            "kid": "bar"
        }
        """
        XCTAssertEqual(header, expectedHeader)

        let decodedPayload = try Base64.decode(
            string: String(splitToken[1]),
            options: [.base64UrlAlphabet, .omitPaddingCharacter]
        )
        let payload = String(bytes: decodedPayload, encoding: .utf8)
        let expectedPayload = """
        {
            "iss": "foo",
            "iat": "1647530000",
            "kid": "bar"
        }
        """
        XCTAssertEqual(payload, expectedPayload)
    }

    func testTokenIsReused() async throws {
        currentTime = .init(timespec: .init(tv_sec: 1_647_530_000, tv_nsec: 0))

        let token1 = try tokenManager.nextValidToken

        // 50 minutes later
        currentTime = .init(timespec: .init(tv_sec: 1_647_533_000, tv_nsec: 0))
        let token2 = try tokenManager.nextValidToken

        XCTAssertEqual(token1, token2)
    }

    func testTokenIsRefreshed() async throws {
        currentTime = .init(timespec: .init(tv_sec: 1_647_530_000, tv_nsec: 0))

        let token1 = try tokenManager.nextValidToken

        // 56 minutes later
        currentTime = .init(timespec: .init(tv_sec: 1_647_533_360, tv_nsec: 0))
        let token2 = try tokenManager.nextValidToken

        XCTAssertNotEqual(token1, token2)
    }
}
