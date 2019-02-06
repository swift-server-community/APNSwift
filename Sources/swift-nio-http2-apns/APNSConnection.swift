import NIO
import NIOHTTP2
import NIOOpenSSL

final class APNSConnection {
    static func connect(host: String, port: Int, apnsConfig: APNSConfig, on eventLoop: EventLoop) -> EventLoopFuture<APNSConnection> {
        let multiplexer = HTTP2StreamMultiplexer { channel, streamID in
            fatalError("server push not supported")
        }
        let bootstrap = ClientBootstrap(group: eventLoop)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .channelInitializer { channel in
                let sslHandler = try! OpenSSLClientHandler(context: sslContext, serverHostname: host)
                let handlers: [ChannelHandler] = [
                    sslHandler,
                    HTTP2Parser(mode: .client),
                    multiplexer
                ]
                return channel.pipeline.addHandlers(handlers, first: false)
        }
        
        return bootstrap.connect(host: host, port: port).map { channel in
            return APNSConnection(channel: channel, multiplexer: multiplexer, apnsConfig: apnsConfig)
        }
    }
    
    let multiplexer: HTTP2StreamMultiplexer
    let channel: Channel
    let apnsConfig: APNSConfig
    
    init(channel: Channel, multiplexer: HTTP2StreamMultiplexer, apnsConfig: APNSConfig) {
        self.channel = channel
        self.multiplexer = multiplexer
        self.apnsConfig = apnsConfig
    }
    
    func send(deviceToken: String, _ request: APNSRequest) -> EventLoopFuture<APNSResponse> {
        let streamPromise = channel.eventLoop.newPromise(of: Channel.self)
        multiplexer.createStreamChannel(promise: streamPromise) { channel, streamID in
            let handlers: [ChannelHandler] = [
                HTTP2ToHTTP1ClientCodec(streamID: streamID, httpProtocol: .https),
                APNSRequestEncoder(deviceToken: deviceToken, apnsConfig: self.apnsConfig),
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
    
    func close() -> EventLoopFuture<Void> {
        return self.channel.close(mode: .all)
    }
}
