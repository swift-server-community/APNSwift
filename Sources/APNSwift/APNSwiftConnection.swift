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
import NIOCore
import NIOFoundationCompat

public final class APNSwiftConnection: APNSwiftClient {

    public let configuration: APNSwiftConfiguration
    private let bearerTokenFactory: APNSwiftBearerTokenFactory
    public var logger: Logger?

    private let jsonDecoder = JSONDecoder()

    public init(
        configuration: APNSwiftConfiguration,
        logger: Logger? = nil
    ) {
        self.configuration = configuration
        self.logger = logger
        self.bearerTokenFactory = APNSwiftBearerTokenFactory(
            authenticationConfig: configuration.authenticationConfig,
            logger: logger
        )
    }

    /// This is to be used with caution. APNSwift cannot gurantee delivery if you do not have the correct payload.
    /// For more information see: [Creating APN Payload](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html)
    public func send(
        rawBytes payload: ByteBuffer,
        pushType: APNSwiftConnection.PushType,
        to deviceToken: String,
        on environment: APNSwiftConfiguration.Environment?,
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        logger: Logger?,
        apnsID: UUID?
    ) async throws {
        let logger = logger ?? self.configuration.logger
        logger?.debug("Sending \(pushType) to \(deviceToken.prefix(8))... at: \(topic ?? configuration.topic)")
        var urlBase: String
        if let overriddenEnvironment = environment {
            urlBase = overriddenEnvironment.url.absoluteString
        } else {
            urlBase = configuration.environment.url.absoluteString
        }
        var request = HTTPClientRequest(url: "\(urlBase)/3/device/\(deviceToken)")
        request.method = .POST
        request.headers.add(name: "content-type", value: "application/json")
        request.headers.add(name: "user-agent", value: "APNS/swift-nio")
        request.headers.add(name: "content-length", value: "\(payload.readableBytes)")

        if let notificationSpecificTopic = topic {
            request.headers.add(name: "apns-topic", value: notificationSpecificTopic)
        } else {
            request.headers.add(name: "apns-topic", value: configuration.topic)
        }

        if let priority = priority {
            request.headers.add(name: "apns-priority", value: String(priority))
        }
        if let epochTime = expiration?.timeIntervalSince1970 {
            request.headers.add(name: "apns-expiration", value: String(Int(epochTime)))
        }
        if let collapseId = collapseIdentifier {
            request.headers.add(name: "apns-collapse-id", value: collapseId)
        }
        request.headers.add(name: "apns-push-type", value: pushType.rawValue)
        request.headers.add(name: "host", value: urlBase)

        // Only use token auth if bearer token is present.
        if let bearerToken = await bearerTokenFactory.currentBearerToken {
            request.headers.add(name: "authorization", value: "bearer \(bearerToken)")
        }
        if let apnsID = apnsID {
            request.headers.add(name: "apns-id", value: apnsID.uuidString.lowercased())
        }

        request.body = .bytes(payload)

        let response = try await configuration.httpClient.execute(request, timeout: configuration.timeout ?? .seconds(30))
        if response.status != .ok {
            let body = try await response.body.collect(upTo: 1024 * 1024)

            let error = try jsonDecoder.decode(APNSwiftError.ResponseStruct.self, from: body)
            logger?.warning("Response - bad request \(error.reason)")
            throw APNSwiftError.ResponseError.badRequest(error.reason)
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
