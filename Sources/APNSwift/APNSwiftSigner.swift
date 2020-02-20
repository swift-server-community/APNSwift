//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2019-2020 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@_implementationOnly import CAPNSwiftBoringSSL
import Foundation
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
        let bio = CAPNSwiftBoringSSL_BIO_new(CAPNSwiftBoringSSL_BIO_s_mem())
        defer { CAPNSwiftBoringSSL_BIO_free(bio) }
        let res = buffer.withUnsafeReadableBytes { ptr in
            CAPNSwiftBoringSSL_BIO_write(bio, ptr.baseAddress, CInt(ptr.count))
        }
        assert(res >= 0, "BIO_write failed")
        
        guard let privateKeyPointer = CAPNSwiftBoringSSL_PEM_read_bio_ECPrivateKey(bio!, nil, nil, nil) else {
            throw APNSwiftError.SigningError.invalidAuthKey
        }
        defer { CAPNSwiftBoringSSL_EC_KEY_free(privateKeyPointer) }

        let sig = try digest.withUnsafeReadableBytes { ptr -> OpaquePointer in
            guard let sig = CAPNSwiftBoringSSL_ECDSA_do_sign(ptr.baseAddress?.assumingMemoryBound(to: UInt8.self), ptr.count, privateKeyPointer) else {
                throw APNSwiftError.SigningError.invalidSignatureData
            }
            return .init(sig)
        }
        defer { CAPNSwiftBoringSSL_ECDSA_SIG_free(.init(sig)) }

        var rPtr: UnsafePointer<BIGNUM>?
        var sPtr: UnsafePointer<BIGNUM>?
        // as this method is `get0` there is no requirement to free those pointers: ECDSA_SIG will free them for us.
        CAPNSwiftBoringSSL_ECDSA_SIG_get0(.init(sig), &rPtr, &sPtr)

        var rb = [UInt8](repeating: 0, count: Int(CAPNSwiftBoringSSL_BN_num_bits(rPtr) + 7) / 8)
        var sb = [UInt8](repeating: 0, count: Int(CAPNSwiftBoringSSL_BN_num_bits(sPtr) + 7) / 8)
        let lenr = Int(CAPNSwiftBoringSSL_BN_bn2bin(rPtr, &rb))
        let lens = Int(CAPNSwiftBoringSSL_BN_bn2bin(sPtr, &sb))

        var signatureBytes = ByteBufferAllocator().buffer(capacity: lenr + lens)
        let allZeroes = Array(repeating: UInt8(0), count: 32)
        signatureBytes.writeBytes([allZeroes, rb].joined().suffix(32))
        signatureBytes.writeBytes([allZeroes, sb].joined().suffix(32))
        return signatureBytes
    }
}
