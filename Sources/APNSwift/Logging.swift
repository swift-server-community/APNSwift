import Logging

enum LoggingKeys {
    static let authenticationTokenIssuedAt = "authenticationToken.issuedAt"
    static let authenticationTokenIssuer = "authenticationToken.issuer"
    static let authenticationTokenKeyID = "authenticationToken.keyID"
}

/// A no-op logger.
public let _noOpLogger = Logger(label: "no-op") { _ in SwiftLogNoOpLogHandler() }
