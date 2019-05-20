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
import CAPNSOpenSSL
import NIO

// Protocol for signing digests
public protocol APNSSigner {
    func sign(digest: ByteBuffer) throws -> ByteBuffer
}
public struct APNSSigners {
    public enum SigningMode {
        case file(String)
        case data(ByteBuffer)
        case custom(APNSSigner)
    }
    public class DataSigner: APNSSigner {
        private let opaqueKey: OpaquePointer

        public init(buffer: ByteBuffer) throws {
            let bio = BIO_new(BIO_s_mem())
            defer { BIO_free(bio) }
            let res = buffer.withUnsafeReadableBytes { ptr in
                Int(BIO_puts(bio, ptr.baseAddress?.assumingMemoryBound(to: Int8.self)))
            }
            assert(res >= 0, "BIO_puts failed")

            if let pointer = OpaquePointer.make(optional: PEM_read_bio_ECPrivateKey(bio!, nil, nil, nil)) {
                opaqueKey = pointer
            } else {
                throw APNSError.SigningError.invalidAuthKey
            }
        }
        deinit {
            EC_KEY_free(opaqueKey)
        }

        public func sign(digest: ByteBuffer) throws -> ByteBuffer {
            let sig = digest.withUnsafeReadableBytes { ptr in
                ECDSA_do_sign(ptr.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(digest.readableBytes), opaqueKey)
            }
            defer { ECDSA_SIG_free(sig) }

            var derEncodedSignature: UnsafeMutablePointer<UInt8>?
            let derLength = i2d_ECDSA_SIG(sig, &derEncodedSignature)

            guard let derCopy = derEncodedSignature, derLength > 0 else {
                throw APNSError.SigningError.invalidASN1
            }

            var derBytes = ByteBufferAllocator().buffer(capacity: Int(derLength))
            for b in 0 ..< Int(derLength) {
                derBytes.writeBytes([derCopy[b]])
            }

            return derBytes
        }
    }
    public class FileSigner: DataSigner {
        public convenience init(url: URL) throws {
            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                throw APNSError.SigningError.certificateFileDoesNotExist
            }
            var byteBuffer = ByteBufferAllocator().buffer(capacity: data.count)
            byteBuffer.writeBytes(data)
            try self.init(buffer: byteBuffer)
        }
    }
}

extension APNSSigners.SigningMode {
    public func sign(_ digest: ByteBuffer) throws -> ByteBuffer {
        switch self {
        case .file(let filePath):
            return try APNSSigners.FileSigner(url: URL(fileURLWithPath: filePath)).sign(digest: digest)
        case .data(let data):
            return try APNSSigners.DataSigner(buffer: data).sign(digest: data)
        case .custom(let signer):
            return try signer.sign(digest: digest)
        }
    }
}
