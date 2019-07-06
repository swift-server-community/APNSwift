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
import NIOHTTP2
import NIOSSL

public final class APNSwiftConnection {
    public static func connect(configuration: APNSwiftConfiguration, on eventLoop: EventLoop) -> EventLoopFuture<APNSwiftConnection> {
        let bootstrap = ClientBootstrap(group: eventLoop)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .channelInitializer { channel in
                do {
                    let sslContext = try NIOSSLContext(configuration: configuration.tlsConfiguration)
                    let sslHandler = try NIOSSLClientHandler(context: sslContext, serverHostname: configuration.url.host)
                    return channel.pipeline.addHandler(sslHandler).flatMap {
                        channel.configureHTTP2Pipeline(mode: .client) { _, _ in
                            fatalError("server push not supported")
                        }.map { _ in }
                    }
                } catch {
                    channel.close(mode: .all, promise: nil)
                    return channel.eventLoop.makeFailedFuture(error)
                }
            }

        return bootstrap.connect(host: configuration.url.host!, port: 443).flatMap { channel in
            return channel.pipeline.handler(type: HTTP2StreamMultiplexer.self).map { multiplexer in
                return APNSwiftConnection(channel: channel, multiplexer: multiplexer, configuration: configuration)
            }
        }
    }

    public let multiplexer: HTTP2StreamMultiplexer
    public let channel: Channel
    public let configuration: APNSwiftConfiguration

    public init(channel: Channel, multiplexer: HTTP2StreamMultiplexer, configuration: APNSwiftConfiguration) {
        self.channel = channel
        self.multiplexer = multiplexer
        self.configuration = configuration
    }

    public func send<Notification>(_ notification: Notification, to deviceToken: String, with customEncoder: JSONEncoder? = nil, expiration: Date? = nil, priority: Int? = nil, collapseIdentifier: String? = nil, topic: String? = nil) -> EventLoopFuture<Void>
        where Notification: APNSwiftNotification {
        let streamPromise = channel.eventLoop.makePromise(of: Channel.self)
        multiplexer.createStreamChannel(promise: streamPromise) { channel, streamID in
            let handlers: [ChannelHandler] = [
                HTTP2ToHTTP1ClientCodec(streamID: streamID, httpProtocol: .https),
                APNSwiftRequestEncoder<Notification>(deviceToken: deviceToken, configuration: self.configuration, expiration: expiration, priority: priority, collapseIdentifier: collapseIdentifier),
                APNSwiftResponseDecoder(),
                APNSwiftStreamHandler(),
            ]
            return channel.pipeline.addHandlers(handlers)
        }

        let responsePromise = channel.eventLoop.makePromise(of: Void.self)
        let data: Data
        if let customEncoder = customEncoder {
            data = try! customEncoder.encode(notification)
        } else {
            data = try! JSONEncoder().encode(notification)
        }
        
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)
        let context = APNSwiftRequestContext(
            request: buffer,
            responsePromise: responsePromise
        )

        return streamPromise.futureResult.flatMap { stream in
            responsePromise.futureResult.whenComplete { _ in }
            return stream.writeAndFlush(context)
            }.flatMap {
                responsePromise.futureResult
        }
    }

    var onClose: EventLoopFuture<Void> {
        return channel.closeFuture
    }

    public func close() -> EventLoopFuture<Void> {
        return channel.close(mode: .all)
    }
}
