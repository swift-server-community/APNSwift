import NIO

final class APNSStreamHandler: ChannelDuplexHandler {
    typealias InboundIn = APNSResponse
    typealias OutboundOut = APNSNotificationProtocol
    typealias OutboundIn = APNSRequestContext
    
    var queue: [APNSRequestContext]
    
    init() {
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
}
