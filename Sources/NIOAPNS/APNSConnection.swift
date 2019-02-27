import NIO
import NIOHTTP2
import NIOOpenSSL

final public class APNSConnection {
    public static func connect(configuration: APNSConfiguration, on eventLoop: EventLoop) -> EventLoopFuture<APNSConnection> {
        let multiplexer = HTTP2StreamMultiplexer { channel, streamID in
            fatalError("server push not supported")
        }
        let bootstrap = ClientBootstrap(group: eventLoop)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .channelInitializer { channel in
                let sslHandler = try! OpenSSLClientHandler(context: configuration.sslContext, serverHostname: configuration.url.host)
                let handlers: [ChannelHandler] = [
                    sslHandler,
                    HTTP2Parser(mode: .client),
                    multiplexer
                ]
                return channel.pipeline.addHandlers(handlers, first: false)
        }
        
        return bootstrap.connect(host: configuration.url.host!, port: 443).map { channel in
            return APNSConnection(channel: channel, multiplexer: multiplexer, configuration: configuration)
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
    
    public func send<T: APNotification>( _ request: T, deviceToken: String) -> EventLoopFuture<APNSResponse> {
        let streamPromise = channel.eventLoop.newPromise(of: Channel.self)
        multiplexer.createStreamChannel(promise: streamPromise) { channel, streamID in
            let handlers: [ChannelHandler] = [
                HTTP2ToHTTP1ClientCodec(streamID: streamID, httpProtocol: .https),
                APNSRequestEncoder(deviceToken: deviceToken, apnsConfig: self.configuration),
                APNSResponseDecoder(),
                APNSStreamHandler()
            ]
            return channel.pipeline.addHandlers(handlers, first: false)
        }
        
        let responsePromise = channel.eventLoop.newPromise(of: APNSResponse.self)
        let ctx = APNSRequestContext(
            request: request,
            responsePromise: responsePromise
        )
        return streamPromise.futureResult.then { stream in
            return stream.writeAndFlush(ctx)
            }.then {
                return responsePromise.futureResult
        }
    }
    
    var onClose: EventLoopFuture<Void> {
        return self.channel.closeFuture
    }
    
    public func close() -> EventLoopFuture<Void> {
        return self.channel.close(mode: .all)
    }
}
