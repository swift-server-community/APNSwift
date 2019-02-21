//
//  SHA256.swift
//  NIOAPNS
//
//  Created by Kyle Browning on 2/21/19.
//

import Foundation
import CNIOOpenSSL

func sha256(message: Data) -> Data {
    var ctx = SHA256_CTX()
    SHA256_Init(&ctx)

    message.enumerateBytes { buffer, _, _ in
        SHA256_Update(&ctx, buffer.baseAddress, buffer.count)
    }

    var digest = Data(count: Int(SHA256_DIGEST_LENGTH))
    _ = digest.withUnsafeMutableBytes { mptr in
        SHA256_Final(mptr, &ctx)
    }

    return digest
}
