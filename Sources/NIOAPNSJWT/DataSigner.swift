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
            throw APNSSignatureError.invalidAuthKey
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
        
        guard let derCopy = derEncodedSignature, derLength > 0 else {
            throw APNSSignatureError.invalidASN1
        }

        var derBytes = [UInt8](repeating: 0, count: Int(derLength))

        for b in 0..<Int(derLength) {
            derBytes[b] = derCopy[b]
        }

        return Data(derBytes)

    }
}
