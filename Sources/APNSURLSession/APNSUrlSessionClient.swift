import APNSCore
import Foundation
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

enum APNSUrlSessionClientError: Error {
    case urlResponseNotFound
}

public struct APNSURLSessionClient: APNSClientProtocol {
    private let configuration: APNSURLSessionClientConfiguration
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    public init(configuration: APNSURLSessionClientConfiguration) {
        self.configuration = configuration
    }
    
    public func send(
        _ request: APNSRequest<some APNSMessage>
    ) async throws -> APNSResponse {
        
        /// Construct URL
        var urlRequest = URLRequest(url: URL(string: configuration.environment.absoluteURL + "/\(request.deviceToken)")!)
        urlRequest.httpMethod = "POST"
        /// Set headers
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (header, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: header)
        }
        
        await urlRequest.setValue(try configuration.nextValidToken(), forHTTPHeaderField: "Authorization")
        
        /// Set Body
        urlRequest.httpBody = try encoder.encode(request.message)
    
        /// Make request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        /// Unwrap response
        guard let response = response as? HTTPURLResponse,
              let apnsIDString = response.allHeaderFields["apns-id"] as? String else {
            throw APNSUrlSessionClientError.urlResponseNotFound
        }
        
        let apnsID = UUID(uuidString: apnsIDString)
        
        /// Detect an error
        if let errorResponse = try? decoder.decode(APNSErrorResponse.self, from: data) {
            let error = APNSError(
                responseStatus: response.statusCode,
                apnsID: apnsID,
                apnsResponse: errorResponse,
                timestamp: errorResponse.timestampInSeconds.flatMap { Date(timeIntervalSince1970: $0) }
            )
            throw error
        } else {
            /// Return APNSResponse
            return APNSResponse(apnsID: apnsID)
        }
    }
}

#endif
