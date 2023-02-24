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

import APNSCore
import Crypto

/// The configuration of an ``APNSClient``.
public struct APNSURLSessionClientConfiguration {
    /// The authentication method used by the ``APNSClient``.
    public struct AuthenticationMethod {
        public enum Method {
            case jwt(privateKey: P256.Signing.PrivateKey, teamIdentifier: String, keyIdentifier: String)
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
            privateKey: P256.Signing.PrivateKey,
            keyIdentifier: String,
            teamIdentifier: String
        ) -> Self {
            Self(method: .jwt(privateKey: privateKey, teamIdentifier: teamIdentifier, keyIdentifier: keyIdentifier))
        }

        public var method: Method
    }

    /// The authentication method used by the ``APNSClient``.
    public var authenticationMethod: AuthenticationMethod

    /// The environment used by the ``APNSClient``.
    public var environment: APNSEnvironment

    /// Initializes a new ``APNSClient.Configuration``.
    ///
    /// - Parameters:
    ///   - authenticationMethod: The authentication method used by the ``APNSClient``.
    ///   - environment: The environment used by the ``APNSClient``.
    public init(
        authenticationMethod: AuthenticationMethod,
        environment: APNSEnvironment
    ) {
        self.authenticationMethod = authenticationMethod
        self.environment = environment
    }
}

