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
import Foundation
import Logging
import NIOCore
import NIOFoundationCompat

public final class APNSClient {

    private let configuration: APNSConfiguration
    private let bearerTokenFactory: APNSBearerTokenFactory
    private let httpClient: HTTPClient

    internal let jsonEncoder = JSONEncoder()
    internal let jsonDecoder = JSONDecoder()

    private var logger: Logger? {
        configuration.logger
    }

    /// APNSClient manages the connection and sending of push notifications to Apple's servers
    ///
    /// - Parameter configuration: `APNSConfiguration` contains various values the client will need.
    public init(
        configuration: APNSConfiguration
    ) {
        self.configuration = configuration
        self.bearerTokenFactory = APNSBearerTokenFactory(
            authenticationConfig: configuration.authenticationConfig,
            logger: configuration.logger
        )
        self.httpClient = HTTPClient(
            eventLoopGroupProvider: configuration.eventLoopGroupProvider.httpClientValue
        )
    }

    /// Shuts down the connections
    public func shutdown() async throws {
        try await httpClient.shutdown()
    }

    /// This method sends a raw payload to Apple, since it is raw, use this with caution as requests may fail
    /// - Parameters:
    ///   - payload: The APS payload in ByteBuffer form
    ///   - pushType: The push type, ie, alert, mdm, voip, etc
    ///   - deviceToken: A device token which will receive the push
    ///   - environment: An optional environment to override for this push
    ///   - expiration: The date at which the notification is no longer valid
    ///   - priority: The priority of the notification. If you omit this header, APNs sets the notification priority to 10
    ///   - collapseIdentifier: An identifier you use to coalesce multiple notifications into a single notification for the user
    ///   - topic: An optional topic to override for this push
    ///   - apnsID: A canonical UUID that is the unique ID for the notification
    ///
    ///   For more information see: [Sending Notification Requests To APNs](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns)
    public func send(
        rawBytes payload: ByteBuffer,
        pushType: APNSClient.PushType,
        to deviceToken: String,
        on environment: APNSConfiguration.Environment?,
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        apnsID: UUID?
    ) async throws {

        let topic = topic ?? configuration.topic
        let urlBase: String =
            environment?.url.absoluteString ?? configuration.environment.url.absoluteString

        var request = HTTPClientRequest(url: "\(urlBase)/3/device/\(deviceToken)")
        request.method = .POST
        request.headers.add(name: "content-type", value: "application/json")
        request.headers.add(name: "user-agent", value: "APNS/swift-nio")
        request.headers.add(name: "content-length", value: "\(payload.readableBytes)")
        request.headers.add(name: "apns-topic", value: topic)
        request.headers.add(name: "apns-push-type", value: pushType.rawValue)
        request.headers.add(name: "host", value: urlBase)

        if let priority = priority {
            request.headers.add(name: "apns-priority", value: String(priority))
        }

        if let epochTime = expiration?.timeIntervalSince1970 {
            request.headers.add(name: "apns-expiration", value: String(Int(epochTime)))
        }

        if let collapseId = collapseIdentifier {
            request.headers.add(name: "apns-collapse-id", value: collapseId)
        }

        let bearerToken = try await bearerTokenFactory.getCurrentBearerToken()

        request.headers.add(name: "authorization", value: "bearer \(bearerToken)")

        if let apnsID = apnsID {
            request.headers.add(name: "apns-id", value: apnsID.uuidString.lowercased())
        }

        request.body = .bytes(payload)

        logger?.debug("APNS request - executing")

        let response = try await httpClient.execute(
            request,
            timeout: configuration.timeout ?? .seconds(30)
        )
        logger?.debug("APNS request - finished - \(response.status)")
        if response.status != .ok {
            let body = try await response.body.collect(upTo: 1024 * 1024)

            let error = try jsonDecoder.decode(APNSError.ResponseStruct.self, from: body)
            logger?.warning("APNS request - failed - \(error.reason)")
            throw APNSError.ResponseError.badRequest(error.reason)
        }
    }
}

extension APNSClient {
    public enum PushType: String {
        case alert
        case background
        case mdm
        case voip
        case fileprovider
        case complication
    }
}

extension APNSClient {

    /**
     APNSClient send method. Sends a notification to the desired deviceToken.
     - Parameter payload: the alert to send.
     - Parameter pushType: push type of the notification.
     - Parameter deviceToken: device token to send alert to.
     - Parameter encoder: customer JSON encoder if needed.
     - Parameter expiration: a date that the notification expires.
     - Parameter priority: priority to send the notification with.
     - Parameter collapseIdentifier: a collapse identifier to use for grouping notifications
     - Parameter topic: the bundle identifier that this notification belongs to.

     For more information see:
     [Retrieve Your App's Device Token](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns#2942135)
     ### Usage Example: ###
     ```
     let apns = APNSClient()
     let expiry = Date().addingTimeInterval(5)
     try apns.send(notification, pushType: .alert, to: "b27a07be2092c7fbb02ab5f62f3135c615e18acc0ddf39a30ffde34d41665276", with: JSONEncoder(), expiration: expiry, priority: 10, collapseIdentifier: "huro2").wait()
     ```
     */
    public func send(
        _ alert: APNSAlert,
        pushType: APNSClient.PushType = .alert,
        to deviceToken: String,
        on environment: APNSConfiguration.Environment? = nil,
        with encoder: JSONEncoder = JSONEncoder(),
        expiration: Date? = nil,
        priority: Int? = nil,
        collapseIdentifier: String? = nil,
        topic: String? = nil,
        apnsID: UUID? = nil
    ) async throws {
        try await self.send(
            APNSPayload(alert: alert),
            pushType: pushType,
            to: deviceToken,
            on: environment,
            with: encoder,
            expiration: expiration,
            priority: priority,
            collapseIdentifier: collapseIdentifier,
            topic: topic,
            apnsID: apnsID
        )
    }

