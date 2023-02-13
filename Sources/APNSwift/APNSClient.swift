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
import Dispatch
import struct Foundation.Date
import struct Foundation.UUID
import Logging
import NIOConcurrencyHelpers
import NIOCore
import NIOHTTP1
import NIOSSL
import NIOTLS

/// A client to talk with the Apple Push Notification services.
public final class APNSClient<Decoder: APNSJSONDecoder, Encoder: APNSJSONEncoder> {
    /// The configuration used by the ``APNSClient``.
    private let configuration: APNSClientConfiguration
    /// The ``HTTPClient`` used by the ``APNSClient``.
    private let httpClient: HTTPClient
    /// The logger used by the ``APNSClient``.
    private let backgroundActivityLogger: Logger
    /// The authentication token manager.
    private let authenticationTokenManager: APNSAuthenticationTokenManager?
    /// The decoder for the responses from APNs.
    private let responseDecoder: Decoder
    /// The encoder for the requests to APNs.
    @usableFromInline
    /* private */ internal let requestEncoder: Encoder
    /// The ByteBufferAllocator
    @usableFromInline
    /* private */ internal let byteBufferAllocator: ByteBufferAllocator
    /// Default ``HTTPHeaders`` which will be adapted for each request. This saves some allocations.
    private let defaultRequestHeaders: HTTPHeaders = {
        var headers = HTTPHeaders()
        headers.reserveCapacity(10)
        headers.add(name: "content-type", value: "application/json")
        headers.add(name: "user-agent", value: "APNS/swift-nio")
        return headers
    }()

    /// Initializes a new ``APNSClient``.
    ///
    /// The client will create an internal ``HTTPClient`` which is used to make requests to APNs.
    /// This ``HTTPClient`` is intentionally internal since both authentication mechanisms are bound to a
    /// single connection and these connections cannot be shared.
    ///
    ///
    /// - Parameters:
    ///   - configuration: The configuration used by the ``APNSClient``.
    ///   - eventLoopGroupProvider: Specify how EventLoopGroup will be created.
    ///   - responseDecoder: The decoder for the responses from APNs.
    ///   - requestEncoder: The encoder for the requests to APNs.
    ///   - backgroundActivityLogger: The logger used by the ``APNSClient``.
    public init(
        configuration: APNSClientConfiguration,
        eventLoopGroupProvider: NIOEventLoopGroupProvider,
        responseDecoder: Decoder,
        requestEncoder: Encoder,
        byteBufferAllocator: ByteBufferAllocator = .init(),
        backgroundActivityLogger: Logger = _noOpLogger
    ) {
        self.configuration = configuration
        self.byteBufferAllocator = byteBufferAllocator
        self.backgroundActivityLogger = backgroundActivityLogger
        self.responseDecoder = responseDecoder
        self.requestEncoder = requestEncoder

        var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
        switch configuration.authenticationMethod.method {
        case .jwt(let privateKey, let teamIdentifier, let keyIdentifier):
            self.authenticationTokenManager = APNSAuthenticationTokenManager(
                privateKey: privateKey,
                teamIdentifier: teamIdentifier,
                keyIdentifier: keyIdentifier,
                logger: backgroundActivityLogger
            )
        case .tls(let privateKey, let certificateChain):
            self.authenticationTokenManager = nil
            tlsConfiguration.privateKey = privateKey
            tlsConfiguration.certificateChain = certificateChain
        }

        var httpClientConfiguration = HTTPClient.Configuration()
        httpClientConfiguration.tlsConfiguration = tlsConfiguration
        httpClientConfiguration.httpVersion = .automatic
        httpClientConfiguration.proxy = configuration.proxy

        let httpClientEventLoopGroupProvider: HTTPClient.EventLoopGroupProvider

        switch eventLoopGroupProvider {
        case .shared(let eventLoopGroup):
            httpClientEventLoopGroupProvider = .shared(eventLoopGroup)
        case .createNew:
            httpClientEventLoopGroupProvider = .createNew
        }

        self.httpClient = HTTPClient(
            eventLoopGroupProvider: httpClientEventLoopGroupProvider,
            configuration: httpClientConfiguration,
            backgroundActivityLogger: backgroundActivityLogger
        )
    }

    /// Shuts down the client and event loop gracefully. This function is clearly an outlier in that it uses a completion
    /// callback instead of an EventLoopFuture. The reason for that is that NIO's EventLoopFutures will call back on an event loop.
    /// The virtue of this function is to shut the event loop down. To work around that we call back on a DispatchQueue
    /// instead.
    ///
    /// - Important: This will only shutdown the event loop if the provider passed to the client was ``createNew``.
    /// For shared event loops the owner of the event loop is responsible for handling the lifecycle.
    ///
    /// - Parameters:
    ///   - queue: The queue on which the callback is invoked on.
    ///   - callback: The callback that is invoked when everything is shutdown.
    public func shutdown(queue: DispatchQueue = .global(), callback: @escaping (Error?) -> Void) {
        self.backgroundActivityLogger.trace("APNSClient is shutting down")
        self.httpClient.shutdown(callback)
    }

