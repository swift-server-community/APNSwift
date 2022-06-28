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

import Crypto
import NIOSSL
import NIOTLS
import AsyncHTTPClient

/// The configuration of an ``APNSClient``.
public struct APNSClientConfiguration {
    /// The authentication method used by the ``APNSClient``.
    public struct AuthenticationMethod {
        internal enum Method {
            case jwt(privateKey: P256.Signing.PrivateKey, teamIdentifier: String, keyIdentifier: String)
            case tls(privateKey: NIOSSLPrivateKeySource, certificateChain: [NIOSSLCertificateSource])
        }

        /// Token-based authentication method.
        ///
        /// This authentication method is bound to a single connection since APNs will reject connections
        /// that use tokens signed by different keys.
        ///
        /// - Parameters:
        ///   - privateKey: The private encryption key obtained through the developer portal.
        ///   - keyIdentifier: The private encryption key identifier obtained through the developer portal.
        ///   - teamIdentifier: The team id.
        public static func jwt(
            privateKey: P256.Signing.PrivateKey, keyIdentifier: String,
            teamIdentifier: String
        ) -> Self {
            Self(method: .jwt(privateKey: privateKey, teamIdentifier: teamIdentifier, keyIdentifier: keyIdentifier))
        }

        /// Certificate based authentication method.
        ///
        /// - Parameters:
        ///   - privateKey: The private key associated with the leaf certificate.
        ///   - certificateChain: The certificates to offer during negotiation. If not present, no certificates will be offered.
        public static func tls(
            privateKey: NIOSSLPrivateKeySource,
            certificateChain: [NIOSSLCertificateSource]
        ) -> Self {
            Self(method: .tls(privateKey: privateKey, certificateChain: certificateChain))
        }

        internal var method: Method
    }

    /// The APNs environment.
    public struct Environment {
        /// The production APNs environment.
        public static let production = Self(url: "https://api.push.apple.com")

        /// The sandbox APNs environment.
        public static let sandbox = Self(url: "https://api.development.push.apple.com")

        /// Creates an APNs environment with a custom URL.
        ///
        /// - Note: This is mostly used for testing purposes.
        public static func custom(url: String) -> Self {
            Self(url: url)
        }

        /// The environment's URL.
        let url: String
    }

    /// The authentication method used by the ``APNSClient``.
    public var authenticationMethod: AuthenticationMethod

    /// The environment used by the ``APNSClient``.
    public var environment: Environment

    /// Upstream proxy, defaults to no proxy.
    public var proxy: HTTPClient.Configuration.Proxy?

    /// Initializes a new ``APNSClient.Configuration``.
    ///
    /// - Parameters:
    ///   - authenticationMethod: The authentication method used by the ``APNSClient``.
    ///   - environment: The environment used by the ``APNSClient``.
    public init(
        authenticationMethod: AuthenticationMethod,
        environment: Environment
    ) {
        self.authenticationMethod = authenticationMethod
        self.environment = environment
    }
}

