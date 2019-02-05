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

    /// See `ChannelOutboundHandler.write(ctx:data:promise:)`.
    func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let req:APNSRequest = unwrapOutboundIn(data)
        let wrappedRequest = try! JSONEncoder().encode(req)
        var buffer = ByteBufferAllocator().buffer(capacity: wrappedRequest.count)
        buffer.write(bytes: wrappedRequest)
        var reqHead = HTTPRequestHead(version: .init(major: 2, minor: 0), method: .POST, uri: "/3/device/223a86bdd22598fb3a76ce12eafd590c86592484539f9b8526d0e683ad10cf4f")
        reqHead.headers.add(name: "Host", value: "api.development.push.apple.com")
        reqHead.headers.add(name: "content-type", value: "application/json")
        reqHead.headers.add(name: "user-agent", value: "APNS/swift-nio")
        reqHead.headers.add(name: "accept", value: "*/*")
        reqHead.headers.add(name: "content-length", value: buffer.readableBytes.description)
        let p8 = "/Users/kylebrowning/Downloads/key.p8"
        let keyID = "9UC9ZLQ8YW"
        let teamID = "ABBM6U9RM5"
        reqHead.headers.add(name: "apns-topic", value: "com.grasscove.Fern")
        let jwt = JWT(keyID: keyID, teamID: teamID, issueDate: Date(), expireDuration: 60 * 60)
        // let token = try! jwt.sign(with: p8)
        let token = "foo"
        reqHead.headers.add(name: "authorization", value: "bearer \(token)")
        ctx.write(self.wrapOutboundOut(.head(reqHead)), promise: nil)
        ctx.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        ctx.write(self.wrapOutboundOut(.end(nil)), promise: nil)
    }
}
