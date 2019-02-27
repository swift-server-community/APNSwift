import NIO

public struct APNSRequestContext {
    let request: APNotification
    let responsePromise: EventLoopPromise<APNSResponse>
}
