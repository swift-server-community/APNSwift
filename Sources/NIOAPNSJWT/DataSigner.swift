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


public class DataSigner: APNSSigner {
    private let opaqueKey: OpaquePointer

    public init(data: Data) throws {
        let bio = BIO_new(BIO_s_mem())
        defer { BIO_free(bio) }

        let nullTerminatedData = data + Data([0])
        let res = nullTerminatedData.withUnsafeBytes { ptr in
            BIO_puts(bio, ptr.baseAddress?.assumingMemoryBound(to: Int8.self))
        }
        assert(res >= 0, "BIO_puts failed")

        if let pointer = OpaquePointer.make(optional: PEM_read_bio_ECPrivateKey(bio!, nil, nil, nil)) {
            opaqueKey = pointer
        } else {
            throw APNSJWTError.invalidAuthKey
        }
    }

    deinit {
        EC_KEY_free(opaqueKey)
    }

    public func sign(digest: Data) throws -> Data {
        let sig = digest.withUnsafeBytes { ptr in
            ECDSA_do_sign(ptr.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(digest.count), opaqueKey)
        }
        defer { ECDSA_SIG_free(sig) }

        var derEncodedSignature: UnsafeMutablePointer<UInt8>?
        let derLength = i2d_ECDSA_SIG(sig, &derEncodedSignature)

        guard let derCopy = derEncodedSignature, derLength > 0 else {
            throw APNSJWTError.invalidASN1
        }

        var derBytes = [UInt8](repeating: 0, count: Int(derLength))

        for b in 0 ..< Int(derLength) {
            derBytes[b] = derCopy[b]
        }

        return Data(derBytes)
    }
}
