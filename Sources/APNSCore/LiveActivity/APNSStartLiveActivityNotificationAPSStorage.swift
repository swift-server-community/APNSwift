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

struct APNSStartLiveActivityNotificationAPSStorage<Attributes: Encodable & Sendable, ContentState: Encodable & Sendable>:
    Encodable & Sendable
{
    enum CodingKeys: String, CodingKey {
        case timestamp = "timestamp"
        case event = "event"
        case contentState = "content-state"
        case staleDate = "stale-date"
        case alert = "alert"
        case attributes = "attributes"
        case attributesType = "attributes-type"
    }

    var timestamp: Int
    var event: String = "start"
    var contentState: ContentState
    var staleDate: Int?
    var alert: APNSAlertNotificationContent
    var attributes: Attributes
    var attributesType: String

    init(
        timestamp: Int,
        contentState: ContentState,
        staleDate: Int?,
        alert: APNSAlertNotificationContent,
        attributes: Attributes,
        attributesType: String
    ) {
        self.timestamp = timestamp
        self.contentState = contentState
        self.staleDate = staleDate
        self.alert = alert
        self.attributes = attributes
        self.attributesType = attributesType
    }
}
