//
//  DataSigner.swift
//  NIOAPNS
//
//  Created by Kyle Browning on 2/21/19.
//
import Foundation
import CAPNSOpenSSL

public class DataSigner: APNSSigner {
    private let opaqueKey: OpaquePointer

    public init(data: Data) throws {
        let bio = BIO_new(BIO_s_mem())
        defer { BIO_free(bio) }

        let nullTerminatedData = data + Data([0])
        let res = nullTerminatedData.withUnsafeBytes { ptr in
            return BIO_puts(bio, ptr.baseAddress?.assumingMemoryBound(to: Int8.self))
        }
        assert(res >= 0, "BIO_puts failed")

        if let pointer  = PEM_read_bio_ECPrivateKey(bio!, nil, nil, nil) {
            self.opaqueKey = pointer
        } else {
            throw APNSTokenError.invalidAuthKey
        }
    }

    deinit {
        EC_KEY_free(opaqueKey)
    }

    public func sign(digest: Data) throws -> Data  {
        let sig = digest.withUnsafeBytes { ptr in
            return ECDSA_do_sign(ptr.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(digest.count), opaqueKey)
        }
        defer { ECDSA_SIG_free(sig) }

        var derEncodedSignature: UnsafeMutablePointer<UInt8>? = nil
        let derLength = i2d_ECDSA_SIG(sig, &derEncodedSignature)
        
        guard let _ = derEncodedSignature, derLength > 0 else {
            throw APNSSignatureError.invalidASN1
        }
        
        // Force unwrap because guard protects us.
        return Data(bytesNoCopy: derEncodedSignature!,
                    count: Int(derLength),
                    deallocator: .custom({ pointer, length in CRYPTO_free(pointer, nil, 0) }))
    }

    public func verify(digest: Data, signature: Data) -> Bool {
        var signature = signature
        let sig = signature.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> UnsafeMutablePointer<ECDSA_SIG> in
            var copy = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self)
            return d2i_ECDSA_SIG(nil, &copy, signature.count)
        }

        defer { ECDSA_SIG_free(sig) }

        let result = digest.withUnsafeBytes { ptr in
            return ECDSA_do_verify(ptr.baseAddress?.assumingMemoryBound(to: UInt8.self), Int32(digest.count), sig, opaqueKey)
        }

        return result == 1
    }
}
