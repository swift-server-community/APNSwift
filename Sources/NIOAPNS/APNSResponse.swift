//
//  APNSResponse.swift
//  CNIOAtomics
//
//  Created by Kyle Browning on 2/1/19.
//

import Foundation
import NIOHTTP1
public struct APNSResponse {
    public var header: HTTPResponseHead
    public var data: Data? {
        didSet {
            if let data = data {
                error = try? JSONDecoder().decode(APNSError.self, from: data)
            }
        }
    }
    public var error: APNSError?
    public init(header: HTTPResponseHead, data: Data?) {
        self.header = header
        self.data = data
        if let data = data {
            error = try! JSONDecoder().decode(APNSError.self, from: data)
        }
    }
}
