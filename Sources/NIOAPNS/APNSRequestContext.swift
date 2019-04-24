import NIO

public struct APNSRequestContext {
    let request: APNSNotification
    let responsePromise: EventLoopPromise<Void>
}
