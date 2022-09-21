//
//  APNSLiveActivityNotificationAPSStorage.swift
//  PushSender
//
//  Created by csms on 20/09/2022.
//

import Foundation

public struct APNSLiveActivityNotificationAPSStorage<ContentState: Encodable>: Encodable {
    enum CodingKeys: String, CodingKey {
        case timestamp = "timestamp"
        case event = "event"
        case contentState = "content-state"

    }

    public var timestamp: Int
    public var event: String
    public var contentState: ContentState

    public init(
        timestamp: Int,
        event: String,
        contentState: ContentState
    ) {
        self.timestamp = timestamp
        self.event = event
        self.contentState = contentState
    }
}
