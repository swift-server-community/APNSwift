//===----------------------------------------------------------------------===//
//
// This source file is part of the NIOApns open source project
//
// Copyright (c) 2019 the NIOApns project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of NIOApns project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import NIO
import NIOHTTP1
import NIOHTTP2

/// The class provides the HTTP2 interface to Swift NIO 2
internal final class APNSRequestEncoder<Notification>: ChannelOutboundHandler
    where Notification: APNSNotification {
    /// See `ChannelOutboundHandler.OutboundIn`.
    typealias OutboundIn = ByteBuffer

    /// See `ChannelOutboundHandler.OutboundOut`.
    typealias OutboundOut = HTTPClientRequestPart

    let configuration: APNSConfiguration
    let deviceToken: String
    let priority: Int?
    let expiration: Int?
    let collapseIdentifier: String?

    init(deviceToken: String, configuration: APNSConfiguration, expiration: Int?, priority: Int?, collapseIdentifier: String?) {
        self.configuration = configuration
        self.deviceToken = deviceToken
        self.expiration = expiration
        self.priority = priority
        self.collapseIdentifier = collapseIdentifier
    }

    /// See `ChannelOutboundHandler.write(context:data:promise:)`.
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let buffer: ByteBuffer = unwrapOutboundIn(data)
        var reqHead = HTTPRequestHead(version: .init(major: 2, minor: 0), method: .POST, uri: "/3/device/\(deviceToken)")
        reqHead.headers.add(name: "content-type", value: "application/json")
        reqHead.headers.add(name: "user-agent", value: "APNS/swift-nio")
        reqHead.headers.add(name: "content-length", value: buffer.readableBytes.description)
        reqHead.headers.add(name: "apns-topic", value: configuration.topic)
        if let priority = self.priority {
            reqHead.headers.add(name: "apns-priority", value: String(priority))
        }
        if let epochTime = self.expiration {
            reqHead.headers.add(name: "apns-expiration", value: String(epochTime))
        }
        if let collapseId = self.collapseIdentifier {
            reqHead.headers.add(name: "apns-collapse-id", value: collapseId)
        }
        reqHead.headers.add(name: "host", value: configuration.url.host!)
        let jwt = APNSJWT(keyID: configuration.keyIdentifier, teamID: configuration.teamIdentifier, issueDate: Date(), expireDuration: 60 * 60)
        var token: String
        do {
            let digestValues = try jwt.getDigest()
            let signature = try configuration.signer.sign(digest: digestValues.fixedDigest)
            guard let data = signature.getData(at: 0, length: signature.readableBytes) else {
                throw APNSError.SigningError.invalidSignatureData
            }
            token = digestValues.digest + "." + data.base64EncodedURLString()
        } catch {
            promise?.fail(error)
            context.close(promise: nil)
            return
        }
        reqHead.headers.add(name: "authorization", value: "bearer \(token)")
        context.write(wrapOutboundOut(.head(reqHead))).cascadeFailure(to: promise)
        context.write(wrapOutboundOut(.body(.byteBuffer(buffer)))).cascadeFailure(to: promise)
        context.write(wrapOutboundOut(.end(nil)), promise: promise)
    }
}
