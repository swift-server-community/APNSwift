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
    case badCollapseIdentifier = "BadCollapseId"
    case badDeviceToken = "BadDeviceToken"
    case badExpirationDate = "BadExpirationDate"
    case badMessageId = "BadMessageId"
    case badPriority = "BadPriority"
    case badTopic = "BadTopic"
    case deviceTokenNotForTopic = "DeviceTokenNotForTopic"
    case duplicateHeaders = "DuplicateHeaders"
    case idleTimeout = "IdleTimeout"
    case missingDeviceToken = "MissingDeviceToken"
    case missingTopic = "MissingTopic"
    case payloadEmpty = "PayloadEmpty"
    case topicDisallowed = "TopicDisallowed"
    case badCertificate = "BadCertificate"
    case badCertificateEnvironment = "BadCertificateEnvironment"
    case expiredProviderToken = "ExpiredProviderToken"
    case forbidden = "Forbidden"
    case invalidProviderToken = "InvalidProviderToken"
    case missingProviderToken = "MissingProviderToken"
    case badPath = "BadPath"
    case methodNotAllowed = "MethodNotAllowed"
    case unregistered = "Unregistered"
    case payloadTooLarge = "PayloadTooLarge"
    case tooManyProviderTokenUpdates = "TooManyProviderTokenUpdates"
    case tooManyRequests = "TooManyRequests"
    case internalServerError = "InternalServerError"
    case serviceUnavailable = "ServiceUnavailable"
    case shutdown = "Shutdown"
    case encodingFailed = "EncodingFailed"
    case unknown = "unknown"


    public var description: String {
        return rawValue
    }
}

public enum APNSTokenError: Error {
    case invalidAuthKey
    case invalidTokenString
    case tokenWasNotGeneratedCorrectly
    case certificateFileDoesNotExist
    case keyFileDoesNotExist
}

public enum APNSResponseError: Error {
    case badRequest(APNSError)
}
