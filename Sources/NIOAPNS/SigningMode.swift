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
    public static func file(path: String) -> SigningMode {
        return .init(signer: FileSigner(url: URL(fileURLWithPath: path))!)
    }
    public static func data(data: Data) -> SigningMode {
        return .init(signer: DataSigner(data: data)!)
    }
    public static func custom(signer: APNSSigner) -> SigningMode {
        return .init(signer: signer)
    }
}
