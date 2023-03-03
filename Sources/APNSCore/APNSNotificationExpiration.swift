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

/// A struct representing the different expiration options for a notification.
public struct APNSNotificationExpiration: Encodable, Hashable, Sendable {
    /// The date at which the notification is no longer valid.
    /// This value is a UNIX epoch expressed in seconds (UTC)
    public let expiration: Int?

    /// Omits sending an expiration for APNs. APNs will default to a default value.
    public static let none = Self(expiration: nil)

    /// This tells APNs to not try to redeliver the notification.
    ///
    /// - Important: This does not mean that the notification is delivered immediately. Due to various network conditions
    /// the message might be delivered with some delay.
    public static let immediately = Self(expiration: 0)

    /// This tells APNs that the notification expires at the given date.
    ///
    /// - Important: This does not mean that the notification is delivered until this date. Due to various network conditions
    /// the message might be delivered after the passed date.
    public static func timeIntervalSince1970InSeconds(_ timeInterval: Int) -> Self {
        Self(expiration: timeInterval)
    }
}
