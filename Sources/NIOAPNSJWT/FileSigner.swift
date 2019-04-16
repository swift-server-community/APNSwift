//
//  FileSigner.swift
//  NIOAPNS
//
//  Created by Kyle Browning on 2/21/19.
//

import Foundation
import CAPNSOpenSSL
public class FileSigner: DataSigner {
    public convenience init(url: URL) throws {
        do {
            try self.init(data: Data(contentsOf: url))
        } catch {
            throw APNSSignatureError.certificateFileDoesNotExist
        }
    }
}
