//
//  APNSRequest.swift
//  CNIOAtomics
//
//  Created by Kyle Browning on 2/1/19.
//

import NIO
import NIOHTTP1
import NIOHTTP2

public protocol APNSNotificationProtocol: Codable {
    var aps: APSPayload { get }
}

public struct APNSNotification: APNSNotificationProtocol {
    public var aps: APSPayload
    public init(aps: APSPayload) {
        self.aps = aps
    }
}

public struct APSPayload: Codable {
    public let badge: Int?
    public let category: String?
    public let alert: Alert
    public init (alert: Alert, category: String?, badge: Int?) {
        self.alert = alert
        self.category = category
        self.badge = badge
    }
}

public struct Alert: Codable {
    public let title: String?
    public let subtitle: String?
    public let body: String?
    public init(title: String?, subtitle: String?, body: String?) {
        self.title = title
        self.subtitle = subtitle
        self.body = body
    }
}
