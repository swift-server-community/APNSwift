//
//  APNSErrors.swift
//  CNIOAtomics
//
//  Created by Kyle Browning on 2/5/19.
//

import Foundation

public struct APNSError: Codable {
    public let reason: APNSErrors
}
public enum APNSErrors: String, Codable {
    case BadCollapseId = "BadCollapseId"
    case BadDeviceToken = "BadDeviceToken"
    case BadExpirationDate = "BadExpirationDate"
    case BadMessageId = "BadMessageId"
    case BadPriority = "BadPriority"
    case BadTopic = "BadTopic"
    case DeviceTokenNotForTopic = "DeviceTokenNotForTopic"
    case DuplicateHeaders = "DuplicateHeaders"
    case IdleTimeout = "IdleTimeout"
    case MissingDeviceToken = "MissingDeviceToken"
    case MissingTopic = "MissingTopic"
    case PayloadEmpty = "PayloadEmpty"
    case TopicDisallowed = "TopicDisallowed"
    case BadCertificate = "BadCertificate"
    case BadCertificateEnvironment = "BadCertificateEnvironment"
    case ExpiredProviderToken = "ExpiredProviderToken"
    case Forbidden = "Forbidden"
    case InvalidProviderToken = "InvalidProviderToken"
    case MissingProviderToken = "MissingProviderToken"
    case BadPath = "BadPath"
    case MethodNotAllowed = "MethodNotAllowed"
    case Unregistered = "Unregistered"
    case PayloadTooLarge = "PayloadTooLarge"
    case TooManyProviderTokenUpdates = "TooManyProviderTokenUpdates"
    case TooManyRequests = "TooManyRequests"
    case InternalServerError = "InternalServerError"
    case ServiceUnavailable = "ServiceUnavailable"
    case Shutdown = "Shutdown"
    case Unknown = "unknown"


    public var description: String {
        return rawValue
    }
}

public enum TokenError: Error {
    case invalidAuthKey
    case invalidTokenString
    case wrongTokenLength
    case tokenWasNotGeneratedCorrectly
}

public enum SimpleError: Error {
    case string(message: String)
}

public enum InitializeError: Error, CustomStringConvertible {
    case noAuthentication
    case noTopic
    case certificateFileDoesNotExist
    case keyFileDoesNotExist

    public var description: String {
        switch self {
        case .noAuthentication: return "APNS Authentication is required. You can either use APNS Auth Key authentication (easiest to setup and maintain) or the old fashioned certificates way"
        case .noTopic: return "No APNS topic provided. This is required."
        case .certificateFileDoesNotExist: return "Certificate file could not be found on your disk. Double check if the file exists and if the path is correct"
        case .keyFileDoesNotExist: return "Key file could not be found on your disk. Double check if the file exists and if the path is correct"
        }
    }

}
