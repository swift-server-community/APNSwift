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

struct APNSLiveActivityNotificationAPSStorage<ContentState: Encodable>: Encodable {
    enum CodingKeys: String, CodingKey {
        case timestamp = "timestamp"
        case event = "event"
        case contentState = "content-state"
        case dismissalDate = "dismissal-date"
        case attributesType = "attributes-type"
        case attributesContent = "attributes"
        case alert = "alert"
    }

    var timestamp: Int
    var event: String
    var attributesType: String?
    var attributesContent: ContentState?
    var contentState: ContentState
    var dismissalDate: Int?
    var alert: APNSAlertNotificationContent?

    init(
        timestamp: Int,
        event: APNSLiveActivityNotificationEvent,
				startOptions: APNSLiveActivityNotificationEventStartOptions<ContentState>?,
        contentState: ContentState,
        dismissalDate: Int?
    ) {
        self.timestamp = timestamp
        self.contentState = contentState
        self.dismissalDate = dismissalDate
        self.event = event.rawValue

				if let startOptions {
					self.attributesType = startOptions.attributeType
					self.attributesContent = startOptions.attributes
					self.alert = startOptions.alert
        }
    }
}
