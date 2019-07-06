//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2019 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIO
import NIOHTTP1

/// Internal `ChannelInboundHandler` that parses `HTTPClientResponsePart` to `HTTPResponse`.
internal final class APNSwiftResponseDecoder {
    private enum State {
        /// Waiting to parse the next response.
        case ready
        /// Currently parsing the response's body.
        case parsingBody(HTTPResponseHead, ByteBuffer?)
    }

    private var state: State = .ready
}

/// This extension allows our APNSwiftResponseDecoder to parse our the body that Apple provides

extension APNSwiftResponseDecoder: ChannelInboundHandler {
    /// See `ChannelInboundHandler.InboundIn`.
    typealias InboundIn = HTTPClientResponsePart

    /// See `ChannelInboundHandler.OutboundOut`.
    typealias OutboundOut = APNSwiftResponse

    /// See `ChannelInboundHandler.channelRead(context:data:)`.
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let response = unwrapInboundIn(data)
        switch (response, state) {
        case (let .head(head), .ready): state = .parsingBody(head, nil)
        case (var .body(body), let .parsingBody(head, existingBuffer)):
            guard var existing = existingBuffer else {
                state = .parsingBody(head, body)
                return
            }
            existing.writeBuffer(&body)
            state = .parsingBody(head, existing)
        case (.end(.none), let .parsingBody(head, data)):
            context.fireChannelRead(wrapOutboundOut(APNSwiftResponse(header: head, byteBuffer: data)))
            state = .ready
        default:
            assertionFailure("Unexpected state! Decoder state: \(state) HTTPResponsePart: \(response)")
        }
    }
}
