//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2020 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// This structure provides the data structure for an APNS Alert
public struct APNSwiftAlert: Codable {
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
     - Parameter title: The title to be displayed to the user.
     - Parameter subtitle: The subtitle to be displayed to the user.
     - Parameter body: The body of the push notification.
     - Parameter titleLocKey: The key to a title string in the Localizable.strings file for the current
     localization.
     - Parameter titleLocArgs: Variable string values to appear in place of the format specifiers in
     title-loc-key.
     - Parameter actionLocKey: The string is used as a key to get a localized string in the current localization
     to use for the right button’s title instead of “View”.
     - Parameter locKey: A key to an alert-message string in a Localizable.strings file for the current
     localization (which is set by the user’s language preference).
     - Parameter locArgs: Variable string values to appear in place of the format specifiers in loc-key.
     - Parameter launchImage: The filename of an image file in the app bundle, with or without the filename
     extension.

     For more information see:
     [Payload Key Reference](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html#)
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
