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

import AsyncHTTPClient
import Foundation
import Logging
import NIO
import NIOHTTP2
import NIOSSL
import JWTKit

/// This is structure that provides the system with common configuration.
public struct APNSwiftConfiguration {
    public var authenticationMethod: AuthenticationMethod

    public enum AuthenticationMethod {
        public static func jwt(
            key: ECDSAKey,
            keyIdentifier: JWKIdentifier,
            teamIdentifier: String
        ) -> Self {
            let signers = JWTSigners()
            signers.use(.es256(key: key), kid: keyIdentifier, isDefault: true)
            return .jwt(signers, teamIdentifier: teamIdentifier, keyIdentifier: keyIdentifier.string)
        }

        case jwt(JWTSigners, teamIdentifier: String, keyIdentifier: String)
    }

    public func makeBearerTokenFactory() -> APNSwiftBearerTokenFactory? {
        switch self.authenticationMethod {
        case .jwt(let signers, let teamIdentifier, let keyIdentifier):
            return .init(
                signers: signers,
                teamIdentifier: teamIdentifier,
                keyIdentifier: keyIdentifier,
                logger: self.logger
            )
        }
    }

    public var httpClient: HTTPClient
    public var topic: String
    public var environment: Environment
    public var logger: Logger?
    /// Optional timeout time if the connection does not receive a response.
    public var timeout: TimeAmount? = nil

    public init(
        httpClient: HTTPClient,
        authenticationMethod: AuthenticationMethod,
        topic: String,
        environment: APNSwiftConfiguration.Environment,
        logger: Logger? = nil,
        timeout: TimeAmount? = nil
    ) {
        self.httpClient = httpClient
        self.topic = topic
        self.authenticationMethod = authenticationMethod
        self.environment = environment
        self.timeout = timeout
        self.logger = logger
    }
}

extension APNSwiftConfiguration {
    public enum Environment {
        case production
        case sandbox

        public var url: URL {
            switch self {
            case .production:
                return URL(string: "https://api.push.apple.com")!
            case .sandbox:
                return URL(string: "https://api.development.push.apple.com")!
            }
        }
    }
}

extension APNSwiftConnection {
    public enum PushType: String {
        case alert
        case background
        case mdm
        case voip
        case fileprovider
        case complication
    }
}
