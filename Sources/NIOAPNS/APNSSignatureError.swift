//
//  Errors.swift
//  CNIOAtomics
//
//  Created by Kyle Browning on 1/10/19.
//  Copyright © 2019 Kyle Browning. All rights reserved.
//

import Foundation
public enum APNSSignatureError: Error {
    case invalidP8
    case invalidASN1
}

extension APNSSignatureError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidP8:
            return "The .p8 string has invalid format."
        case .invalidASN1:
            return "The ASN.1 data has invalid format."
        }
    }
}
