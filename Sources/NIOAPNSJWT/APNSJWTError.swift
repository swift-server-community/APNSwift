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
public enum APNSJWTError {
    case encodingFailed
    case tokenWasNotGeneratedCorrectly
}

extension APNSJWTError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "The JWT Header or Payload can't be encoded."
        case .tokenWasNotGeneratedCorrectly:
            return "The JWT token was not generated correctly."
        }
    }
}
