//
//  FileSigner.swift
//  NIOAPNS
//
//  Created by Kyle Browning on 2/21/19.
//

import Foundation
import CAPNSOpenSSL
public class FileSigner: DataSigner {
    public convenience init (url: URL) throws {
        let data: Data
        do {
            data = try Data.init(contentsOf: url)
        } catch {
            throw APNSTokenError.certificateFileDoesNotExist
        }
       try self.init(data: data)
    }
}
