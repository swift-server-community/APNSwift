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

import struct Foundation.UUID

/// The response of a successful APNs request.
public struct APNSResponse: Hashable {
    /// The same value as the `apnsID` send in the request.
    ///
    /// Use this value to identify the notification. If you don’t specify an `apnsID` in your request,
    /// APNs creates a new `UUID` and returns it in this header.
    public var apnsID: UUID?

    /// Initializes a new ``APNSResponse``.
    ///
    /// - Parameter apnsID: The same value as the `apnsID` send in the request.
    public init(apnsID: UUID? = nil) {
        self.apnsID = apnsID
    }
}
