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

public enum SigningMode {
    case file(String)
    case data(Data)
    case custom(APNSSigner)
}

extension SigningMode {
    public func sign(digest: Data) throws -> Data {
        switch self {
        case .file(let filePath):
            return try FileSigner(url: URL(fileURLWithPath: filePath)).sign(digest: digest)
        case .data(let data):
            return try DataSigner(data: data).sign(digest: digest)
        case .custom(let signer):
            return try signer.sign(digest: digest)
        }
    }
}