    /**
     APNSClient send method. Sends a notification to the desired deviceToken.
     - Parameter payload: the payload to send.
     - Parameter pushType: push type of the notification.
     - Parameter deviceToken: device token to send alert to.
     - Parameter encoder: customer JSON encoder if needed.
     - Parameter expiration: a date that the notification expires.
     - Parameter priority: priority to send the notification with.
     - Parameter collapseIdentifier: a collapse identifier to use for grouping notifications
     - Parameter topic: the bundle identifier that this notification belongs to.

     For more information see:
     [Retrieve Your App's Device Token](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns#2942135)
     ### Usage Example: ###
     ```
     let apns = APNSClient()
     let expiry = Date().addingTimeInterval(5)
     try apns.send(notification, pushType: .alert, to: "b27a07be2092c7fbb02ab5f62f3135c615e18acc0ddf39a30ffde34d41665276", with: JSONEncoder(), expiration: expiry, priority: 10, collapseIdentifier: "huro2").wait()
     ```
     */
    public func send(
        _ payload: APNSPayload,
        pushType: APNSClient.PushType = .alert,
        to deviceToken: String,
        on environment: APNSConfiguration.Environment? = nil,
        with encoder: JSONEncoder = JSONEncoder(),
        expiration: Date? = nil,
        priority: Int? = nil,
        collapseIdentifier: String? = nil,
        topic: String? = nil,
        apnsID: UUID? = nil
    ) async throws {
        struct BasicNotification: APNSNotification {
            let aps: APNSPayload
        }
        try await self.send(
            BasicNotification(aps: payload),
            pushType: pushType,
            to: deviceToken,
            on: environment,
            with: encoder,
            expiration: expiration,
            priority: priority,
            collapseIdentifier: collapseIdentifier,
            topic: topic,
            apnsID: apnsID
        )
    }

    /**
     APNSClient send method. Sends a notification to the desired deviceToken.
     - Parameter notification: the notification meta data and alert to send.
     - Parameter pushType: push type of the notification.
     - Parameter deviceToken: device token to send alert to.
     - Parameter encoder: customer JSON encoder if needed.
     - Parameter expiration: a date that the notification expires.
     - Parameter priority: priority to send the notification with.
     - Parameter collapseIdentifier: a collapse identifier to use for grouping notifications
     - Parameter topic: the bundle identifier that this notification belongs to.

     For more information see:
     [Retrieve Your App's Device Token](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns#2942135)
     ### Usage Example: ###
     ```
     let apns = APNSClient()
     let expiry = Date().addingTimeInterval(5)
     try apns.send(notification, pushType: .alert, to: "b27a07be2092c7fbb02ab5f62f3135c615e18acc0ddf39a30ffde34d41665276", with: JSONEncoder(), expiration: expiry, priority: 10, collapseIdentifier: "huro2").wait()
     ```
     */
    public func send<Notification>(
        _ notification: Notification,
        pushType: APNSClient.PushType = .alert,
        to deviceToken: String,
        on environment: APNSConfiguration.Environment? = nil,
        with encoder: JSONEncoder? = nil,
        expiration: Date? = nil,
        priority: Int? = nil,
        collapseIdentifier: String? = nil,
        topic: String? = nil,
        apnsID: UUID? = nil
    ) async throws where Notification: APNSNotification {
        let data: Data
        if let encoder = encoder {
            data = try encoder.encode(notification)
        } else {
            data = try jsonEncoder.encode(notification)
        }
        try await self.send(
            raw: data,
            pushType: pushType,
            to: deviceToken,
            on: environment,
            expiration: expiration,
            priority: priority,
            collapseIdentifier: collapseIdentifier,
            topic: topic,
            apnsID: apnsID
        )
    }

    /// This is to be used with caution. APNSwift cannot guarantee delivery if you do not have the correct payload.
    /// For more information see: [Creating APN Payload](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html)
    public func send<Bytes>(
        raw payload: Bytes,
        pushType: APNSClient.PushType = .alert,
        to deviceToken: String,
        on environment: APNSConfiguration.Environment? = nil,
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        apnsID: UUID? = nil
    ) async throws
    where Bytes: Collection, Bytes.Element == UInt8 {
        var buffer = ByteBufferAllocator().buffer(capacity: payload.count)
        buffer.writeBytes(payload)
        try await self.send(
            rawBytes: buffer,
            pushType: pushType,
            to: deviceToken,
            on: environment,
            expiration: expiration,
            priority: priority,
            collapseIdentifier: collapseIdentifier,
            topic: topic,
            apnsID: apnsID
        )
    }
}
