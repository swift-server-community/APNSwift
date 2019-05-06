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
/// This enum provides an error interface for Signing digests.
public enum APNSSignatureError: Error {
    case invalidP8
    case invalidASN1
    case invalidAuthKey
    case certificateFileDoesNotExist
    case encodingFailed
}

extension APNSSignatureError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidP8:
            return "The .p8 string has invalid format."
        case .invalidASN1:
            return "The ASN.1 data has invalid format."
        case .invalidAuthKey:
            return "The Private key is invalid."
        case .certificateFileDoesNotExist:
            return "The Certificate file doesn't exist."
        case .encodingFailed:
            return "The JWT Header or Payload can't be encoded"
        }
    }
}
