//
//  APNSConfig.swift
//  swift-nio-http2-apns
//
//  Created by Kyle Browning on 2/5/19.
//

import Foundation
public struct APNSConfig {
    public let keyId: String
    public let teamId: String
    public let privateKeyPath: String
    public let topic: String
}
