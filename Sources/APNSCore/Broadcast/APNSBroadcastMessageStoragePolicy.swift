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

/// The storage policy for broadcast channel messages.
public enum APNSBroadcastMessageStoragePolicy: Int, Codable, Sendable {
    /// No messages are stored.
    case noMessageStored = 0
    /// Only the most recent message is stored.
    case mostRecentMessageStored = 1
}
