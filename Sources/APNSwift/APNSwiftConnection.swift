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

public final class APNSwiftConnection {

    /**
     APNSwift Connect method. Used to establish a connection with Apple Push Notification service.
     - Parameter configuration: APNSwiftConfiguration struct.
     - Parameter eventLoop: eventLoop to open the connection on.
     
     ### Usage Example: ###
     ```
     let signer = try! APNSwiftSigner(filePath: "/Users/kylebrowning/Downloads/AuthKey_9UC9ZLQ8YW.p8")
     
     let apnsConfig = APNSwiftConfiguration(keyIdentifier: "9UC9ZLQ8YW",
     teamIdentifier: "ABBM6U9RM5",
     signer: signer,
     topic: "com.grasscove.Fern",
     environment: .sandbox)
     
     let apns = try APNSwiftConnection.connect(configuration: apnsConfig, on: group.next()).wait()
     ```
     */

    public static func connect(configuration: APNSwiftConfiguration, on eventLoop: EventLoop) -> EventLoopFuture<APNSwiftConnection> {
        struct UnsupportedServerPushError: Error {}
        configuration.logger?.debug("Connection - starting")
        let sslContext = try! NIOSSLContext(configuration: configuration.tlsConfiguration)
        let connectionFullyUpPromise = eventLoop.makePromise(of: Void.self)
        let tcpConnection = ClientBootstrap(group: eventLoop).connect(host: configuration.url.host!, port: 443)
        tcpConnection.cascadeFailure(to: connectionFullyUpPromise)
        return tcpConnection.flatMap { channel in
            let sslHandler = try! NIOSSLClientHandler(context: sslContext,
                                                     serverHostname: configuration.url.host)
            return channel.pipeline.addHandlers([sslHandler,
                                                 WaitForTLSUpHandler(allDonePromise: connectionFullyUpPromise)]).flatMap {
                channel.configureHTTP2Pipeline(mode: .client) { channel, _ in
                    let error = UnsupportedServerPushError()
                    configuration.logger?.warning("Connection - failed \(error)")
                    return channel.eventLoop.makeFailedFuture(error)
                }.flatMap { multiplexer in
                    var tokenFactory: APNSwiftBearerTokenFactory?
                    configuration.logger?.debug("Connection - token factory setup")
                    if configuration.tlsConfiguration.privateKey == nil {
                        do {
                            tokenFactory = try APNSwiftBearerTokenFactory(eventLoop: eventLoop, configuration: configuration)
                            configuration.logger?.debug("Connection - token factory created")
                        } catch {
                            configuration.logger?.debug("Connection - token factory setup failed")
                            return channel.eventLoop.makeFailedFuture(APNSwiftError.SigningError.invalidSignatureData)
                        }
                    } else {
                        configuration.logger?.debug("Connection - private key empty, using pem")
                    }
                    return connectionFullyUpPromise.futureResult.map { () -> APNSwiftConnection in
                        configuration.logger?.debug("Connection - bringing up")
                        return APNSwiftConnection(channel: channel, multiplexer: multiplexer, configuration: configuration, bearerTokenFactory: tokenFactory)
                    }
                }
            }
        }
    }

    public let multiplexer: HTTP2StreamMultiplexer
    public let channel: Channel
    public let configuration: APNSwiftConfiguration
    private var bearerTokenFactory: APNSwiftBearerTokenFactory?

    private init(channel: Channel, multiplexer: HTTP2StreamMultiplexer, configuration: APNSwiftConfiguration, bearerTokenFactory: APNSwiftBearerTokenFactory?) {
        self.channel = channel
        self.multiplexer = multiplexer
        self.configuration = configuration
        self.bearerTokenFactory = bearerTokenFactory
        configuration.logger?.info("Connection - up")
    }

    @available(*, deprecated, message: "APNSwiftConnection is initialized internally now.")
    public convenience init(channel: Channel, multiplexer: HTTP2StreamMultiplexer, configuration: APNSwiftConfiguration) {
        var tokenFactory: APNSwiftBearerTokenFactory?
        if configuration.tlsConfiguration.privateKey == nil {
            tokenFactory = try? APNSwiftBearerTokenFactory(eventLoop: channel.eventLoop, configuration: configuration)
        }
        self.init(channel: channel, multiplexer: multiplexer, configuration: configuration, bearerTokenFactory: tokenFactory)
    }

