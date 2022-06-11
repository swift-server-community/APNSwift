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

import Crypto
import Foundation
import NIO

extension P256.Signing.PrivateKey {
    public static func loadFrom(filePath: String) throws -> P256.Signing.PrivateKey {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
            let pemString = String(data: data, encoding: .utf8)
        else {
            throw APNSError.SigningError.certificateFileDoesNotExist
        }
        return try loadFrom(string: pemString)
    }

    public static func loadFrom(string: String) throws -> P256.Signing.PrivateKey {
        try .init(pemRepresentation: string)
    }
}
