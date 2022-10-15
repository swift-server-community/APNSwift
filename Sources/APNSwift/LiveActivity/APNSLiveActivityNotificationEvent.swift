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

public struct APNSLiveActivityNotificationEvent: Hashable {
    
    /// The underlying raw value that is send to APNs.
    @usableFromInline
    internal let rawValue: String
    
    /// Specifies that live activity should be updated
    public static let update = Self(rawValue: "update")
    
    /// Specifies that live activity should be ended
    public static let end = Self(rawValue: "end")
}
