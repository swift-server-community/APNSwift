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

/// A struct to indicate the importance and delivery timing of a notification
public struct APNSAlertNotificationInterruptionLevel: Encodable, Hashable, Sendable {
    internal var rawValue: String

    /// The system adds the notification to the notification list without lighting up the screen or playing a sound.
    public static let passive = Self(rawValue: "passive")

    /// The system presents the notification immediately, lights up the screen, and can play a sound.
    public static let active = Self(rawValue: "active")

    /// The system presents the notification immediately, lights up the screen, and can play a sound,
    /// but won’t break through system notification controls.
    public static let timeSensitive = Self(rawValue: "time-sensitive")

    /// The system presents the notification immediately, lights up the screen, and bypasses the mute switch to play a sound.
    public static let critical = Self(rawValue: "critical")

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}
