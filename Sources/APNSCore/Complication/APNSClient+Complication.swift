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
    /// Sends a complication notification to APNs.
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
    public func sendComplicationNotification<Payload: Encodable>(
        _ notification: APNSComplicationNotification<Payload>,
        deviceToken: String,
        deadline: Duration,
        logger: Logger = _noOpLogger
    ) async throws -> APNSResponse {
        let request = APNSRequest(
            message: notification,
            deviceToken: deviceToken,
            pushType: .complication,
            expiration: notification.expiration,
            priority: notification.priority,
            apnsID: notification.apnsID,
            topic: notification.topic
        )
        return try await send(request)
    }
}
