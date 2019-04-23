//
//  APNSResponseDecoder.swift
//  CNIOAtomics
//
//  Created by Kyle Browning on 2/1/19.
//

import NIO
import NIOHTTP1

/// Internal `ChannelInboundHandler` that parses `HTTPClientResponsePart` to `HTTPResponse`.
internal final class APNSResponseDecoder {
    private enum State {
        /// Waiting to parse the next response.
        case ready
        /// Currently parsing the response's body.
        case parsingBody(HTTPResponseHead, ByteBuffer?)
    }

    private var state: State = .ready
}

extension APNSResponseDecoder: ChannelInboundHandler {
    /// See `ChannelInboundHandler.InboundIn`.
    typealias InboundIn = HTTPClientResponsePart

    /// See `ChannelInboundHandler.OutboundOut`.
    typealias OutboundOut = APNSResponse

    /// See `ChannelInboundHandler.channelRead(context:data:)`.
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let response = unwrapInboundIn(data)
        switch (response, state) {
        case (.head(let head), .ready): state = .parsingBody(head, nil)
        case (.body(var body), .parsingBody(let head, let existingBuffer)):
            guard var existing = existingBuffer else {
                state = .parsingBody(head, body)
                return
            }
            existing.writeBuffer(&body)
            state = .parsingBody(head, existing)
        case (.end(.none), let .parsingBody(head, data)):
            context.fireChannelRead(wrapOutboundOut(APNSResponse(header: head, data: data)))
            state = .ready
        default:
            assertionFailure("Unexpected state! Decoder state: \(state) HTTPResponsePart: \(response)")
        }
    }
}
