//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2019 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation

/// This is an enum that provides the possible responses from Apple
public struct APNSwiftError: Equatable {
    public enum ResponseError: Error, Equatable {
        case badRequest(ResponseErrorMessage)
    }
    /// This is used to decode the response from Apple.
    public struct ResponseStruct: Codable {
        public let reason: ResponseErrorMessage
    }
    public enum ResponseErrorMessage: String, Codable {
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
        case unknown

        public var description: String {
            return rawValue
        }
    }
    public enum SigningError: Error {
        case invalidAuthKey
        case invalidASN1
        case certificateFileDoesNotExist
        case invalidSignatureData
    }
}
