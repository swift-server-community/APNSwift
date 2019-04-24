//
//  APNSRequestEncoder.swift
//  CNIOAtomics
//
//  Created by Kyle Browning on 2/1/19.
//

import Foundation
import NIOAPNSJWT
import NIO
import NIOHTTP1
import NIOHTTP2

internal final class APNSRequestEncoder<Notification>: ChannelOutboundHandler
    where Notification: APNSNotification
{
    /// See `ChannelOutboundHandler.OutboundIn`.
    typealias OutboundIn = Notification

    /// See `ChannelOutboundHandler.OutboundOut`.
    typealias OutboundOut = HTTPClientRequestPart
    
    let configuration: APNSConfiguration
    let deviceToken: String

    init(deviceToken: String, configuration: APNSConfiguration) {
        self.configuration = configuration
        self.deviceToken = deviceToken
    }
    
    /// See `ChannelOutboundHandler.write(context:data:promise:)`.
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let req: Notification = unwrapOutboundIn(data)
        let data: Data
        do {
            data = try JSONEncoder().encode(req)
        } catch {
            promise?.fail(error)
            context.fireErrorCaught(error)
            return
        }
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)
        var reqHead = HTTPRequestHead(version: .init(major: 2, minor: 0), method: .POST, uri: "/3/device/\(deviceToken)")
        reqHead.headers.add(name: "content-type", value: "application/json")
        reqHead.headers.add(name: "user-agent", value: "APNS/swift-nio")
        reqHead.headers.add(name: "content-length", value: buffer.readableBytes.description)
        reqHead.headers.add(name: "apns-topic", value: configuration.topic)
        reqHead.headers.add(name: "host", value: self.configuration.url.host!)
        let jwt = JWT(keyID: configuration.keyIdentifier, teamID: configuration.teamIdentifier, issueDate: Date(), expireDuration: 60 * 60)
        let token: String
        do {
            token = try jwt.sign(with: configuration.signingMode)
        } catch {
            promise?.fail(APNSTokenError.tokenWasNotGeneratedCorrectly)
            context.close(promise: nil)
            return
        }
        reqHead.headers.add(name: "authorization", value: "bearer \(token)")
        context.write(self.wrapOutboundOut(.head(reqHead))).cascadeFailure(to: promise)
        context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer)))).cascadeFailure(to: promise)
        context.write(self.wrapOutboundOut(.end(nil)), promise: promise)
    }
}
