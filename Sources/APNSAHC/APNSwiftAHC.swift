import APNSCore
import AsyncHTTPClient
import Dispatch
import struct Foundation.Date
import struct Foundation.UUID
import Foundation.NSJSONSerialization
import Logging
import NIOConcurrencyHelpers
import NIOCore
import NIOHTTP1
import NIOSSL
import NIOTLS

public struct AsyncHTTPAPNSClient: APNSHttpClient {
    private let httpClient: HTTPClient
    /// The logger used by the ``APNSClient``.
    private let backgroundActivityLogger: Logger
    
    private let byteBufferAllocator: ByteBufferAllocator = .init()
    
    public init(
        configuration: APNSClientConfiguration,
        eventLoopGroupProvider: HTTPClient.EventLoopGroupProvider,
        backgroundActivityLogger: Logger = _noOpLogger
    ) {
        var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
//        switch configuration.authenticationMethod.method {
//        case .tls(let privateKey, let certificateChain):
//            tlsConfiguration.privateKey = privateKey
//            tlsConfiguration.certificateChain = certificateChain
//        case .jwt:
//            /// no op
//            break
//        }
        
        var httpClientConfiguration = HTTPClient.Configuration()
        httpClientConfiguration.tlsConfiguration = tlsConfiguration
        httpClientConfiguration.httpVersion = .automatic
//        httpClientConfiguration.proxy = configuration.proxy

        self.backgroundActivityLogger = backgroundActivityLogger
        self.httpClient = HTTPClient(
            eventLoopGroupProvider: eventLoopGroupProvider,
            configuration: httpClientConfiguration,
            backgroundActivityLogger: backgroundActivityLogger
        )
    }
    
    public init(
        configuration: APNSClientConfiguration,
        backgroundActivityLogger: Logger = _noOpLogger
    ) {
        self.init(
            configuration: configuration,
            eventLoopGroupProvider: .createNew,
            backgroundActivityLogger: backgroundActivityLogger
        )
    }
    
    /// Shuts down the client and event loop gracefully. This function is clearly an outlier in that it uses a completion
    /// callback instead of an EventLoopFuture. The reason for that is that NIO's EventLoopFutures will call back on an event loop.
    /// The virtue of this function is to shut the event loop down. To work around that we call back on a DispatchQueue
    /// instead.
    ///
    /// - Important: This will only shutdown the event loop if the provider passed to the client was ``createNew``.
    /// For shared event loops the owner of the event loop is responsible for handling the lifecycle.
    ///
    /// - Parameters:
    ///   - queue: The queue on which the callback is invoked on.
    ///   - callback: The callback that is invoked when everything is shutdown.
    public func shutdown(queue: DispatchQueue = .global(), callback: @escaping (Error?) -> Void) {
        self.backgroundActivityLogger.trace("APNSClient is shutting down")
        self.httpClient.shutdown(callback)
    }

    /// Shuts down the client and `EventLoopGroup` if it was created by the client.
    public func syncShutdown() throws {
        self.backgroundActivityLogger.trace("APNSClient is shutting down")
        try self.httpClient.syncShutdown()
    }
    
    public func send<Payload: Encodable>(
        payload: Payload?,
        headers: [String : String],
        requestURL: String,
        decoder: JSONDecoder,
        deadline: Duration,
        logger: Logging.Logger,
        file: String,
        line: Int
    ) async throws -> APNSResponse {
        let headers = HTTPHeaders(headers.map { ($0, $1) })
        var request = HTTPClientRequest(url: requestURL)
        
        
        var byteBuffer = self.byteBufferAllocator.buffer(capacity: 0)

        if let payload = payload {
            let data = try JSONEncoder().encode(payload)
            byteBuffer.writeData(data)
        }
        
        request.method = .POST
        request.headers = headers
        request.body = .bytes(byteBuffer)
        
        let deadline = NIODeadline.uptimeNanoseconds(UInt64(deadline.components.seconds))
        
        let response = try await self.httpClient.execute(request, deadline: deadline, logger: logger)
        let apnsID = response.headers.first(name: "apns-id").flatMap { UUID(uuidString: $0) }
        if response.status == .ok {
            return APNSResponse(apnsID: apnsID)
        }
        let body = try await response.body.collect(upTo: 1024)
        let errorResponse = try decoder.decode(APNSErrorResponse.self, from: body)

        let error = APNSError(
            responseStatus: response.status.description,
            apnsID: apnsID,
            reason: .init(_reason: .init(rawValue: errorResponse.reason)),
            timestamp: errorResponse.timestampInSeconds.flatMap { Date(timeIntervalSince1970: $0) },
            file: file,
            line: line
        )
        
        throw error
    }
}
