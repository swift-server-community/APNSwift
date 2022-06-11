//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2019-2020 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import Logging
import NIO

public protocol APNSwiftClientProtocol {
    func send(
        rawBytes payload: ByteBuffer,
        pushType: APNSwiftClient.PushType,
        to deviceToken: String,
        on environment: APNSwiftConfiguration.Environment?,
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        apnsID: UUID?
    ) async throws
}
