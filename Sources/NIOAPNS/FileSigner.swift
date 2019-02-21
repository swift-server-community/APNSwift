//
//  FileSigner.swift
//  NIOAPNS
//
//  Created by Kyle Browning on 2/21/19.
//

import Foundation
import CAPNSOpenSSL
public class FileSigner: DataSigner {
    public convenience init?(url: URL) {
        let data = try! Data.init(contentsOf: url)
        self.init(data: data)
    }
}
