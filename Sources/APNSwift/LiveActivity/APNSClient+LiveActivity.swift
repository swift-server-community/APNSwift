//
//  APNSClient+LiveActivity.swift
//  PushSender
//
//  Created by csms on 20/09/2022.
//

import NIOCore
import Logging

extension APNSClient {
    /// Sends an alert notification to APNs.
    ///
    /// - Parameters:
    ///   - notification: The notification to send.
    ///
    ///   - deviceToken: The hexadecimal bytes that identify the user’s device. Your app receives the bytes for this device token
    ///    when registering for remote notifications.
    ///
    ///   - deadline: Point in time by which sending the notification to APNs must complete.
    ///
    ///   - logger: The logger to use for sending this notification.
    @discardableResult
    @inlinable
    public func sendLiveActivityNotification<Payload: Encodable>(
        _ notification: APNSLiveActivityNotification<Payload>,
        deviceToken: String,
        deadline: NIODeadline,
        logger: Logger = _noOpLogger
    ) async throws -> APNSResponse {
        return try await self.send(
            payload: notification,
            deviceToken: deviceToken,
            pushType: .liveactivity,
            apnsID: notification.apnsID,
            expiration: notification.expiration,
            priority: notification.priority,
            topic: notification.topic + ".push-type.liveactivity",
            deadline: deadline,
            logger: logger
        )
    }
}

