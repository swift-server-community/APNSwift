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

/// The APNs environment.
public struct APNSEnvironment {
    /// The production APNs environment.
    public static let production = Self(url: "https://api.push.apple.com")

    /// The sandbox APNs environment.
    public static let sandbox = Self(url: "https://api.development.push.apple.com")

    /// Creates an APNs environment with a custom URL.
    ///
    /// - Note: This is mostly used for testing purposes.
    public static func custom(url: String) -> Self {
        Self(url: url)
    }

    /// The environment's URL.
    public let url: String
}
