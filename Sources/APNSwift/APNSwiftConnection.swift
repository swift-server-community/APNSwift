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
import NIOHTTP2
import NIOSSL
import NIOTLS
import Logging

private final class WaitForTLSUpHandler: ChannelInboundHandler {
    typealias InboundIn = Never

    struct TLSNegotiationError: Error {
        var wrongProtocolNegotiated: String?
    }

    private let allDonePromise: EventLoopPromise<Void>

    init(allDonePromise: EventLoopPromise<Void>) {
        self.allDonePromise = allDonePromise
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        // this is an unknown error, this is unexpected, let's fail everything and close the connection.
        self.allDonePromise.fail(error)
        context.close(promise: nil)
    }

    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        if let event = event as? TLSUserEvent {
            switch event {
            case .handshakeCompleted(negotiatedProtocol: "h2"):
                self.allDonePromise.succeed(())
            case .handshakeCompleted(negotiatedProtocol: let proto):
                self.allDonePromise.fail(TLSNegotiationError(wrongProtocolNegotiated: proto))
                context.close(promise: nil)
            case .shutdownCompleted:
                context.fireUserInboundEventTriggered(event)
            }
        } else {
            context.fireUserInboundEventTriggered(event)
        }
    }

    func channelInactive(context: ChannelHandlerContext) {
        // there's always the possibility that we just get a close which we need to handle.
        self.allDonePromise.fail(ChannelError.eof)
    }
}

public final class APNSwiftConnection: APNSwiftClient {
    /// APNSwift Connect method. Used to establish a connection with Apple Push Notification service.
    ///
    /// Usage example:
    ///
    ///     let signer = try! APNSwiftSigner(filePath: "/Users/kylebrowning/Downloads/AuthKey_9UC9ZLQ8YW.p8")
    ///
    ///     let apnsConfig = APNSwiftConfiguration(keyIdentifier: "9UC9ZLQ8YW",
    ///     teamIdentifier: "ABBM6U9RM5",
    ///     signer: signer,
    ///     topic: "com.grasscove.Fern",
    ///     environment: .sandbox)
    ///
    ///     let apns = try APNSwiftConnection.connect(configuration: apnsConfig, on: group.next()).wait()
    ///
    /// - Parameters:
    ///     - configuration: APNSwiftConfiguration struct.
    ///     - eventLoop: eventLoop to open the connection on.
    public static func connect(
        configuration: APNSwiftConfiguration,
        on eventLoop: EventLoop,
        logger: Logger? = nil
    ) -> EventLoopFuture<APNSwiftConnection> {
        struct UnsupportedServerPushError: Error {}

        let logger = logger ?? configuration.logger
        logger?.debug("Connection - starting")
        var tlsConfiguration = TLSConfiguration.forClient(applicationProtocols: ["h2"])
        switch configuration.authenticationMethod {
        case .jwt: break
        case .tls(let configure):
            configure(&tlsConfiguration)
        }
        let sslContext: NIOSSLContext
        do {
            sslContext = try NIOSSLContext(configuration: tlsConfiguration)
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
        let connectionFullyUpPromise = eventLoop.makePromise(of: Void.self)
        let tcpConnection = ClientBootstrap(group: eventLoop).connect(host: configuration.url.host!, port: 443)
        tcpConnection.cascadeFailure(to: connectionFullyUpPromise)
        return tcpConnection.flatMap { channel in
            let sslHandler: NIOSSLClientHandler
            do {
                sslHandler = try NIOSSLClientHandler(
                    context: sslContext,
                    serverHostname: configuration.url.host
                )
            } catch {
                return channel.eventLoop.makeFailedFuture(error)
            }
            return channel.pipeline.addHandlers([
                sslHandler,
                WaitForTLSUpHandler(allDonePromise: connectionFullyUpPromise)
            ]).flatMap {
                channel.configureHTTP2Pipeline(mode: .client) { channel, _ in
                    let error = UnsupportedServerPushError()
                    logger?.warning("Connection - failed \(error)")
                    return channel.eventLoop.makeFailedFuture(error)
                }.flatMap { multiplexer in
                    return connectionFullyUpPromise.futureResult.map { () -> APNSwiftConnection in
                        logger?.debug("Connection - bringing up")
                        return APNSwiftConnection(
                            channel: channel,
                            multiplexer: multiplexer,
                            configuration: configuration,
                            logger: logger
                        )
                    }
                }
            }
        }
    }

    public var eventLoop: EventLoop {
        return self.channel.eventLoop
    }
    public let multiplexer: HTTP2StreamMultiplexer
    public let channel: Channel
    public let configuration: APNSwiftConfiguration
    private var bearerTokenFactory: APNSwiftBearerTokenFactory?
    public var logger: Logger?

    private init(
        channel: Channel,
        multiplexer: HTTP2StreamMultiplexer,
        configuration: APNSwiftConfiguration,
        logger: Logger? = nil
    ) {
        self.channel = channel
        self.multiplexer = multiplexer
        self.configuration = configuration
        self.logger = logger
        logger?.info("Connection - up")
        self.bearerTokenFactory = configuration.makeBearerTokenFactory(on: channel.eventLoop)
    }

    /// This is to be used with caution. APNSwift cannot gurantee delivery if you do not have the correct payload.
    /// For more information see: [Creating APN Payload](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html)
    public func send(
        rawBytes payload: ByteBuffer,
        pushType: APNSwiftConnection.PushType,
        to deviceToken: String,
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        logger: Logger?
    ) -> EventLoopFuture<Void> {
        let logger = logger ?? self.configuration.logger
        logger?.debug("Send - starting up")
        let streamPromise = self.channel.eventLoop.makePromise(of: Channel.self)
        self.multiplexer.createStreamChannel(promise: streamPromise) { channel, streamID in
            let handlers: [ChannelHandler] = [
                HTTP2ToHTTP1ClientCodec(streamID: streamID, httpProtocol: .https),
                APNSwiftRequestEncoder(
                    deviceToken: deviceToken,
                    configuration: self.configuration,
                    bearerToken: self.bearerTokenFactory?.currentBearerToken,
                    pushType: pushType,
                    expiration: expiration,
                    priority: priority,
                    collapseIdentifier: collapseIdentifier,
                    topic: topic,
                    logger: logger
                ),
                APNSwiftResponseDecoder(),
                APNSwiftStreamHandler(logger: logger)
            ]
            return channel.pipeline.addHandlers(handlers)
        }

        let responsePromise = self.channel.eventLoop.makePromise(of: Void.self)
        let context = APNSwiftRequestContext(
            request: payload,
            responsePromise: responsePromise
        )

        streamPromise.futureResult.cascadeFailure(to: responsePromise)
        return streamPromise.futureResult.flatMap { stream in
            logger?.info("Send - sending")
            return stream.writeAndFlush(context).flatMapErrorThrowing { error in
                logger?.info("Send - sending - failed - \(error)")
                responsePromise.fail(error)
                throw error
            }
        }.flatMap {
            responsePromise.futureResult
        }
    }

    var onClose: EventLoopFuture<Void> {
        logger?.debug("Connection - closed")
        return self.channel.closeFuture
    }

    public func close() -> EventLoopFuture<Void> {
        logger?.debug("Connection - closing")
        self.channel.eventLoop.execute {
            self.logger?.debug("Connection - killing bearerToken")
            self.bearerTokenFactory?.cancel()
            self.bearerTokenFactory = nil
        }
        return self.channel.close(mode: .all)
    }
}
