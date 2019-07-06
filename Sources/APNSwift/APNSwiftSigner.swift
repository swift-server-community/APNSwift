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
            Int(BIO_puts(bio, ptr.baseAddress?.assumingMemoryBound(to: Int8.self)))
        }
        assert(res >= 0, "BIO_puts failed")

        guard let opaquePointer = OpaquePointer.make(optional: PEM_read_bio_ECPrivateKey(bio!, nil, nil, nil)) else {
            throw APNSwiftError.SigningError.invalidAuthKey
        }
        defer { EC_KEY_free(opaquePointer) }
        
        let sig = digest.withUnsafeReadableBytes { ptr in
            ECDSA_do_sign(ptr.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(digest.readableBytes), opaquePointer)
        }
        defer { ECDSA_SIG_free(sig) }

        var derEncodedSignature: UnsafeMutablePointer<UInt8>?
        let derLength = i2d_ECDSA_SIG(sig, &derEncodedSignature)
        guard let derCopy = derEncodedSignature, derLength > 0 else {
            throw APNSwiftError.SigningError.invalidASN1
        }

        var derBytes = ByteBufferAllocator().buffer(capacity: Int(derLength))
        for b in 0 ..< Int(derLength) {
            derBytes.writeBytes([derCopy[b]])
        }

        return derBytes
    }
}
