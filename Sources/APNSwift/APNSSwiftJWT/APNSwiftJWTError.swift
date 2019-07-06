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
internal enum APNSwiftJWTError {
    case encodingFailed
    case tokenWasNotGeneratedCorrectly
}

extension APNSwiftJWTError: LocalizedError {
    internal var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "The JWT Header or Payload can't be encoded."
        case .tokenWasNotGeneratedCorrectly:
            return "The JWT token was not generated correctly."
        }
    }
}
