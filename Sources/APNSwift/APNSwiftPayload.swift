//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2019-2020 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// This structure provides the data structure for an APNS Payload
public struct APNSwiftPayload: Encodable {
    public let alert: APNSwift.APNSwiftAlert?
    public let badge: Int?
    public let sound: APNSwift.APNSwiftSoundType?
    public let contentAvailable: Int?
    public let mutableContent: Int?
    public let category: String?
    public let threadID: String?

    public init(alert: APNSwift.APNSwiftAlert? = nil, badge: Int? = nil, sound: APNSwift.APNSwiftSoundType? = nil, hasContentAvailable: Bool = false, hasMutableContent: Bool = false, category: String? = nil, threadID: String? = nil) {
        self.alert = alert
        self.badge = badge
        self.sound = sound
        self.contentAvailable = hasContentAvailable ? 1 : 0
        self.mutableContent = hasMutableContent ? 1 : 0
        self.category = category
        self.threadID = threadID
    }

    enum CodingKeys: String, CodingKey {
        case alert
        case badge
        case sound
        case contentAvailable = "content-available"
        case mutableContent = "mutable-content"
        case category
        case threadID = "thread-id"
    }
}
