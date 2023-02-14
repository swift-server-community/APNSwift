import Logging

enum LoggingKeys {
    static let error = "error"
    static let authenticationTokenIssuedAt = "authenticationToken.issuedAt"
    static let authenticationTokenIssuer = "authenticationToken.issuer"
    static let authenticationTokenKeyID = "authenticationToken.keyID"
    static let notificationPushType = "notification.pushType"
    static let notificationID = "notification.id"
    static let notificationExpiration = "notification.expiration"
    static let notificationPriority = "notification.priority"
    static let notificationTopic = "notification.topic"
    static let notificationCollapseID = "notification.collapseID"
}

/// A no-op logger.
public let _noOpLogger = Logger(label: "no-op") { _ in SwiftLogNoOpLogHandler() }
