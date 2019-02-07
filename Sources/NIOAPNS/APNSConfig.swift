//
//  APNSConfig.swift
//  swift-nio-http2-apns
//
//  Created by Kyle Browning on 2/5/19.
//

import Foundation
import NIO
import NIOHTTP2
import NIOOpenSSL
import CNIOOpenSSL

public struct APNSConfig {
    public let keyId: String
    public let teamId: String
    public let privateKeyPath: String
    public let topic: String
    public let env: APNSEnv
    public let sslContext: NIOOpenSSL.SSLContext

    public init(keyId: String, teamId: String, privateKeyPath: String, topic: String, env: APNSEnv) {
        self.keyId = keyId
        self.teamId = teamId
        self.privateKeyPath = privateKeyPath
        self.topic = topic
        self.env = env
        self.sslContext = try! SSLContext(configuration: TLSConfiguration.forClient(applicationProtocols: ["h2"]))
    }
    public func getUrl() -> URL {
        switch env {
        case .prod:
            return URL(string: "https://api.push.apple.com")!
        case .sandbox:
            return URL(string: "https://api.development.push.apple.com")!
        }
    }

}
