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
import struct Foundation.Data

struct APNSLiveActivityNotificationAPSStorage<ContentState: Encodable & Hashable & Sendable>:
    Encodable, Sendable, Hashable
{
    enum CodingKeys: String, CodingKey {
        case timestamp = "timestamp"
        case event = "event"
        case contentState = "content-state"
        case dismissalDate = "dismissal-date"
        case attributesType = "attributes-type"
        case attributesContent = "attributes"
    }

    var timestamp: Int
    var event: String
    var attributesType: String?
    var attributesContent: ContentState?
    var contentState: ContentState
    var dismissalDate: Int?

    init(
        timestamp: Int,
        event: String,
        attributes: APNSLiveActivityNotificationEventStart<ContentState>.Attributes?,
        contentState: ContentState,
        dismissalDate: Int?
    ) {
        self.timestamp = timestamp
        self.event = event
        self.attributesType = attributes?.type
        self.attributesContent = attributes?.state
        self.contentState = contentState
        self.dismissalDate = dismissalDate
    }
}
