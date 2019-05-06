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
import NIOAPNSJWT
import NIO
import NIOHTTP2
import NIOSSL

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
    
    public init(keyIdentifier: String, teamIdentifier: String, signingMode: SigningMode, topic: String, environment: APNSConfiguration.Environment) {
        self.keyIdentifier = keyIdentifier
        self.teamIdentifier = teamIdentifier
        self.topic = topic
        self.signingMode = signingMode
        self.environment = environment
        self.tlsConfiguration = TLSConfiguration.forClient(applicationProtocols: ["h2"])
    }
}

extension APNSConfiguration {
    public enum Environment {
        case production
        case sandbox
    }
}
