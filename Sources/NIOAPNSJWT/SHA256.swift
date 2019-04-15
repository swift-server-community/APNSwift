//
//  SHA256.swift
//  NIOAPNS
//
//  Created by Kyle Browning on 2/21/19.
//

import Foundation
import CAPNSOpenSSL

func sha256(message: Data) -> Data {
    var context = SHA256_CTX()
    SHA256_Init(&context)

    var res = message.withUnsafeBytes { buffer in
        return SHA256_Update(&context, buffer.baseAddress, buffer.count)
    }
    assert(res == 1, "SHA256_Update failed")

    var digest = Data(count: Int(SHA256_DIGEST_LENGTH))
    res = digest.withUnsafeMutableBytes { mptr in
        return SHA256_Final(mptr.baseAddress?.assumingMemoryBound(to: UInt8.self), &context)
    }
    assert(res == 1, "SHA256_Final failed")

    return digest
}
