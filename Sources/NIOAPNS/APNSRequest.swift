//===----------------------------------------------------------------------===//
//
// This source file is part of the NIOApns open source project
//
// Copyright (c) 2019 the NIOApns project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of NIOApns project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIO
import NIOHTTP1
import NIOHTTP2

/// This is a protocol which allows developers to construct their own Notification payload
public protocol APNSNotification: Codable {
    var aps: APSPayload { get }
}
/// This structure is provided as a default basic notification
public struct BasicNotification: APNSNotification {
    public var aps: APSPayload
    public init(aps: APSPayload) {
        self.aps = aps
    }
}

/// This structure provides the data structure for an APNS Payload
public struct APSPayload: Codable {
    public let alert: Alert?
    public let badge: Int?
    public let sound: String?
    public let contentAvailable: Int?
    public let category: String?
    public let threadID: String?

    /**
     Initialize an APSPayload
     - Parameters:
     - alert: The alert which will be display to the user.
     - badge: The number the push notification will bump the apps badge number to.
     - sound: The apps path to a sound file.
     - contentAvailable: When this key is present, the system wakes up your app in the background and
     delivers the notification to its app delegate.
     - category: provide this string to define a category for your app.
     - threadID: Provide a thread value to group notifications.

     More Information
     [https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html#]: Payload Key Reference
     ### Usage Example: ###
     ````
     let alert = ...
     let aps = APSPayload(alert: alert, badge: 1)
     ````
     */
    public init(alert: Alert? = nil, badge: Int? = nil, sound: String? = nil, contentAvailable: Int? = nil, category: String? = nil, threadID: String? = nil) {
        self.alert = alert
        self.badge = badge
        self.sound = sound
        self.contentAvailable = contentAvailable
        self.category = category
        self.threadID = threadID
    }

    enum CodingKeys: String, CodingKey {
        case alert
        case badge
        case sound
        case contentAvailable = "content-available"
        case category
        case threadID = "thread-id"
    }
}

/// This structure provides the data structure for an APNS Alert
public struct Alert: Codable {
    public let title: String?
    public let subtitle: String?
    public let body: String?
    public let titleLocKey: String?
    public let titleLocArgs: [String]?
    public let actionLocKey: String?
    public let locKey: String?
    public let locArgs: [String]?
    public let launchImage: String?

    /**
     This structure provides the data structure for an APNS Alert
     - Parameters:
     - title: The title to be displayed to the user.
     - subtitle: The subtitle to be displayed to the user.
     - body: The body of the push notification.
     - titleLocKey: The key to a title string in the Localizable.strings file for the current
     localization.
     - titleLocArgs: Variable string values to appear in place of the format specifiers in
     title-loc-key.
     - actionLocKey: The string is used as a key to get a localized string in the current localization
     to use for the right button’s title instead of “View”.
     - locKey: A key to an alert-message string in a Localizable.strings file for the current
     localization (which is set by the user’s language preference).
     - locArgs: Variable string values to appear in place of the format specifiers in loc-key.
     - launchImage: The filename of an image file in the app bundle, with or without the filename
     extension.

     For more information
     (https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html#)[Payload Key Reference]
     ### Usage Example: ###
     ````
     let alert = Alert(title: "Hey There", subtitle: "Subtitle", body: "Body")
     ````
     */
    public init(title: String? = nil, subtitle: String? = nil, body: String? = nil,
                titleLocKey: String? = nil, titleLocArgs: [String]? = nil, actionLocKey: String? = nil,
                locKey: String? = nil, locArgs: [String]? = nil, launchImage: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.titleLocKey = titleLocKey
        self.titleLocArgs = titleLocArgs
        self.actionLocKey = actionLocKey
        self.locKey = locKey
        self.locArgs = locArgs
        self.launchImage = launchImage
    }

    enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case body
        case titleLocKey = "title-loc-key"
        case titleLocArgs = "title-loc-args"
        case actionLocKey = "action-loc-key"
        case locKey = "loc-key"
        case locArgs = "loc-args"
        case launchImage = "launch-image"
    }
}
