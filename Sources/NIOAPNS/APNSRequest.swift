//
//  APNSRequest.swift
//  CNIOAtomics
//
//  Created by Kyle Browning on 2/1/19.
//

import NIO
import NIOHTTP1
import NIOHTTP2

public protocol APNSNotification: Codable {
    var aps: APSPayload { get }
}

public struct BasicNotification: APNSNotification {
    public var aps: APSPayload
    public init(aps: APSPayload) {
        self.aps = aps
    }
}

/**
 APNS Payload

 [https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html#]: Payload Key Reference
 */
public struct APSPayload: Codable {

    public let alert: Alert?
    public let badge: Int?
    public let sound: String?
    public let contentAvailable: Int?
    public let category: String?
    public let threadID: String?

    public init (alert: Alert? = nil, badge: Int? = nil, sound: String? = nil, contentAvailable: Int? = nil,  category: String? = nil, threadID: String? = nil) {
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


/**
    APNS Alert

    - SeeAlso: `struct APSPayload: Codable`
 */
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
