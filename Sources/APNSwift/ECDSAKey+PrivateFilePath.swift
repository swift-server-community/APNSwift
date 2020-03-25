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

import JWTKit
import Foundation
import NIO

extension ECDSAKey {
    public static func `private`(filePath: String) throws -> ECDSAKey {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            throw APNSwiftError.SigningError.certificateFileDoesNotExist
        }
        return try .private(pem: data)
    }
}
