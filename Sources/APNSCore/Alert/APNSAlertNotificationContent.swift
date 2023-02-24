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

/// The information for displaying an alert.
public struct APNSAlertNotificationContent: Encodable, Sendable {
    public struct StringValue: Encodable, Hashable, Sendable {
        internal enum Configuration: Encodable, Hashable {
            case raw(String)
            case localized(key: String, arguments: [String])
        }

        internal var configuration: Configuration

        /// Sends the raw value to APNs.
        ///
        /// Use this if you are localizing your values from the backend.
        ///
        /// - Parameters:
        ///   - value: The raw string.
        public static func raw(_ value: String) -> Self {
            Self(configuration: .raw(value))
        }

        /// Sends a localization key and arguments.
        ///
        /// - Parameters:
        ///   - key: The key that will be retrieved from your app's `Localizable.strings`. The key *must* contain the name of a key in your strings file.
        ///   - arugments: An array of strings containing replacement values for variables in your `key` string.
        ///   Each %@ character in the string specified by the `key` is replaced by a value from this array.
        ///   The first item in the array replaces the first instance of the %@ character in the string, the second item replaces the second instance, and so on.
        public static func localized(key: String, arguments: [String]) -> Self {
            Self(configuration: .localized(key: key, arguments: arguments))
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.configuration)
        }
    }

    enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case body
        case launchImage = "launch-image"
        case titleLocalizationKey = "title-loc-key"
        case titleLocalizationArguments = "title-loc-args"
        case subtitleLocalizationKey = "subtitle-loc-key"
        case subtitleLocalizationArguments = "subtitle-loc-args"
        case bodyLocalizationKey = "loc-key"
        case bodyLocalizationArguments = "loc-args"
    }

    /// The title of the notification. Apple Watch displays this string in the short look notification interface.
    /// Specify a string that’s quickly understood by the user.
    public var title: StringValue?

    /// Additional information that explains the purpose of the notification.
    public var subtitle: StringValue?

    /// The content of the alert message.
    public var body: StringValue?

    /// The name of the launch image file to display. If the user chooses to launch your app,
    /// the contents of the specified image or storyboard file are displayed instead of your app’s normal launch image.
    public var launchImage: String?

    /// Initializes a new ``APNSAlertNotificationContent``.
    ///
    /// - Parameters:
    ///   - title: The title of the notification.
    ///   - subtitle: Additional information that explains the purpose of the notification.
    ///   - body: The content of the alert message.
    ///   - launchImage: The name of the launch image file to display.
    public init(
        title: APNSAlertNotificationContent.StringValue? = nil,
        subtitle: APNSAlertNotificationContent.StringValue? = nil,
        body: APNSAlertNotificationContent.StringValue? = nil,
        launchImage: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.launchImage = launchImage
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try self.encode(
            value: self.title,
            into: &container,
            rawKey: .title,
            localizedKey: .titleLocalizationKey,
            localizedArgumentsKey: .titleLocalizationArguments
        )
        try self.encode(
            value: self.subtitle,
            into: &container,
            rawKey: .subtitle,
            localizedKey: .subtitleLocalizationKey,
            localizedArgumentsKey: .subtitleLocalizationArguments
        )
        try self.encode(
            value: self.body,
            into: &container,
            rawKey: .body,
            localizedKey: .bodyLocalizationKey,
            localizedArgumentsKey: .bodyLocalizationArguments
        )
        try container.encodeIfPresent(self.launchImage, forKey: .launchImage)
    }

    private func encode(
        value: StringValue?,
        into container: inout KeyedEncodingContainer<CodingKeys>,
        rawKey: KeyedEncodingContainer<CodingKeys>.Key,
        localizedKey: KeyedEncodingContainer<CodingKeys>.Key,
        localizedArgumentsKey: KeyedEncodingContainer<CodingKeys>.Key
    ) throws {
        switch value?.configuration {
        case .raw(let value):
            try container.encode(value, forKey: rawKey)
        case .localized(let key, let arguments):
            try container.encode(key, forKey: localizedKey)
            try container.encode(arguments, forKey: localizedArgumentsKey)
        case .none:
            break
        }
    }
}
