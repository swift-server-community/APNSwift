//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2022-2020 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// This structure provides the data structure for an APNS Payload
public struct APNSPayload: Codable {
    public let alert: APNSAlert?
    public let badge: Int?
    public let sound: APNSSoundType?
    public let contentAvailable: Int?
    public let mutableContent: Int?
    public let category: String?
    public let threadID: String?
    public let targetContentId: String?
    public let interruptionLevel: InterruptionLevel?
    public let relevanceScore: Float?
    public let filterCriteria: String?

    /// An APNs Push payload provides the properties to send along for a push notification
    ///
    ///  For more information see: [Generating a remote notification](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification)
    /// - Parameters:
    ///   - alert: The information for displaying an alert.
    ///   - badge: The number to display in a badge on your app’s icon.
    ///   - sound: The name of a sound file in your app’s main bundle or in the Library/Sounds folder of your app’s container directory.
    ///   - hasContentAvailable: The background notification flag. To perform a silent background update, specify the value 1 and don’t include the alert, badge, or sound keys in your payload.
    ///   - hasMutableContent: The notification service app extension flag. If the value is 1, the system passes the notification to your notification service app extension before delivery.
    ///   - category: The notification’s type. This string must correspond to the identifier of one of the UNNotificationCategory objects you register at launch time.
    ///   - threadID: An app-specific identifier for grouping related notifications.
    ///   - targetContentId: The identifier of the window brought forward.
    ///   - interruptionLevel: The importance and delivery timing of a notification. The string values “passive”, “active”, “time-sensitive”, or “critical” correspond to the UNNotificationInterruptionLevel enumeration cases.
    ///   - relevanceScore: The relevance score, a number between 0 and 1, that the system uses to sort the notifications from your app.
    public init(
        alert: APNSAlert? = nil,
        badge: Int? = nil,
        sound: APNSSoundType? = nil,
        hasContentAvailable: Bool? = false,
        hasMutableContent: Bool? = false,
        category: String? = nil,
        threadID: String? = nil,
        targetContentId: String? = nil,
        interruptionLevel: InterruptionLevel? = nil,
        relevanceScore: Float? = nil,
        filterCriteria: String? = nil
    ) {

        self.alert = alert
        self.badge = badge
        self.sound = sound
        if let hasContentAvailable = hasContentAvailable {
            self.contentAvailable = hasContentAvailable ? 1 : 0
        } else {
            self.contentAvailable = nil
        }
        if let hasMutableContent = hasMutableContent {
            self.mutableContent = hasMutableContent ? 1 : 0
        } else {
            self.mutableContent = nil
        }
        self.category = category
        self.threadID = threadID
        self.targetContentId = targetContentId
        self.interruptionLevel = interruptionLevel
        self.relevanceScore = relevanceScore
        self.filterCriteria = filterCriteria
    }

    enum CodingKeys: String, CodingKey {
        case alert
        case badge
        case sound
        case contentAvailable = "content-available"
        case mutableContent = "mutable-content"
        case category
        case threadID = "thread-id"
        case targetContentId = "target-content-id"
        case interruptionLevel = "interruption-level"
        case relevanceScore = "relevance-score"
        case filterCriteria = "filter-criteria"
    }

    public enum InterruptionLevel: String, Codable {
        case passive
        case active
        case timeSensitive = "time-sensitive"
        case critical
    }
}
