//===----------------------------------------------------------------------===//
//
// This source file is part of the NIOApns open source project
//
// Copyright (c) 2019 the NIOApns project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of NIOApns project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

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
