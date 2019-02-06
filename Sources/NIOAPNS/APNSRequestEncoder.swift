//
//  APNSRequestEncoder.swift
//  CNIOAtomics
//
//  Created by Kyle Browning on 2/1/19.
//

import Foundation
import NIO
import NIOHTTP1
import NIOHTTP2

internal final class APNSRequestEncoder: ChannelOutboundHandler {
    /// See `ChannelOutboundHandler.OutboundIn`.
    typealias OutboundIn = APNSRequest

    /// See `ChannelOutboundHandler.OutboundOut`.
    typealias OutboundOut = HTTPClientRequestPart
    
    public let apnsConfig: APNSConfig
    public let deviceToken: String
    
    init(deviceToken: String, apnsConfig: APNSConfig) {
        self.apnsConfig = apnsConfig
        self.deviceToken = deviceToken
    }

    /// See `ChannelOutboundHandler.write(ctx:data:promise:)`.
    func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let req:APNSRequest = unwrapOutboundIn(data)
        let wrappedRequest = try! JSONEncoder().encode(req)
        var buffer = ByteBufferAllocator().buffer(capacity: wrappedRequest.count)
        buffer.write(bytes: wrappedRequest)
        var reqHead = HTTPRequestHead(version: .init(major: 2, minor: 0), method: .POST, uri: "/3/device/\(deviceToken)")
        reqHead.headers.add(name: "content-type", value: "application/json")
        reqHead.headers.add(name: "user-agent", value: "APNS/swift-nio")
        reqHead.headers.add(name: "content-length", value: buffer.readableBytes.description)
        reqHead.headers.add(name: "apns-topic", value: apnsConfig.topic)
        let jwt = JWT(keyID: apnsConfig.keyId, teamID: apnsConfig.teamId, issueDate: Date(), expireDuration: 60 * 60)
        let token = try! jwt.sign(with: apnsConfig.privateKeyPath)
        reqHead.headers.add(name: "authorization", value: "bearer \(token)")
        ctx.write(self.wrapOutboundOut(.head(reqHead)), promise: nil)
        ctx.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        ctx.write(self.wrapOutboundOut(.end(nil)), promise: nil)
    }
}