    /// Shuts down the client and `EventLoopGroup` if it was created by the client.
    public func syncShutdown() throws {
        self.backgroundActivityLogger.trace("APNSClient is shutting down")
        try self.httpClient.syncShutdown()
    }
}


// MARK: - Raw sending

extension APNSClient {
    /// Sends a notification to APNs.
    ///
    /// - Important: This method exposes the raw API for APNs. In general, this should be avoided
    /// and the semantic-safe APIs should be used instead.
    ///
    /// - Parameters:
    ///   - payload: The notification payload.
    ///
    ///   - deviceToken: The hexadecimal bytes that identify the user’s device. Your app receives the bytes for this device token
    ///    when registering for remote notifications.
    ///
    ///   - pushType: The value of this header must accurately reflect the contents of your notification’s payload. If there’s a mismatch,
    ///    or if the header is missing on required systems, APNs may return an error, delay the delivery of the notification, or drop it altogether.
    ///
    ///   - apnsID: A canonical UUID that identifies the notification. If there is an error sending the notification,
    ///    APNs uses this value to identify the notification to your server. The canonical form is 32 lowercase hexadecimal digits,
    ///    displayed in five groups separated by hyphens in the form 8-4-4-4-12. An example UUID is as follows: 123e4567-e89b-12d3-a456-42665544000.
    ///    If you omit this, a new UUID is created by APNs and returned in the response.
    ///
    ///   - expiration: The date when the notification is no longer valid and can be discarded. If this value is not `none`,
    ///    APNs stores the notification and tries to deliver it at least once, repeating the attempt as needed if it is unable to deliver the notification the first time.
    ///    If the value is `immediately`, APNs treats the notification as if it expires immediately and does not store the notification or attempt to redeliver it.
    ///
    ///   - priority: The priority of the notification. If you omit this header, APNs sets the notification priority to `immediately`.
    ///
    ///   - topic: The topic for the notification. In general, the topic is your app’s bundle ID/app ID.
    ///    It can have a suffix based on the type of push notification. If you’re using a certificate that supports PushKit VoIP or watchOS complication notifications,
    ///    you must include this header with bundle ID of you app and if applicable, the proper suffix.
    ///    If you’re using token-based authentication with APNs, you must include this header with the correct bundle ID and suffix combination.
    ///
    ///   - collapseID: An identifier you use to coalesce multiple notifications into a single notification for the user.
    ///    Typically, each notification request causes a new notification to be displayed on the user’s device.
    ///    When sending the same notification more than once, use the same value in this header to coalesce the requests.
    ///    The value of this key must not exceed 64 bytes.
    ///
    ///   - deadline: Point in time by which sending the notification to APNs must complete.
    ///
    ///   - logger: The logger to use for sending this notification.
    @discardableResult
    @inlinable
    public func send<Payload: Encodable>(
        payload: Payload?,
        deviceToken: String,
        pushType: APNSPushType,
        apnsID: UUID? = nil,
        expiration: APNSNotificationExpiration,
        priority: APNSPriority,
        topic: String? = nil,
        collapseID: String? = nil,
        deadline: NIODeadline,
        logger: Logger = _noOpLogger
    ) async throws -> APNSResponse {
        var byteBuffer = self.byteBufferAllocator.buffer(capacity: 0)

        if let payload = payload {
            try self.requestEncoder.encode(payload, into: &byteBuffer)
        }

        return try await self.send(
            payload: byteBuffer,
            deviceToken: deviceToken,
            pushType: pushType.configuration.rawValue,
            apnsID: apnsID,
            expiration: expiration.expiration,
            priority: priority.rawValue,
            topic: topic,
            collapseID: collapseID,
            deadline: deadline,
            logger: logger
        )
    }

