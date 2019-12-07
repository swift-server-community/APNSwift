import Foundation
import Logging
import NIO

extension APNSwiftClient {
    public func logging(to logger: Logger) -> APNSwiftClient {
        return APNSwiftClientWithCustomLogger(client: self, logger: logger)
    }
}

private struct APNSwiftClientWithCustomLogger: APNSwiftClient {
    func send<Bytes>(raw payload: Bytes, pushType: APNSwiftConnection.PushType, to deviceToken: String, expiration: Date?, priority: Int?, collapseIdentifier: String?, topic: String?, logger: Logger?) -> EventLoopFuture<Void> where Bytes : Collection, Bytes.Element == UInt8 {
        return client.send(raw: payload, pushType: pushType, to: deviceToken, expiration: expiration, priority: priority, collapseIdentifier: collapseIdentifier, topic: topic, logger: logger)
    }
    

    let client: APNSwiftClient
    let logger: Logger?
}
