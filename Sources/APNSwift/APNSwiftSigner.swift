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

        guard let privateKeyPtr = OpaquePointer.make(optional: PEM_read_bio_ECPrivateKey(bio!, nil, nil, nil)) else {
            throw APNSwiftError.SigningError.invalidAuthKey
        }
        defer { EC_KEY_free(privateKeyPtr) }
        
        let sig = try digest.withUnsafeReadableBytes { ptr -> OpaquePointer in
            guard let sig = ECDSA_do_sign(ptr.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(ptr.count), privateKeyPtr) else {
                throw APNSwiftError.SigningError.invalidSignatureData
            }
            return .init(sig)
        }
        defer { ECDSA_SIG_free(.init(sig)) }

        var r : OpaquePointer? = nil
        var s : OpaquePointer? = nil
        
        // as this method is `get0` there is no requirement to free those pointers: ECDSA_SIG will free them for us.
        withUnsafeMutablePointer(to: &r) { rPtr in
            withUnsafeMutablePointer(to: &s) { sPtr in
                CAPNSOpenSSL_ECDSA_SIG_get0(.init(sig), .make(optional: rPtr), .make(optional: sPtr))
            }
        }
        
        
        var rb = [UInt8](repeating: 0, count: Int(BN_num_bits(.make(optional: r))+7)/8)
        var sb = [UInt8](repeating: 0, count: Int(BN_num_bits(.make(optional: s))+7)/8)
        let lenr = Int(BN_bn2bin(.make(optional: r), &rb))
        let lens = Int(BN_bn2bin(.make(optional: s), &sb))

        var signatureBytes = ByteBufferAllocator().buffer(capacity: lenr + lens)
        signatureBytes.writeBytes(rb[0..<lenr])
        signatureBytes.writeBytes(sb[0..<lens])
        return signatureBytes
    }
}
