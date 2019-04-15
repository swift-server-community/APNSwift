//
//  SigningMode.swift
//  NIOAPNS
//
//  Created by Kyle Browning on 2/21/19.
//

import Foundation

public struct SigningMode {
    public let signer: APNSSigner
    init(signer: APNSSigner) {
        self.signer = signer
    }
}

extension SigningMode {
    public static func file(path: String) throws -> SigningMode {
        return .init(signer: try FileSigner(url: URL(fileURLWithPath: path)))
    }
    public static func data(data: Data) throws -> SigningMode {
        return .init(signer: try DataSigner(data: data))
    }
    public static func custom(signer: APNSSigner) -> SigningMode {
        return .init(signer: signer)
    }
}
