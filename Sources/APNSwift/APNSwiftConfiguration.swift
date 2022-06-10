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
import Crypto
import Foundation
import Logging
import NIOCore

/// This is structure that provides the system with common configuration.
public struct APNSwiftConfiguration {
    public typealias APNSPrivateKey = P256.Signing.PrivateKey
    public var authenticationConfig: Authentication

    public struct Authentication {
        public init(
            privateKey: APNSwiftConfiguration.APNSPrivateKey,
            teamIdentifier: String,
            keyIdentifier: String
        ) {
            self.privateKey = privateKey
            self.teamIdentifier = teamIdentifier
            self.keyIdentifier = keyIdentifier
        }

        let privateKey: APNSPrivateKey
        let teamIdentifier: String
        let keyIdentifier: String
    }

    internal let httpClient: HTTPClient
    internal let topic: String
    internal let environment: Environment
    internal let logger: Logger?
    /// Optional timeout time if the connection does not receive a response.
    internal let timeout: TimeAmount?

    public init(
        httpClient: HTTPClient,
        authenticationConfig: APNSwiftConfiguration.Authentication,
        topic: String,
        environment: APNSwiftConfiguration.Environment,
        logger: Logger? = nil,
        timeout: TimeAmount? = nil
    ) {
        self.httpClient = httpClient
        self.topic = topic
        self.authenticationConfig = authenticationConfig
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
