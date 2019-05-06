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

import CAPNSOpenSSL
import Foundation

func sha256(message: Data) -> Data {
    var context = SHA256_CTX()
    SHA256_Init(&context)

    var res = message.withUnsafeBytes { buffer in
        SHA256_Update(&context, buffer.baseAddress, buffer.count)
    }
    assert(res == 1, "SHA256_Update failed")

    var digest = Data(count: Int(SHA256_DIGEST_LENGTH))
    res = digest.withUnsafeMutableBytes { mptr in
        SHA256_Final(mptr.baseAddress?.assumingMemoryBound(to: UInt8.self), &context)
    }
    assert(res == 1, "SHA256_Final failed")

    return digest
}
