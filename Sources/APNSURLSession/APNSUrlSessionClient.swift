import APNSCore
import Foundation

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
        var urlRequest = URLRequest(url: URL(string: configuration.environment.absoluteURL + "/\(request.deviceToken)")!)
        urlRequest.httpMethod = "POST"
        // Set headers
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (header, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: header)
        }
        
        await urlRequest.setValue(try configuration.nextValidToken(), forHTTPHeaderField: "Authorization")
        
        /// Set Body
        urlRequest.httpBody = try encoder.encode(request.message)
        
        var apnsID: UUID? = nil
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        if let response = response as? HTTPURLResponse,
           response.statusCode == 200,
           let apnsIDString = response.allHeaderFields["apns-id"] as? String {
            apnsID = UUID(uuidString: apnsIDString)
            return APNSResponse(apnsID: apnsID)
        }
        
        let errorResponse = try decoder.decode(APNSErrorResponse.self, from: data)
        let error = APNSError(
            responseStatus: response.description,
            apnsID: apnsID,
            apnsResponse: errorResponse,
            timestamp: errorResponse.timestampInSeconds.flatMap { Date(timeIntervalSince1970: $0) }
        )
        
        throw error
    }
}
