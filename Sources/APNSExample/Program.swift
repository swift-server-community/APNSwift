//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2022 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import APNSCore
import APNS
import Foundation

@available(macOS 11.0, *)
@main
struct Main {
    /// To use this example app please provide proper values for variable below.
    static let deviceToken = ""
    static let pushKitDeviceToken = ""
    static let fileProviderDeviceToken = ""
    static let appBundleID = ""
    static let privateKey = """
    """
    static let keyIdentifier = ""
    static let teamIdentifier = ""

    static func main() async throws {
        let client = APNSClient(
            configuration: .init(
                authenticationMethod: .jwt(
                    privateKey: try .init(pemRepresentation: privateKey),
                    keyIdentifier: keyIdentifier,
                    teamIdentifier: teamIdentifier
                ),
                environment: .sandbox
            ),
            eventLoopGroupProvider: .createNew,
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder()
        )

        try await Self.sendSimpleAlert(with: client)
        try await Self.sendLocalizedAlert(with: client)
        try await Self.sendThreadedAlert(with: client)
        try await Self.sendCustomCategoryAlert(with: client)
        try await Self.sendMutableContentAlert(with: client)
        try await Self.sendBackground(with: client)
        try await Self.sendVoIP(with: client)
        try await Self.sendFileProvider(with: client)
    }
}

// MARK: Alerts

@available(macOS 11.0, *)
extension Main {
    static func sendSimpleAlert(with client: some APNSClientProtocol) async throws {
        try await client.sendAlertNotification(
            .init(
                alert: .init(
                    title: .raw("Simple Alert"),
                    subtitle: .raw("Subtitle"),
                    body: .raw("Body"),
                    launchImage: nil
                ),
                expiration: .immediately,
                priority: .immediately,
                topic: self.appBundleID,
                payload: EmptyPayload()
            ),
            deviceToken: self.deviceToken
        )
    }

    static func sendLocalizedAlert(with client: some APNSClientProtocol) async throws {
        try await client.sendAlertNotification(
            .init(
                alert: .init(
                    title: .localized(key: "title", arguments: ["Localized"]),
                    subtitle: .localized(key: "subtitle", arguments: ["APNS"]),
                    body: .localized(key: "body", arguments: ["APNS"]),
                    launchImage: nil
                ),
                expiration: .immediately,
                priority: .immediately,
                topic: self.appBundleID,
                payload: EmptyPayload()
            ),
            deviceToken: self.deviceToken
        )
    }

    static func sendThreadedAlert(with client: some APNSClientProtocol) async throws {
        try await client.sendAlertNotification(
            .init(
                alert: .init(
                    title: .raw("Threaded Alert"),
                    subtitle: .raw("Subtitle"),
                    body: .raw("Body"),
                    launchImage: nil
                ),
                expiration: .immediately,
                priority: .immediately,
                topic: self.appBundleID,
                payload: EmptyPayload(),
                threadID: "thread"
            ),
            deviceToken: self.deviceToken
        )
    }

    static func sendCustomCategoryAlert(with client: some APNSClientProtocol) async throws {
        try await client.sendAlertNotification(
            .init(
                alert: .init(
                    title: .raw("Custom Category Alert"),
                    subtitle: .raw("Subtitle"),
                    body: .raw("Body"),
                    launchImage: nil
                ),
                expiration: .immediately,
                priority: .immediately,
                topic: self.appBundleID,
                payload: EmptyPayload(),
                category: "CUSTOM"
            ),
            deviceToken: self.deviceToken
        )
    }

    static func sendMutableContentAlert(with client: some APNSClientProtocol) async throws {
        try await client.sendAlertNotification(
            .init(
                alert: .init(
                    title: .raw("Mutable Alert"),
                    subtitle: .raw("Subtitle"),
                    body: .raw("Body"),
                    launchImage: nil
                ),
                expiration: .immediately,
                priority: .immediately,
                topic: self.appBundleID,
                payload: EmptyPayload(),
                mutableContent: 1
            ),
            deviceToken: self.deviceToken
        )
    }
}

// MARK: Background

@available(macOS 11.0, *)
extension Main {
    static func sendBackground(with client: some APNSClientProtocol) async throws {
        try await client.sendBackgroundNotification(
            .init(
                expiration: .immediately,
                topic: self.appBundleID,
                payload: EmptyPayload()
            ),
            deviceToken: self.deviceToken
        )
    }
}

// MARK: VoIP

@available(macOS 11.0, *)
extension Main {
    static func sendVoIP(with client: some APNSClientProtocol) async throws {
        try await client.sendVoIPNotification(
            .init(
                expiration: .immediately,
                priority: .immediately,
                appID: self.appBundleID,
                payload: EmptyPayload()
            ),
            deviceToken: self.pushKitDeviceToken
        )
    }
}

// MARK: FileProvider

@available(macOS 11.0, *)
extension Main {
    static func sendFileProvider(with client: some APNSClientProtocol) async throws {
        try await client.sendFileProviderNotification(
            .init(
                expiration: .immediately,
                appID: self.appBundleID,
                payload: EmptyPayload()
            ),
            deviceToken: self.fileProviderDeviceToken
        )
    }
}
