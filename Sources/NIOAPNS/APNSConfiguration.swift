//===----------------------------------------------------------------------===//
//
// This source file is part of the NIOApns open source project
//
// Copyright (c) 2019 the NIOApns project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of NIOApns project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import NIO
import NIOAPNSJWT
import NIOHTTP2
import NIOSSL

/// This is structure that provides the system with common configuration.
public struct APNSConfiguration {
    public let keyIdentifier: String
    public let teamIdentifier: String
    public let signingMode: SigningMode
    public let topic: String
    public let environment: Environment
    public let tlsConfiguration: TLSConfiguration

    public var url: URL {
        switch environment {
        case .production:
            return URL(string: "https://api.push.apple.com")!
        case .sandbox:
            return URL(string: "https://api.development.push.apple.com")!
        }
    }

    /**
     Call this function to create a new Configuration.
     - Parameters:
     - keyIdentifier: The key identifier Apple gives you when you setup your APNS key.
     - teamIdentifier: The team identifier Apple assigned you when you created your developer team
     - signingMode: provides a method by which engineers can choose how their certificates are
     signed. Since security is important keeping we extracted this logic into three options.
     `file`, `data`, or `custom`.

     ### Usage Example: ###
     ````
     let apnsConfig = try APNSConfiguration(keyIdentifier: "9UC9ZLQ8YW",
         teamIdentifier: "ABBM6U9RM5",
         signingMode: .file(path: "/Users/kylebrowning/Downloads/AuthKey_9UC9ZLQ8YW.p8"),
         topic: "com.grasscove.Fern",
         environment: .sandbox
     )
     ````
     */
    public init(keyIdentifier: String, teamIdentifier: String, signingMode: SigningMode, topic: String, environment: APNSConfiguration.Environment) {
        self.keyIdentifier = keyIdentifier
        self.teamIdentifier = teamIdentifier
        self.topic = topic
        self.signingMode = signingMode
        self.environment = environment
        tlsConfiguration = TLSConfiguration.forClient(applicationProtocols: ["h2"])
    }
}

extension APNSConfiguration {
    public enum Environment {
        case production
        case sandbox
    }
}
