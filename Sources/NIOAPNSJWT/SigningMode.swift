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

public struct SigningMode {
    public let signer: APNSSigner
    init(signer: APNSSigner) {
        self.signer = signer
    }
}

extension SigningMode {
    public static func file(path: String) throws -> SigningMode {
        return .init(signer: try FileSigner(url: URL(fileURLWithPath: path)))
    }
    public static func data(data: Data) throws -> SigningMode {
        return .init(signer: try DataSigner(data: data))
    }
    public static func custom(signer: APNSSigner) -> SigningMode {
        return .init(signer: signer)
    }
}
