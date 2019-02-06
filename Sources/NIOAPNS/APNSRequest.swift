//
//  APNSRequest.swift
//  CNIOAtomics
//
//  Created by Kyle Browning on 2/1/19.
//

import NIO
import NIOHTTP1
import NIOHTTP2

public struct APNSRequest: Codable {
    public let aps: Aps
    public let custom: [String: String]?
    public init(aps: Aps, custom: [String: String]?) {
        self.aps = aps
        self.custom = custom
    }
}

public struct Aps: Codable {
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
