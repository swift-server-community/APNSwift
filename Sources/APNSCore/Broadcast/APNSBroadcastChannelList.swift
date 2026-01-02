//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2024 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Represents the list of all broadcast channel IDs.
public struct APNSBroadcastChannelList: Codable, Sendable {
    /// The array of channel IDs.
    public let channels: [String]

    public init(channels: [String]) {
        self.channels = channels
    }
}
