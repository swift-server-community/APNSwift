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

// Can someone explain why I could do this, but not
// let wrappedRequest = try! JSONEncoder().encode(req)
// Cannot invoke 'encode' with an argument list of type '(APNotification)'

extension Encodable {
    func toJSONData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}
internal final class APNSRequestEncoder: ChannelOutboundHandler {
    /// See `ChannelOutboundHandler.OutboundIn`.
    typealias OutboundIn = APNotification

    /// See `ChannelOutboundHandler.OutboundOut`.
    typealias OutboundOut = HTTPClientRequestPart
    
    public let apnsConfig: APNSConfiguration
    public let deviceToken: String
    
    init(deviceToken: String, apnsConfig: APNSConfiguration) {
        self.apnsConfig = apnsConfig
        self.deviceToken = deviceToken
    }
    /// See `ChannelOutboundHandler.write(ctx:data:promise:)`.
    func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let req:APNotification = unwrapOutboundIn(data)
        let wrappedRequest = req.toJSONData()!
        if let string = String.init(data: wrappedRequest, encoding: .utf8) {
            print(string)
        }
        var buffer = ByteBufferAllocator().buffer(capacity: wrappedRequest.count)
        buffer.write(bytes: wrappedRequest)
        var reqHead = HTTPRequestHead(version: .init(major: 2, minor: 0), method: .POST, uri: "/3/device/\(deviceToken)")
        reqHead.headers.add(name: "content-type", value: "application/json")
        reqHead.headers.add(name: "user-agent", value: "APNS/swift-nio")
        reqHead.headers.add(name: "content-length", value: buffer.readableBytes.description)
        reqHead.headers.add(name: "apns-topic", value: apnsConfig.topic)
        let jwt = JWT(keyID: apnsConfig.keyIdentifier, teamID: apnsConfig.teamIdentifier, issueDate: Date(), expireDuration: 60 * 60)
        let token = try! jwt.sign(with: apnsConfig.signingMode)
        reqHead.headers.add(name: "authorization", value: "bearer \(token)")
        ctx.write(self.wrapOutboundOut(.head(reqHead)), promise: nil)
        ctx.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        ctx.write(self.wrapOutboundOut(.end(nil)), promise: nil)
    }
}
