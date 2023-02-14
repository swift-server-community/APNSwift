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

import Dispatch
import struct Foundation.Date
import struct Foundation.UUID
import Foundation.NSJSONSerialization
import Logging


/// A client to talk with the Apple Push Notification services.
public final class APNSClient<Client: APNSHttpClient> {
    /// The configuration used by the ``APNSClient``.
    private let configuration: APNSClientConfiguration
    /// The ``APNSHttpClient`` used by the ``APNSClient``.
    public let httpClient: Client
    /// The logger used by the ``APNSClient``.
    private let backgroundActivityLogger: Logger
    /// The authentication token manager.
    private let authenticationTokenManager: APNSAuthenticationTokenManager?
    /// The decoder for the responses from APNs.
    private let responseDecoder: JSONDecoder
    /// The encoder for the requests to APNs.
    @usableFromInline
    /* private */ internal let requestEncoder: JSONEncoder
    
    /// Default Headers which will be adapted for each request. This saves some allocations.
    private let defaultRequestHeaders: [String: String] = [
        "content-type": "application/json",
        "user-agent": "APNS/swift-nio"
    ]

    /// Initializes a new ``APNSClient``.
    ///
    /// The client will create an internal ``HTTPClient`` which is used to make requests to APNs.
    /// This ``HTTPClient`` is intentionally internal since both authentication mechanisms are bound to a
    /// single connection and these connections cannot be shared.
    ///
    ///
    /// - Parameters:
    ///   - configuration: The configuration used by the ``APNSClient``.
    ///   - responseDecoder: The decoder for the responses from APNs.
    ///   - requestEncoder: The encoder for the requests to APNs.
    ///   - backgroundActivityLogger: The logger used by the ``APNSClient``.
    public init(
        configuration: APNSClientConfiguration,
        responseDecoder: JSONDecoder,
        requestEncoder: JSONEncoder,
        backgroundActivityLogger: Logger = _noOpLogger
    ) {
        self.configuration = configuration
        self.backgroundActivityLogger = backgroundActivityLogger
        self.responseDecoder = responseDecoder
        self.requestEncoder = requestEncoder


        switch configuration.authenticationMethod.method {
        case .jwt(let privateKey, let teamIdentifier, let keyIdentifier):
            self.authenticationTokenManager = APNSAuthenticationTokenManager(
                privateKey: privateKey,
                teamIdentifier: teamIdentifier,
                keyIdentifier: keyIdentifier,
                logger: backgroundActivityLogger
            )
//        case .tls:
//            self.authenticationTokenManager = nil
        }
        
        self.httpClient = Client(
            configuration: configuration,
            backgroundActivityLogger: backgroundActivityLogger
        )
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
        deadline: Duration,
        logger: Logger = _noOpLogger
    ) async throws -> APNSResponse {
        return try await self.send(
            payload: payload,
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
    public func send<Payload: Encodable>(
        payload: Payload?,
        deviceToken: String,
        pushType: String,
        apnsID: UUID? = nil,
        expiration: Int? = nil,
        priority: Int? = nil,
        topic: String? = nil,
        collapseID: String? = nil,
        deadline: Duration,
        logger: Logger = _noOpLogger,
        file: String = #file,
        line: Int = #line
    ) async throws -> APNSResponse {
        var logger = logger
        var headers = self.defaultRequestHeaders

        /// Push type
        headers["apns-push-type"] = pushType

        /// APNS ID
        if let apnsID = apnsID {
            headers["apns-id"] = apnsID.uuidString.lowercased()
        }

        /// Expiration
        if let expiration = expiration {
            headers["apns-expiration"] = String(expiration)
        }

        /// Priority
        if let priority = priority {
            headers["apns-priority"] = String(priority)
        }

        /// Topic
        if let topic = topic {
            headers["apns-topic"] = topic
        }

        /// Collapse ID
        if let collapseID = collapseID {
            headers["apns-collapse-id"] = collapseID
        }

        // Authorization token
        if let authenticationTokenManager = self.authenticationTokenManager {
            headers["authorization"] = try authenticationTokenManager.nextValidToken
        }

        // Device token
        let requestURL = "\(self.configuration.environment.url)/3/device/\(deviceToken)"

        // Attaching all metadata to the logger
        // so that we see it inside AHC as well
        logger[metadataKey: LoggingKeys.notificationPushType] = "\(pushType)"
        logger[metadataKey: LoggingKeys.notificationID] = "\(apnsID?.description ?? "nil")"
        logger[metadataKey: LoggingKeys.notificationExpiration] = "\(expiration?.description ?? "nil")"
        logger[metadataKey: LoggingKeys.notificationPriority] = "\(priority?.description ?? "nil")"
        logger[metadataKey: LoggingKeys.notificationTopic] = "\(topic ?? "nil")"
        logger[metadataKey: LoggingKeys.notificationCollapseID] = "\(collapseID ?? "nil")"

        logger.debug("APNSClient sending notification request")

        let response = try await httpClient.send(
            payload: payload,
            headers: headers,
            requestURL: requestURL,
            decoder: responseDecoder,
            deadline: deadline,
            logger: logger,
            file: file,
            line: line
        )
        
        logger.trace("APNSClient notification sent")
        
        return response
    }
}

public protocol APNSHttpClient {

    func send<Payload: Encodable>(
        payload: Payload?,
        headers: [String: String],
        requestURL: String,
        decoder: JSONDecoder,
        deadline: Duration,
        logger: Logger,
        file: String,
        line: Int
    ) async throws -> APNSResponse
    
    init(
        configuration: APNSClientConfiguration,
        backgroundActivityLogger: Logger
    )
}
