import NIO
import NIOHTTP1
import NIOHTTP2
import NIOOpenSSL
import Foundation

let sslContext = try SSLContext(configuration: TLSConfiguration.forClient(applicationProtocols: ["h2"]))
let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
var verbose = true
var args = CommandLine.arguments.dropFirst(0)

func usage() {
    print("Usage: http2-client [-v] https://host:port/path")
    print()
    print("OPTIONS:")
    print("     -v: verbose operation (print response code, headers, etc.)")
}

if case .some(let arg) = args.dropFirst().first, arg.starts(with: "-") {
    switch arg {
    case "-v":
        verbose = true
        args = args.dropFirst()
    default:
        usage()
        exit(1)
    }
}

guard let url = URL.init(string: "https://api.development.push.apple.com/3/device/e4bcda99669b692a726b3912e8eca173bac937101c04b774fb053939e74c4f4d") else {
    usage()
    exit(1)
}
guard let host = url.host else {
    print("ERROR: URL '\(url)' does not have a hostname which is required")
    exit(1)
}
guard url.scheme == "https" else {
    print("ERROR: URL '\(url)' is not https but that's required")
    exit(1)
}

let uri = url.absoluteURL.path == "" ? "/" : url.absoluteURL.path
let port = url.port ?? 443


final class APNSHTTP2Handler: ChannelInboundHandler {
    typealias InboundIn = Never
    
    let multiplexer: HTTP2StreamMultiplexer
    let activePromise: EventLoopPromise<Channel>
    
    init(multiplexer: HTTP2StreamMultiplexer, activePromise: EventLoopPromise<Channel>) {
        self.multiplexer = multiplexer
        self.activePromise = activePromise
    }
    
    func channelActive(ctx: ChannelHandlerContext) {
        multiplexer.createStreamChannel(promise: nil) { channel, streamID in
            let handlers: [ChannelHandler] = [
                HTTP2ToHTTP1ClientCodec(streamID: streamID, httpProtocol: .https),
                APNSRequestEncoder(),
                APNSResponseDecoder(),
                APNSHTTP2StreamHandler(activePromise: self.activePromise)
            ]
            return channel.pipeline.addHandlers(handlers, first: false)
        }
    }
}

struct APNSRequestContext {
    let request: APNSRequest
    let responsePromise: EventLoopPromise<APNSResponse>
}

final class APNSHTTP2StreamHandler: ChannelDuplexHandler {
    typealias InboundIn = APNSResponse
    typealias OutboundOut = APNSRequest
    typealias OutboundIn = APNSRequestContext
    
    let activePromise: EventLoopPromise<Channel>
    var queue: [APNSRequestContext]
    
    init(activePromise: EventLoopPromise<Channel>) {
        self.activePromise = activePromise
        self.queue = []
    }
    
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let res = self.unwrapInboundIn(data)
        if let current = self.queue.popLast() {
            current.responsePromise.succeed(result: res)
        }
    }
    
    func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let input = self.unwrapOutboundIn(data)
        self.queue.insert(input, at: 0)
        ctx.write(self.wrapOutboundOut(input.request), promise: promise)
    }
    
    func channelActive(ctx: ChannelHandlerContext) {
        self.activePromise.succeed(result: ctx.channel)
    }
}

let activePromise = group.next().newPromise(of: Channel.self)
let bootstrap = ClientBootstrap(group: group)
    .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
    .channelInitializer { channel in
        let sslHandler = try! OpenSSLClientHandler(context: sslContext, serverHostname: host)
        let multiplexer = HTTP2StreamMultiplexer { channel, streamID in
            fatalError("server push not supported")
        }
        let handlers: [ChannelHandler] = [
            sslHandler,
            HTTP2Parser(mode: .client),
            multiplexer,
            APNSHTTP2Handler(multiplexer: multiplexer, activePromise: activePromise)
        ]
        return channel.pipeline.addHandlers(handlers, first: false)
}


defer {
    try! group.syncShutdownGracefully()
}

do {
    let channel = try bootstrap.connect(host: host, port: port).wait()

    if verbose {
        print("* Connected to \(host) (\(channel.remoteAddress!)")
    }

    let subchannel = try activePromise.futureResult.wait()
    print(subchannel.pipeline)

    let res = subchannel.eventLoop.newPromise(of: APNSResponse.self)
    let alert = Alert(title: "Hey There", subtitle: "Subtitle", body: "Body")
    let aps = Aps(badge: 1, category: nil, alert: alert)
    let req = APNSRequestContext(request: APNSRequest(aps: aps, custom: nil), responsePromise: res)
    subchannel.writeAndFlush(req, promise: nil)
    print(try res.futureResult.wait())
   
    try channel.close(mode: .all).wait()
    try group.syncShutdownGracefully()
    exit(0)
} catch {
    print("ERROR: \(error)")
}
