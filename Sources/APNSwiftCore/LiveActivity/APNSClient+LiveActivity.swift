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

import Logging

extension APNSClient {
    /// Sends a live activity notification.
    ///
    /// - Parameters:
    ///   - notification: The notification to send.
    ///
    ///   - deviceToken: The hexadecimal bytes use to send live activity notification. Your app receives the bytes for this activity token
    ///    from `pushTokenUpdates` async property of a live activity.
    ///
    ///   - deadline: Point in time by which sending the notification to APNs must complete.
    ///
    ///   - logger: The logger to use for sending this notification.
    @discardableResult
    @inlinable
    public func sendLiveActivityNotification<ContentState: Encodable>(
        _ notification: APNSLiveActivityNotification<ContentState>,
        deviceToken: String,
        deadline: Duration,
        logger: Logger = _noOpLogger
    ) async throws -> APNSResponse {
        return try await self.send(
            payload: notification,
            deviceToken: deviceToken,
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

