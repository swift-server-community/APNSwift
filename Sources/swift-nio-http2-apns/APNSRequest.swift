//
//  APNSRequest.swift
//  CNIOAtomics
//
//  Created by Kyle Browning on 2/1/19.
//

import NIO
import NIOHTTP1
import NIOHTTP2

struct APNSRequest: Codable {
    let aps: Aps
    let custom: [String: String]?
}

struct Aps: Codable {
    let badge: Int?
    let category: String?
    let alert: Alert
}

struct Alert: Codable {
    let title: String?
    let subtitle: String?
    let body: String?
}
