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

/// An error for when the connections ends, but we still have promises in our queue.
public struct NoResponseReceivedBeforeConnectionEnded: Error, Equatable {}
/// An error where a request was made to Apple, but the response body buffer was nil
public struct NoResponseBodyFromApple: Error, Equatable {}
/// An error where no the connection received no response within the timeout period
public struct NoResponseWithinTimeoutError: Error, Equatable {}

public struct APNSwiftError: Equatable {
    public enum ResponseError: Error, Equatable {
        case badRequest(ResponseErrorMessage)
    }
    /// This is used to decode the response from Apple.
    public struct ResponseStruct: Codable {
        public let reason: ResponseErrorMessage
    }
    /// This is an enum that provides the possible responses from Apple
    public enum ResponseErrorMessage: String, Codable {
        /// The collapse identifier exceeds the maximum allowed size.
        case badCollapseIdentifier = "BadCollapseId"
        /// The specified device token was bad. Verify that the request contains a valid token and that the token matches the environment.
        case badDeviceToken = "BadDeviceToken"
        /// The apns-expiration value is bad.
        case badExpirationDate = "BadExpirationDate"
        /// The apns-id value is bad.
        case badMessageId = "BadMessageId"
        /// The apns-priority value is bad.
        case badPriority = "BadPriority"
        /// The apns-topic was invalid.
        case badTopic = "BadTopic"
        /// The device token does not match the specified topic.
        case deviceTokenNotForTopic = "DeviceTokenNotForTopic"
        /// One or more headers were repeated.
        case duplicateHeaders = "DuplicateHeaders"
        /// Idle time out.
        case idleTimeout = "IdleTimeout"
        /// The device token is not specified in the request :path. Verify that the :path header contains the device token.
        case missingDeviceToken = "MissingDeviceToken"
        /// The apns-topic header of the request was not specified and was required. The apns-topic header is mandatory when the client is connected using a certificate that supports multiple topics.
        case missingTopic = "MissingTopic"
        /// The message payload was empty.
        case payloadEmpty = "PayloadEmpty"
        /// Pushing to this topic is not allowed.
        case topicDisallowed = "TopicDisallowed"
        /// The certificate was bad.
        case badCertificate = "BadCertificate"
        /// The client certificate was for the wrong environment.
        case badCertificateEnvironment = "BadCertificateEnvironment"
        /// The provider token is stale and a new token should be generated.
        case expiredProviderToken = "ExpiredProviderToken"
        /// The specified action is not allowed.
        case forbidden = "Forbidden"
        /// The provider token is not valid or the token signature could not be verified.
        case invalidProviderToken = "InvalidProviderToken"
        /// No provider certificate was used to connect to APNs and Authorization header was missing or no provider token was specified.
        case missingProviderToken = "MissingProviderToken"
        /// The request contained a bad :path value.
        case badPath = "BadPath"
        /// The specified :method was not POST.
        case methodNotAllowed = "MethodNotAllowed"
        /// The device token is inactive for the specified topic.
        case unregistered = "Unregistered"
        /// The message payload was too large.
        case payloadTooLarge = "PayloadTooLarge"
        /// The provider token is being updated too often.
        case tooManyProviderTokenUpdates = "TooManyProviderTokenUpdates"
        /// Too many requests were made consecutively to the same device token.
        case tooManyRequests = "TooManyRequests"
        /// An internal server error occurred.
        case internalServerError = "InternalServerError"
        /// The service is unavailable.
        case serviceUnavailable = "ServiceUnavailable"
        /// The server is shutting down.
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
