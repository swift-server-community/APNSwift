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

/// <#Description#>
final public class APNSConnection {

    /// <#Description#>
    ///
    /// - Parameters:
    ///   - configuration: <#configuration description#>
    ///   - eventLoop: <#eventLoop description#>
    /// - Returns: <#return value description#>
    public static func connect(configuration: APNSConfiguration, on eventLoop: EventLoop) -> EventLoopFuture<APNSConnection> {
        let multiplexerPromise = eventLoop.makePromise(of: HTTP2StreamMultiplexer.self)
        let bootstrap = ClientBootstrap(group: eventLoop)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .channelInitializer { channel in
                do {
                    let sslContext = try NIOSSLContext(configuration: configuration.tlsConfiguration)
                    let sslHandler = try NIOSSLClientHandler(context: sslContext, serverHostname: configuration.url.host)
                    return channel.pipeline.addHandler(sslHandler).flatMap {
                        return channel.configureHTTP2Pipeline(mode: .client) { channel, streamID in
                            fatalError("server push not supported")
                        }.map { multiplexer in
                            multiplexerPromise.succeed(multiplexer)
                        }
                    }
                } catch {
                    channel.close(mode: .all, promise: nil)
                    return channel.eventLoop.makeFailedFuture(error)
                }
        }
        
        return bootstrap.connect(host: configuration.url.host!, port: 443).flatMap { channel in
            return channel.pipeline.context(handlerType: HTTP2StreamMultiplexer.self).map { $0.handler as! HTTP2StreamMultiplexer }.flatMap { multiplexer in
                return multiplexerPromise.futureResult.map { multiplexer in
                    return APNSConnection(channel: channel, multiplexer: multiplexer, configuration: configuration)
                }
            }
        }
    }
    
    public let multiplexer: HTTP2StreamMultiplexer
    public let channel: Channel
    public let configuration: APNSConfiguration
    
    public init(channel: Channel, multiplexer: HTTP2StreamMultiplexer, configuration: APNSConfiguration) {
        self.channel = channel
        self.multiplexer = multiplexer
        self.configuration = configuration
    }
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - notification: <#notification description#>
    ///   - deviceToken: <#deviceToken description#>
    ///   - expiration: <#expiration description#>
    ///   - priority: <#priority description#>
    ///   - collapseIdentifier: <#collapseIdentifier description#>
    /// - Returns: <#return value description#>
    public func send<Notification>(_ notification: Notification, to deviceToken: String, expiration: Int? = nil, priority: Int? = nil, collapseIdentifier: String? = nil) -> EventLoopFuture<Void>
        where Notification: APNSNotification {
        let streamPromise = channel.eventLoop.makePromise(of: Channel.self)
        multiplexer.createStreamChannel(promise: streamPromise) { channel, streamID in
            let handlers: [ChannelHandler] = [
                HTTP2ToHTTP1ClientCodec(streamID: streamID, httpProtocol: .https),
                APNSRequestEncoder<Notification>(deviceToken: deviceToken, configuration: self.configuration, expiration: expiration, priority: priority, collapseIdentifier: collapseIdentifier),
                APNSResponseDecoder(),
                APNSStreamHandler()
            ]
            return channel.pipeline.addHandlers(handlers)
        }
        
        let responsePromise = channel.eventLoop.makePromise(of: Void.self)
        let context = APNSRequestContext(
            request: notification,
            responsePromise: responsePromise
        )
        return streamPromise.futureResult.flatMap { stream in
            return stream.writeAndFlush(context)
        }.flatMap {
            return responsePromise.futureResult
        }
    }
    
    var onClose: EventLoopFuture<Void> {
        return self.channel.closeFuture
    }
    
    /// <#Description#>
    ///
    /// - Returns: <#return value description#>
    public func close() -> EventLoopFuture<Void> {
        return self.channel.close(mode: .all)
    }
}
