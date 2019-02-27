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

public struct APNSConfiguration {
    public let keyIdentifier: String
    public let teamIdentifier: String
    public let signingMode: SigningMode
    public let topic: String
    public let environment: APNSEnvironment
    public let sslContext: NIOOpenSSL.SSLContext

    public var url: URL {
        get {
            switch environment {
            case .production:
                return URL(string: "https://api.push.apple.com")!
            case .sandbox:
                return URL(string: "https://api.development.push.apple.com")!
            }
        }
    }
    
    public init(keyIdentifier: String, teamIdentifier: String, signingMode: SigningMode, topic: String, environment: APNSEnvironment) {
        self.keyIdentifier = keyIdentifier
        self.teamIdentifier = teamIdentifier
        self.topic = topic
        self.signingMode = signingMode
        self.environment = environment
        self.sslContext = try! SSLContext(configuration: TLSConfiguration.forClient(applicationProtocols: ["h2"]))
    }
}
