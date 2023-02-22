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

/// A sound to play for an alert notification.
public struct APNSAlertNotificationSound: Encodable, Hashable, Sendable {
    internal enum Configuration: Hashable {
        case systemSound
        case fileName(String)
        case critical(fileName: String, volume: Double)
    }

    internal enum CriticalCodingKeys: String, CodingKey {
        case critical
        case name
        case volume
    }

    internal var configuration: Configuration

    /// Plays the default system sound.
    public static let `default` = Self(configuration: .systemSound)

    /// Plays a sound file with the given name in your app's main bundle or
    /// in the `Library/Sounds` folder of your app's container directory.
    ///
    /// - Important: For `critical` alerts use the ``APNSAlertNotificationSound.critical`` method instead.
    ///
    /// - Parameters:
    ///   - fileName: The file name of the sound file.
    public static func fileName(_ fileName: String) -> Self {
        Self(configuration: .fileName(fileName))
    }

    /// Plays a sound file with the given name for critical alerts. The file needs to be in your app's main bundle or
    /// in the `Library/Sounds` folder of your app's container directory.
    ///
    /// - Parameters:
    ///   - fileName: The file name of the sound file.
    ///   - volume: The volume for the critical alert’s sound. Set this to a value between 0 (silent) and 1 (full volume).
    public static func critical(fileName: String, volume: Double) -> Self {
        precondition(volume >= 0 && volume <= 1, "The volume can only be between 0 and 1")

        return Self(configuration: .critical(fileName: fileName, volume: volume))
    }

    public func encode(to encoder: Encoder) throws {
        switch self.configuration {
        case .systemSound:
            var container = encoder.singleValueContainer()
            try container.encode("default")
        case .fileName(let fileName):
            var container = encoder.singleValueContainer()
            try container.encode(fileName)
        case .critical(let fileName, let volume):
            var container = encoder.container(keyedBy: CriticalCodingKeys.self)
            try container.encode(1, forKey: .critical)
            try container.encode(fileName, forKey: .name)
            try container.encode(volume, forKey: .volume)
        }
    }
}
