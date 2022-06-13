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

import AsyncHTTPClient
import Crypto
import Foundation
import Logging
import NIOCore

/// This is structure that provides the system with common configuration.
public struct APNSConfiguration {
    public typealias APNSPrivateKey = P256.Signing.PrivateKey
    internal var authenticationConfig: Authentication

    public struct Authentication {

        /// Configurtion for handling bearer tokens
        /// - Parameters:
        ///   - privateKey: A string of the private key used to sign requests
        ///   - teamIdentifier: An Apple developer team identifier
        ///   - keyIdentifier: A key identifier provided by Apple
        public init(
            privateKey: APNSConfiguration.APNSPrivateKey,
            teamIdentifier: String,
            keyIdentifier: String
        ) {
            self.privateKey = privateKey
            self.teamIdentifier = teamIdentifier
            self.keyIdentifier = keyIdentifier
        }

        internal let privateKey: APNSPrivateKey
        internal let teamIdentifier: String
        internal let keyIdentifier: String
    }

    internal let topic: String
    internal let environment: Environment
    internal let logger: Logger?
    /// Optional timeout time if the connection does not receive a response.
    internal let timeout: TimeAmount?
    internal let eventLoopGroupProvider: EventLoopGroupProvider
    internal let proxy: Proxy?

    /// `APNSConfiguration` provides the values for APNSClient to use when sending pushes
    /// - Parameters:
    ///   - authenticationConfig: A configuration type to handle bearer tokens
    ///   - topic: A string for which the push is sent to e.g `com.grasscove.Fern`
    ///   - environment: The environment which APNSClient will connect to
    ///   - eventLoopGroupProvider: The event loop provider for APNSwift
    ///   - logger: An optional logger
    ///   - timeout: An optional timeout for requests
    public init(
        authenticationConfig: APNSConfiguration.Authentication,
        topic: String,
        environment: APNSConfiguration.Environment,
        eventLoopGroupProvider: EventLoopGroupProvider,
        logger: Logger? = nil,
        timeout: TimeAmount? = nil,
        proxy: Proxy? = nil
    ) {
        self.topic = topic
        self.authenticationConfig = authenticationConfig
        self.environment = environment
        self.eventLoopGroupProvider = eventLoopGroupProvider
        self.timeout = timeout
        self.logger = logger
        self.proxy = proxy
    }
}

extension APNSConfiguration {
    /// Provides an enum to manage the URL at which the push is sent.
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

    /// Specifies how `EventLoopGroup` will be created and establishes lifecycle ownership.
    public struct EventLoopGroupProvider {
        var httpClientValue: HTTPClient.EventLoopGroupProvider

        init(_ httpClientValue: HTTPClient.EventLoopGroupProvider) {
            self.httpClientValue = httpClientValue
        }

        /// `EventLoopGroup` will be created by the client. When `syncShutdown` is called, created `EventLoopGroup` will be shut down as well.
        public static let createNew = EventLoopGroupProvider(.createNew)

        /// `EventLoopGroup` will be provided by the user. Owner of this group is responsible for its lifecycle.
        public static func shared(_ eventLoopGroup: EventLoopGroup) -> EventLoopGroupProvider {
            .init(.shared(eventLoopGroup))
        }
    }
}

extension APNSConfiguration {
    public struct Proxy {
        public struct HTTPAuthorization {
            var base: HTTPClient.Authorization

            init(_ base: HTTPClient.Authorization) {
                self.base = base
            }

            public static func basic(username: String, password: String) -> HTTPClient.Authorization
            {
                .basic(username: username, password: password)
            }
            public static func basic(credentials: String) -> HTTPClient.Authorization {
                .basic(credentials: credentials)
            }
            public static func bearer(tokens: String) -> HTTPClient.Authorization {
                .bearer(tokens: tokens)
            }
        }

        var base: HTTPClient.Configuration.Proxy

        public static func server(host: String, port: Int) -> Proxy {
            return .server(host: host, port: port)
        }

        public static func http(host: String, port: Int, authorization: HTTPAuthorization? = nil)
            -> Proxy
        {
            return .http(host: host, port: port, authorization: authorization)
        }

        public static func socks(host: String, port: Int = 1080) -> Proxy {
            return .socks(host: host, port: port)
        }
    }
}
