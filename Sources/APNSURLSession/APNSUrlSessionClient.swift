import APNSCore
import Foundation.NSJSONSerialization

public struct APNSUrlSessionClient: APNSClient {
    public let configuration: APNSClientConfiguration
    public let authenticationTokenManager: APNSAuthenticationTokenManager?
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    public init(configuration: APNSClientConfiguration) {
        self.configuration = configuration
        
        switch configuration.authenticationMethod.method {
        case .jwt(let privateKey, let teamIdentifier, let keyIdentifier):
            self.authenticationTokenManager = APNSAuthenticationTokenManager(
                privateKey: privateKey,
                teamIdentifier: teamIdentifier,
                keyIdentifier: keyIdentifier
            )
        case .tls:
            self.authenticationTokenManager = nil
        }
    }
    
    public func send(
        _ request: APNSRequest<some APNSMessage>
    ) async throws -> APNSResponse {
        var urlRequest = URLRequest(url: URL(string: configuration.environment.url + "/3/device/\(request.deviceToken)")!)
        urlRequest.httpMethod = "POST"
        // Set headers
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (header, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: header)
        }
        
        if let authenticationTokenManager {
            urlRequest.setValue(try authenticationTokenManager.nextValidToken, forHTTPHeaderField: "Authorization")
        }
        
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
