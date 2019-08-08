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
import CAPNSOpenSSL
import NIO

public struct APNSwiftSigner {
    private let buffer: ByteBuffer
    public init(buffer: ByteBuffer) throws {
        self.buffer = buffer
    }

    // this is a blocking init and should be done at the start of application not on an event loop.
    public init(filePath: String) throws {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            throw APNSwiftError.SigningError.certificateFileDoesNotExist
        }
        var mutableByteBuffer = ByteBufferAllocator().buffer(capacity: data.count)
        mutableByteBuffer.writeBytes(data)
        self.buffer = mutableByteBuffer
    }

    internal func sign(digest: ByteBuffer) throws -> ByteBuffer {
        let bio = BIO_new(BIO_s_mem())
        defer { BIO_free(bio) }
        let res = buffer.withUnsafeReadableBytes { ptr in
            BIO_write(bio, ptr.baseAddress, CInt(ptr.count))
        }
        assert(res >= 0, "BIO_write failed")

        guard let opaquePointer = OpaquePointer.make(optional: PEM_read_bio_ECPrivateKey(bio!, nil, nil, nil)) else {
            throw APNSwiftError.SigningError.invalidAuthKey
        }
        defer { EC_KEY_free(opaquePointer) }
        
        let sig = try digest.withUnsafeReadableBytes { ptr -> UnsafeMutablePointer<ECDSA_SIG> in
            guard let sig = ECDSA_do_sign(ptr.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(digest.readableBytes), opaquePointer) else {
                throw APNSwiftError.SigningError.invalidSignatureData
            }
            return sig
        }
        defer { ECDSA_SIG_free(sig) }

        let r = sig.pointee.r
        let s = sig.pointee.s

        var rb = [UInt8](repeating: 0, count: Int(BN_num_bits(r)+7)/8)
        var sb = [UInt8](repeating: 0, count: Int(BN_num_bits(s)+7)/8)
        let lenr = Int(BN_bn2bin(r, &rb))
        let lens = Int(BN_bn2bin(s, &sb))

        let finalSig = Array(rb[0..<lenr] + sb[0..<lens])
        
        var derBytes = ByteBufferAllocator().buffer(capacity: Int(finalSig.count))
        derBytes.writeBytes(UnsafeBufferPointer<CUnsignedChar>(start: finalSig, count: Int(finalSig.count)))
        return derBytes
    }
}
