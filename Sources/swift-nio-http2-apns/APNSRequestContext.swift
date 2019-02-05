import NIO

struct APNSRequestContext {
    let request: APNSRequest
    let responsePromise: EventLoopPromise<APNSResponse>
}
