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

/// The APNs broadcast environment.
public struct APNSBroadcastEnvironment: Sendable {
    /// The production APNs broadcast environment.
    public static let production = Self(url: "https://api-manage-broadcast.push.apple.com", port: 2196)

    /// The development/sandbox APNs broadcast environment.
    public static let development = Self(url: "https://api-manage-broadcast.sandbox.push.apple.com", port: 2195)

    /// Creates an APNs broadcast environment with a custom URL.
    ///
    /// - Note: This is mostly used for testing purposes.
    public static func custom(url: String, port: Int = 443) -> Self {
        Self(url: url, port: port)
    }

    /// The environment's URL.
    public let url: String

    /// The environment's port.
    public let port: Int
}
