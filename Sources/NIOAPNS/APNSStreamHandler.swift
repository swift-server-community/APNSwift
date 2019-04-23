import NIO
import Foundation

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
        guard let current = self.queue.popLast() else { return }
        guard res.header.status == .ok else {
            if var data = res.data, let error = try? JSONDecoder().decode(APNSError.self, from: Data(data.readBytes(length: data.readableBytes) ?? [])) {
                current.responsePromise.fail(APNSResponseError.badRequest(error))
            }
            return
        }
        current.responsePromise.succeed(Void())
    }
    
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let input = self.unwrapOutboundIn(data)
        self.queue.insert(input, at: 0)
        context.write(self.wrapOutboundOut(input.request), promise: promise)
    }
}
