import NIO

public struct APNSRequestContext {
    let request: APNSRequest
    let responsePromise: EventLoopPromise<APNSResponse>
}
