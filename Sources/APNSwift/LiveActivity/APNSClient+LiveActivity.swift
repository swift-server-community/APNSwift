//
//  APNSClient+LiveActivity.swift
//  PushSender
//
//  Created by csms on 20/09/2022.
//

import NIOCore
import Logging

extension APNSClient {
    /// Sends a live activity notification.
    ///
    /// - Parameters:
    ///   - notification: The notification to send.
    ///
    ///   - activityPushToken: The hexadecimal bytes use to send live activity notification. Your app receives the bytes for this activity token
    ///    from `pushTokenUpdates` async property of a live activity.
    ///
    ///   - deadline: Point in time by which sending the notification to APNs must complete.
    ///
    ///   - logger: The logger to use for sending this notification.
    @discardableResult
    @inlinable
    public func sendLiveActivityNotification<ContentState: Encodable>(
        _ notification: APNSLiveActivityNotification<ContentState>,
        activityPushToken: String,
        deadline: NIODeadline,
        logger: Logger = _noOpLogger
    ) async throws -> APNSResponse {
        return try await self.send(
            payload: notification,
            deviceToken: activityPushToken,
            pushType: .liveactivity,
            apnsID: notification.apnsID,
            expiration: notification.expiration,
            priority: notification.priority,
            topic: notification.topic,
            deadline: deadline,
            logger: logger
        )
    }
}

