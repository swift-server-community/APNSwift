//
//  SigningMode.swift
//  NIOAPNS
//
//  Created by Kyle Browning on 2/21/19.
//

import Foundation

/// Specifies options to sign with
public enum SigningMode {
    /// Use a custom Signer.
    case custom(Signer)
    /// Use file Signer.
    case file(String)
    /// Use data Signer
    case data(Data)
}
