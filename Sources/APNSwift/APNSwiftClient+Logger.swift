import Foundation
import Logging
import NIO

extension APNSwiftClient {
    public func logging(to logger: Logger) -> APNSwiftClient {
        return APNSwiftClientWithCustomLogger(client: self, logger: logger)
    }
}

private struct APNSwiftClientWithCustomLogger: APNSwiftClient {
    var eventLoop: EventLoop {
        return self.client.eventLoop
    }
    let client: APNSwiftClient
    let logger: Logger?

    func send(rawBytes payload: ByteBuffer,
              pushType: APNSwiftConnection.PushType,
              to deviceToken: String,
              expiration: Date?,
              priority: Int?,
              collapseIdentifier: String?,
              topic: String?,
              logger: Logger?) -> EventLoopFuture<Void> {
        return self.client.send(rawBytes: payload,
                           pushType: pushType,
                           to: deviceToken,
                           expiration: expiration,
                           priority: priority,
                           collapseIdentifier: collapseIdentifier,
                           topic: topic,
                           logger: logger)
    }
}
