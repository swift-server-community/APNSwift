//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2019 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import NIO
import NIOHTTP1
import NIOHTTP2

/// The class provides the HTTP2 interface to Swift NIO 2
internal final class APNSwiftRequestEncoder: ChannelOutboundHandler {
    /// See `ChannelOutboundHandler.OutboundIn`.
    typealias OutboundIn = ByteBuffer

    /// See `ChannelOutboundHandler.OutboundOut`.
    typealias OutboundOut = HTTPClientRequestPart

    let configuration: APNSwiftConfiguration
    var bearerToken: String?
    let deviceToken: String
    let priority: Int?
    let expiration: Date?
    let collapseIdentifier: String?
    let topic: String?
    let pushType: APNSwiftConnection.PushType?
    
    
    init(deviceToken: String, configuration: APNSwiftConfiguration, bearerToken: String?, pushType: APNSwiftConnection.PushType, expiration: Date?, priority: Int?, collapseIdentifier: String?, topic: String?) {
        self.configuration = configuration
        self.bearerToken = bearerToken
        self.deviceToken = deviceToken
        self.expiration = expiration
        self.priority = priority
        self.collapseIdentifier = collapseIdentifier
        self.topic = topic
        self.pushType = pushType
    }
    
    convenience init(deviceToken: String, configuration: APNSwiftConfiguration, bearerToken: String, expiration: Date?, priority: Int?, collapseIdentifier: String?, topic: String? = nil) {
        self.init(deviceToken: deviceToken, configuration: configuration, bearerToken: bearerToken, pushType: .alert, expiration: expiration, priority: priority, collapseIdentifier: collapseIdentifier, topic: topic)
        
    }

    /// See `ChannelOutboundHandler.write(context:data:promise:)`.
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let buffer: ByteBuffer = unwrapOutboundIn(data)
        var reqHead = HTTPRequestHead(version: .init(major: 2, minor: 0), method: .POST, uri: "/3/device/\(deviceToken)")
        reqHead.headers.add(name: "content-type", value: "application/json")
        reqHead.headers.add(name: "user-agent", value: "APNS/swift-nio")
        reqHead.headers.add(name: "content-length", value: buffer.readableBytes.description)
        if let notificationSpecificTopic = self.topic {
            reqHead.headers.add(name: "apns-topic", value: notificationSpecificTopic)
        } else {
            reqHead.headers.add(name: "apns-topic", value: configuration.topic)
        }
        
        if let priority = self.priority {
            reqHead.headers.add(name: "apns-priority", value: String(priority))
        }
        if let epochTime = self.expiration?.timeIntervalSince1970 {
            reqHead.headers.add(name: "apns-expiration", value: String(Int(epochTime)))
        }
        if let collapseId = self.collapseIdentifier {
            reqHead.headers.add(name: "apns-collapse-id", value: collapseId)
        }
        if let pushType = self.pushType {
            reqHead.headers.add(name: "apns-push-type", value: pushType.rawValue)
        }
        reqHead.headers.add(name: "host", value: configuration.url.host!)
        // Only use token auth if bearer token is present.
        if let bearerToken = self.bearerToken {
            reqHead.headers.add(name: "authorization", value: "bearer \(bearerToken)")
        }

        context.write(wrapOutboundOut(.head(reqHead))).cascadeFailure(to: promise)
        context.write(wrapOutboundOut(.body(.byteBuffer(buffer)))).cascadeFailure(to: promise)
        context.write(wrapOutboundOut(.end(nil)), promise: promise)
    }
}
