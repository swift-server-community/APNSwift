//
//  APNSResponse.swift
//  CNIOAtomics
//
//  Created by Kyle Browning on 2/1/19.
//

import Foundation
import NIO
import NIOHTTP1
internal struct APNSResponse {
    public var header: HTTPResponseHead
    public var data: ByteBuffer?
}
