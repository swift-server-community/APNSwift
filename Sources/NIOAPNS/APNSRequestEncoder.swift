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

internal final class APNSRequestEncoder<T: APNSNotificationProtocol>: ChannelOutboundHandler {
    /// See `ChannelOutboundHandler.OutboundIn`.
    typealias OutboundIn = T

    /// See `ChannelOutboundHandler.OutboundOut`.
    typealias OutboundOut = HTTPClientRequestPart
    
    public let configuration: APNSConfiguration
    public let deviceToken: String
    
    init(deviceToken: String, configuration: APNSConfiguration) {
        self.configuration = configuration
        self.deviceToken = deviceToken
    }
    /// See `ChannelOutboundHandler.write(ctx:data:promise:)`.
    func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let req: T = unwrapOutboundIn(data)
        let data: Data
        do {
            data = try JSONEncoder().encode(req)
        } catch {
            promise?.fail(error: error)
            ctx.close(promise: nil)
            return
        }
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.write(bytes: data)
        var reqHead = HTTPRequestHead(version: .init(major: 2, minor: 0), method: .POST, uri: "/3/device/\(deviceToken)")
        reqHead.headers.add(name: "content-type", value: "application/json")
        reqHead.headers.add(name: "user-agent", value: "APNS/swift-nio")
        reqHead.headers.add(name: "content-length", value: buffer.readableBytes.description)
        reqHead.headers.add(name: "apns-topic", value: configuration.topic)
        let jwt = JWT(keyID: configuration.keyIdentifier, teamID: configuration.teamIdentifier, issueDate: Date(), expireDuration: 60 * 60)
        let token: String
        do {
            token = try jwt.sign(with: configuration.signingMode)
        } catch {
            promise?.fail(error: APNSTokenError.tokenWasNotGeneratedCorrectly)
            ctx.close(promise: nil)
            return
        }
        reqHead.headers.add(name: "authorization", value: "bearer \(token)")
        ctx.write(self.wrapOutboundOut(.head(reqHead)), promise: nil)
        ctx.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        ctx.write(self.wrapOutboundOut(.end(nil)), promise: nil)
    }
}
