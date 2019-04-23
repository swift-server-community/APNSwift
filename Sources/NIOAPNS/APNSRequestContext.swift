import NIO

public struct APNSRequestContext {
    let request: APNSNotificationProtocol
    let responsePromise: EventLoopPromise<Void>
}
