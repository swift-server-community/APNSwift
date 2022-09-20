//
//  APNSLiveActivityNotification.swift
//  PushSender
//
//  Created by csms on 20/09/2022.
//

import struct Foundation.UUID

/// An alert notification.
///
/// - Important: Your dynamic payload will get encoded to the root of the JSON payload that is send to APNs.
/// It is **important** that you do not encode anything with the key `aps`.
public struct APNSLiveActivityNotification<ContentState: Encodable>: Encodable {
    enum CodingKeys: CodingKey {
        case aps
    }

    /// The fixed content to indicate that this is a background notification.
    private var aps: APNSLiveActivityNotificationAPSStorage<ContentState>

 
    /// A canonical UUID that identifies the notification. If there is an error sending the notification,
    /// APNs uses this value to identify the notification to your server. The canonical form is 32 lowercase hexadecimal digits,
    /// displayed in five groups separated by hyphens in the form 8-4-4-4-12. An example UUID is as follows:
    /// `123e4567-e89b-12d3-a456-42665544000`.
    ///
    /// If you omit this, a new UUID is created by APNs and returned in the response.
    public var apnsID: UUID?

    /// The date when the notification is no longer valid and can be discarded. If this value is not `none`,
    /// APNs stores the notification and tries to deliver it at least once,
    /// repeating the attempt as needed if it is unable to deliver the notification the first time.
    /// If the value is `immediately`, APNs treats the notification as if it expires immediately
    /// and does not store the notification or attempt to redeliver it.
    public var expiration: APNSNotificationExpiration

    /// The priority of the notification.
    public var priority: APNSPriority

    /// The topic for the notification. In general, the topic is your app’s bundle ID/app ID.
    public var topic: String

    /// Initializes a new ``APNSAlertNotification``.
    ///
    /// - Important: Your dynamic payload will get encoded to the root of the JSON payload that is send to APNs.
    /// It is **important** that you do not encode anything with the key `aps`
    ///
    /// - Parameters:
    ///   - expiration: The date when the notification is no longer valid and can be discarded.
    ///   - priority: The priority of the notification.
    ///   - topic: The topic for the notification. In general, the topic is your app’s bundle ID/app ID.
    ///   - apnsID: A canonical UUID that identifies the notification.
    ///   - contentState: Updated content-state on live activity
    ///   - timestamp: Timestamp when sending notification
    ///   - event: event type e.g. update
    public init(
        expiration: APNSNotificationExpiration,
        priority: APNSPriority,
        topic: String,
        apnsID: UUID? = nil,
        contentState: ContentState,
        event: LiveActivityNotificationEvent,
        timestamp: Int
    ) {
        self.aps = APNSLiveActivityNotificationAPSStorage(
            timestamp: timestamp,
            event: event.rawValue,
            contentState: contentState
        )
        self.apnsID = apnsID
        self.expiration = expiration
        self.priority = priority
        self.topic = topic
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // First we encode the user payload since this might use the `aps` key
        // and we override it afterward.
//        try self.payload.encode(to: encoder)
        try container.encode(self.aps, forKey: .aps)
    }
}