    /**
     APNSwiftConnection send method. Sends a notification to the desired deviceToken.
     - Parameter notification: the notification meta data and alert to send.
     - Parameter bearerToken: the bearer token to authenitcate our request
     - Parameter deviceToken: device token to send alert to.
     - Parameter encoder: customer JSON encoder if needed.
     - Parameter expiration: a date that the notificaiton expires.
     - Parameter priority: priority to send the notification with.
     - Parameter collapseIdentifier: a collapse identifier to use for grouping notifications
     - Parameter topic: the bundle identifier that this notification belongs to.
     
     For more information see:
     [Retrieve Your App's Device Token](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns#2942135)
     ### Usage Example: ###
     ```
     let apns = APNSwiftConnection.connect()
     let expiry = Date().addingTimeInterval(5)
     let bearerToken = APNSwiftBearerToken(configuration: apnsConfig, timeout: 50.0)
     try apns.send(notification, bearerToken: bearerToken,to: "b27a07be2092c7fbb02ab5f62f3135c615e18acc0ddf39a30ffde34d41665276", with: JSONEncoder(), expiration: expiry, priority: 10, collapseIdentifier: "huro2").wait()
     ```
     */
    public func send<Notification: APNSwiftNotification>(_ notification: Notification, pushType: APNSwiftConnection.PushType, to deviceToken: String, with encoder: JSONEncoder = JSONEncoder(), expiration: Date? = nil, priority: Int? = nil, collapseIdentifier: String? = nil, topic: String? = nil) -> EventLoopFuture<Void> {
        let data: Data = try! encoder.encode(notification)
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)
        return send(rawBytes: buffer, pushType: pushType, to: deviceToken)
    }

    /// This is to be used with caution. APNSwift cannot gurantee delivery if you do not have the correct payload.
    /// For more information see: [Creating APN Payload](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html)
    public func send(rawBytes payload: ByteBuffer, pushType: APNSwiftConnection.PushType, to deviceToken: String, expiration: Date? = nil, priority: Int? = nil, collapseIdentifier: String? = nil, topic: String? = nil) -> EventLoopFuture<Void> {
            configuration.logger?.debug("Send - starting up")
            let streamPromise = channel.eventLoop.makePromise(of: Channel.self)
            multiplexer.createStreamChannel(promise: streamPromise) { channel, streamID in
                let handlers: [ChannelHandler] = [
                    HTTP2ToHTTP1ClientCodec(streamID: streamID, httpProtocol: .https),
                    APNSwiftRequestEncoder(deviceToken: deviceToken, configuration: self.configuration, bearerToken: self.bearerTokenFactory?.currentBearerToken, pushType: pushType, expiration: expiration, priority: priority, collapseIdentifier: collapseIdentifier, topic: topic),
                    APNSwiftResponseDecoder(),
                    APNSwiftStreamHandler(configuration: self.configuration)
                ]
                return channel.pipeline.addHandlers(handlers)
            }

            let responsePromise = channel.eventLoop.makePromise(of: Void.self)
            let context = APNSwiftRequestContext(
                request: payload,
                responsePromise: responsePromise
            )

            return streamPromise.futureResult.flatMap { stream in
                self.configuration.logger?.info("Send - sending")
                return stream.writeAndFlush(context)
            }.flatMap {
                responsePromise.futureResult
            }
    }
    @available(*, deprecated, message: "Bearer Tokens are handled internally now, and no longer exposed.")
    public func send<Notification: APNSwiftNotification>(_ notification: Notification, bearerToken: APNSwiftBearerToken, to deviceToken: String, with encoder: JSONEncoder = JSONEncoder(), expiration: Date? = nil, priority: Int? = nil, collapseIdentifier: String? = nil, topic: String? = nil) -> EventLoopFuture<Void> {
        return self.send(notification, pushType: .alert, to: deviceToken, with: encoder, expiration: expiration, priority: priority, collapseIdentifier: collapseIdentifier, topic: topic)
    }

    var onClose: EventLoopFuture<Void> {
        configuration.logger?.debug("Connection - closed")
        return channel.closeFuture
    }

    public func close() -> EventLoopFuture<Void> {
        configuration.logger?.debug("Connection - closing")
        channel.eventLoop.execute {
            self.configuration.logger?.debug("Connection - killing bearerToken")
            self.bearerTokenFactory?.cancel()
            self.bearerTokenFactory = nil
        }
        return channel.close(mode: .all)
    }
}