    /// Sends a notification to APNs.
    ///
    /// - Important: This method exposes the raw API for APNs. In general, this should be avoided
    /// and the semantic-safe APIs should be used instead.
    ///
    /// - Parameters:
    ///   - payload: A ``ByteBuffer`` with the notification payload.
    ///
    ///   - deviceToken: The hexadecimal bytes that identify the user’s device. Your app receives the bytes for this device token
    ///    when registering for remote notifications.
    ///
    ///   - pushType: The value of this header must accurately reflect the contents of your notification’s payload. If there’s a mismatch,
    ///    or if the header is missing on required systems, APNs may return an error, delay the delivery of the notification, or drop it altogether.
    ///
    ///   - apnsID: A canonical UUID that identifies the notification. If there is an error sending the notification,
    ///    APNs uses this value to identify the notification to your server. The canonical form is 32 lowercase hexadecimal digits,
    ///    displayed in five groups separated by hyphens in the form 8-4-4-4-12. An example UUID is as follows: 123e4567-e89b-12d3-a456-42665544000.
    ///    If you omit this, a new UUID is created by APNs and returned in the response.
    ///
    ///   - expiration: The date when the notification is no longer valid and can be discarded. This value is a UNIX epoch expressed in seconds (UTC). If this value is nonzero,
    ///    APNs stores the notification and tries to deliver it at least once, repeating the attempt as needed if it is unable to deliver the notification the first time.
    ///    If the value is 0, APNs treats the notification as if it expires immediately and does not store the notification or attempt to redeliver it.
    ///
    ///   - priority: The priority of the notification. If you omit this header, APNs sets the notification priority to `immediately`.
    ///
    ///   - topic: The topic for the notification. In general, the topic is your app’s bundle ID/app ID.
    ///    It can have a suffix based on the type of push notification. If you’re using a certificate that supports PushKit VoIP or watchOS complication notifications,
    ///    you must include this header with bundle ID of you app and if applicable, the proper suffix.
    ///    If you’re using token-based authentication with APNs, you must include this header with the correct bundle ID and suffix combination.
    ///
    ///   - collapseID: An identifier you use to coalesce multiple notifications into a single notification for the user.
    ///    Typically, each notification request causes a new notification to be displayed on the user’s device.
    ///    When sending the same notification more than once, use the same value in this header to coalesce the requests.
    ///    The value of this key must not exceed 64 bytes.
    ///
    ///   - deadline: Point in time by which sending the notification to APNs must complete.
    ///
    ///   - logger: The logger to use for sending this notification.
    @discardableResult
    public func send(
        payload: ByteBuffer,
        deviceToken: String,
        pushType: String,
        apnsID: UUID? = nil,
        expiration: Int? = nil,
        priority: Int? = nil,
        topic: String? = nil,
        collapseID: String? = nil,
        deadline: NIODeadline,
        logger: Logger = _noOpLogger,
        file: String = #file,
        line: Int = #line
    ) async throws -> APNSResponse {
        var logger = logger
        var headers = self.defaultRequestHeaders

        // Push type
        headers.add(name: "apns-push-type", value: pushType)

        // APNS ID
        if let apnsID = apnsID {
            headers.add(name: "apns-id", value: apnsID.uuidString.lowercased())
        }

        // Expiration
        if let expiration = expiration {
            headers.add(name: "apns-expiration", value: String(expiration))
        }

        // Priority
        if let priority = priority {
            headers.add(name: "apns-priority", value: String(priority))
        }

        // Topic
        if let topic = topic {
            headers.add(name: "apns-topic", value: topic)
        }

        // Collapse ID
        if let collapseID = collapseID {
            headers.add(name: "apns-collapse-id", value: collapseID)
        }

        // Authorization token
        if let authenticationTokenManager = self.authenticationTokenManager {
            let token = try authenticationTokenManager.nextValidToken
            headers.add(name: "authorization", value: token)
        }

        // Device token
        let requestURL = "\(self.configuration.environment.url)/3/device/\(deviceToken)"

        var request = HTTPClientRequest(url: requestURL)
        request.method = .POST
        request.headers = headers
        request.body = .bytes(payload)

        // Attaching all metadata to the logger
        // so that we see it inside AHC as well
        logger[metadataKey: LoggingKeys.notificationPushType] = "\(pushType)"
        logger[metadataKey: LoggingKeys.notificationID] = "\(apnsID?.description ?? "nil")"
        logger[metadataKey: LoggingKeys.notificationExpiration] = "\(expiration?.description ?? "nil")"
        logger[metadataKey: LoggingKeys.notificationPriority] = "\(priority?.description ?? "nil")"
        logger[metadataKey: LoggingKeys.notificationTopic] = "\(topic ?? "nil")"
        logger[metadataKey: LoggingKeys.notificationCollapseID] = "\(collapseID ?? "nil")"

        logger.debug("APNSClient sending notification request")

        let response = try await self.httpClient.execute(
            request,
            deadline: deadline,
            logger: logger
        )

        let apnsID = response.headers.first(name: "apns-id").flatMap { UUID(uuidString: $0) }

        if response.status == .ok {
            logger.trace("APNSClient notification sent")
            return APNSResponse(apnsID: apnsID)
        }

        let body = try await response.body.collect(upTo: 1024)
        let errorResponse = try responseDecoder.decode(APNSErrorResponse.self, from: body)

        let error = APNSError(
            responseStatus: response.status,
            apnsID: apnsID,
            reason: .init(_reason: .init(rawValue: errorResponse.reason)),
            timestamp: errorResponse.timestampInSeconds.flatMap { Date(timeIntervalSince1970: $0) },
            file: file,
            line: line
        )

        logger.debug("APNSClient sending notification failed")

        throw error
    }
}

