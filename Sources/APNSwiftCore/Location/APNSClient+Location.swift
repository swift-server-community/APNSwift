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
    /// Sends a location request notification to APNs.
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
    func sendLocationNotification(
        _ notification: APNSLocationNotification,
        deviceToken: String,
        deadline: Duration,
        logger: Logger = _noOpLogger
    ) async throws -> APNSResponse {
        try await self.send(
            // This is just to make the compiler work
            payload: Int?.none,
            deviceToken: deviceToken,
            pushType: .location,
            expiration: .none, // TODO: Figure out if expiration has any impact here
            priority: notification.priority,
            topic: notification.topic,
            deadline: deadline,
            logger: logger
        )
    }
}
