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
import XCTest

final class APNSAuthenticationTokenManagerTests: XCTestCase {
    private static let signingKey = """
    -----BEGIN EC PRIVATE KEY-----
    MHcCAQEEIPnrjgMs/LOp9W5R2kQtdBfzyjCe2wICBOWgyCA6OwRDoAoGCCqGSM49
    AwEHoUQDQgAEbWmxH/HLvIJIVUt8bB42ntiBZUSb6Bxx7F36mDSHssBaRBU0BYYj
    NVeBKbgP2rVE/nOAexjhmWE2S5G98nkEPg==
    -----END EC PRIVATE KEY-----
    
    """
    private var clock: TestClock<Duration>!
    private var tokenManager: APNSAuthenticationTokenManager<TestClock<Duration>>!
    
    override func setUp() {
        super.setUp()
        clock = TestClock()
        tokenManager = APNSAuthenticationTokenManager(
            privateKey: try! .init(pemRepresentation: Self.signingKey),
            teamIdentifier: "foo",
            keyIdentifier: "bar",
            clock: clock
        )
    }
    
    override func tearDown() {
        super.tearDown()
        
        tokenManager = nil
        clock = nil
    }
    
    func testToken() async throws {
        let token = try await tokenManager.nextValidToken
        
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
        let issuedAtTime = DispatchWallTime.now()
        let expectedPayload = """
        {
            "iss": "foo",
            "iat": "\(issuedAtTime.asSecondsSince1970)",
            "kid": "bar"
        }
        """
        XCTAssertEqual(payload, expectedPayload)
    }
    
        func testTokenIsReused() async throws {
   
            let token1 = try await tokenManager.nextValidToken
            // 48 minutes later
            let temp = clock.now.advanced(by: .init(secondsComponent: 2880, attosecondsComponent: 0))
            clock.now = temp
            let token2 = try await tokenManager.nextValidToken
    
            XCTAssertEqual(token1, token2)
        }

    func testTokenIsRefreshed() async throws {
        let token1 = try await tokenManager.nextValidToken
        
        // 56 minutes later
        let temp = clock.now.advanced(by: .init(secondsComponent: 3360, attosecondsComponent: 0))
        clock.now = temp
        let token2 = try await tokenManager.nextValidToken

        XCTAssertNotEqual(token1, token2)
    }
}

final class TestClock<Duration: DurationProtocol & Hashable>: Clock {
    struct Instant: InstantProtocol {
        public var offset: Duration
        
        public init(offset: Duration = .zero) {
            self.offset = offset
        }
        
        public func advanced(by duration: Duration) -> Self {
            .init(offset: self.offset + duration)
        }
        
        public func duration(to other: Self) -> Duration {
            other.offset - self.offset
        }
        
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.offset < rhs.offset
        }
    }
    
    let minimumResolution: Duration = .zero
    var now: Instant

    
    public init(now: Instant = .init()) {
        self.now = .init()
    }
    
    public func sleep(until deadline: Instant, tolerance: Duration? = nil) async throws {
        try Task.checkCancellation()
        try await Task.sleep(until: deadline, clock: self)
    }
}
