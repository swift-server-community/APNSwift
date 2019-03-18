import NIO

final class APNSStreamHandler: ChannelDuplexHandler {
    typealias InboundIn = APNSResponse
    typealias OutboundOut = APNSNotificationProtocol
    typealias OutboundIn = APNSRequestContext
    
    var queue: [APNSRequestContext]
    
    init() {
        self.queue = []
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let res = self.unwrapInboundIn(data)
        if let current = self.queue.popLast() {
            current.responsePromise.succeed(res)
        }
    }
    
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let input = self.unwrapOutboundIn(data)
        self.queue.insert(input, at: 0)
        context.write(self.wrapOutboundOut(input.request), promise: promise)
    }
}
