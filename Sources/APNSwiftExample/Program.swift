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

import APNSwift
import Foundation
import Logging

@available(macOS 11.0, *)
@main
struct Main {
    // TODO: Maybe provide this in the package
    struct Payload: Codable {}
    static let logger: Logger = {
        var logger = Logger(label: "APNSExample")
        logger.logLevel = .trace
        return logger
    }()

    /// To use this example app please provide proper values for variable below.
    static let deviceToken = ""
    static let pushKitDeviceToken = ""
    static let appBundleID = ""
    static let privateKey = """
    -----BEGIN PRIVATE KEY-----
    -----END PRIVATE KEY-----
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
            requestEncoder: JSONEncoder(),
            byteBufferAllocator: .init(),
            backgroundActivityLogger: logger
        )
        defer {
            client.shutdown { _ in
                logger.error("Failed to shutdown APNSClient")
            }
        }

        do {
            // TODO: Send pushes once semantic APIs land
        } catch {
            self.logger.error("Failed sending push", metadata: ["error": "\(error)"])
        }
    }
}
