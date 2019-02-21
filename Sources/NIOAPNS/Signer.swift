//
//  APNSSigner.swift
//  NIOAPNS
//
//  Created by Kyle Browning on 2/21/19.
//

import Foundation

// Protocol for signing digests
public protocol APNSSigner {
    func sign(digest: Data) throws -> Data
    func verify(digest: Data, signature: Data) -> Bool
}
