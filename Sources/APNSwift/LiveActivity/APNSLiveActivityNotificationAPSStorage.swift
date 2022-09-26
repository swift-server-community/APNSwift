//
//  APNSLiveActivityNotificationAPSStorage.swift
//  PushSender
//
//  Created by csms on 20/09/2022.
//

import Foundation

struct APNSLiveActivityNotificationAPSStorage<ContentState: Encodable>: Encodable {
    enum CodingKeys: String, CodingKey {
        case timestamp = "timestamp"
        case event = "event"
        case contentState = "content-state"

    }

    var timestamp: Int
    var event: String
    var contentState: ContentState

    init(
        timestamp: Int,
        event: String,
        contentState: ContentState
    ) {
        self.timestamp = timestamp
        self.event = event
        self.contentState = contentState
    }
}
