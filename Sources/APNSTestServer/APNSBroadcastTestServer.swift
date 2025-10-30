//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2024 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore
import NIOPosix
import NIOHTTP1
import struct Foundation.UUID
import struct Foundation.Data
import class Foundation.JSONSerialization

/// A lightweight mock server that simulates Apple's broadcast push notification API.
///
/// This server is useful for testing APNSBroadcastClient without hitting real Apple servers.
/// It maintains an in-memory store of channels and responds to all standard operations:
/// - POST /channels (create)
/// - GET /channels (list all)
/// - GET /channels/{id} (read)
/// - DELETE /channels/{id} (delete)
public final class APNSBroadcastTestServer: @unchecked Sendable {
    private let group: EventLoopGroup
    private var channel: Channel?
    private var channels: [String: MockChannel] = [:]

    public var port: Int {
        guard let channel = channel else {
            return 0
        }
        return channel.localAddress?.port ?? 0
    }

    struct MockChannel: Codable {
        let channelID: String
        let messageStoragePolicy: Int

        enum CodingKeys: String, CodingKey {
            case channelID = "channel-id"
            case messageStoragePolicy = "message-storage-policy"
        }
    }

    public init() {
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }

    /// Starts the server on the specified port.
    public func start(port: Int = 0) async throws {
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(BroadcastRequestHandler(server: self))
                }
            }

        self.channel = try await bootstrap.bind(host: "127.0.0.1", port: port).get()
    }

    /// Stops the server.
    public func shutdown() async throws {
        try await channel?.close()
        try await group.shutdownGracefully()
    }

    fileprivate func handleRequest(method: HTTPMethod, uri: String, body: ByteBuffer?) -> (status: HTTPResponseStatus, body: String) {
        // Parse the URI
        let components = uri.split(separator: "/")

        switch (method, components.count) {
        case (.POST, 1) where components[0] == "channels":
            // Create channel
            return createChannel(body: body)

        case (.GET, 1) where components[0] == "channels":
            // List all channels
            return listChannels()

        case (.GET, 2) where components[0] == "channels":
            // Read specific channel
            let channelID = String(components[1])
            return readChannel(channelID: channelID)

        case (.DELETE, 2) where components[0] == "channels":
            // Delete specific channel
            let channelID = String(components[1])
            return deleteChannel(channelID: channelID)

        default:
            return (.notFound, "{\"reason\":\"NotFound\"}")
        }
    }

    private func createChannel(body: ByteBuffer?) -> (status: HTTPResponseStatus, body: String) {
        guard var body = body else {
            return (.badRequest, "{\"reason\":\"BadRequest\"}")
        }

        guard let bytes = body.readBytes(length: body.readableBytes) else {
            return (.badRequest, "{\"reason\":\"BadRequest\"}")
        }

        let data = Data(bytes)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let policy = json["message-storage-policy"] as? Int else {
            return (.badRequest, "{\"reason\":\"BadRequest\"}")
        }

        let channelID = UUID().uuidString
        let channel = MockChannel(channelID: channelID, messageStoragePolicy: policy)
        channels[channelID] = channel

        let responseJSON = """
        {"channel-id":"\(channelID)","message-storage-policy":\(policy)}
        """
        return (.created, responseJSON)
    }

    private func listChannels() -> (status: HTTPResponseStatus, body: String) {
        let channelIDs = Array(channels.keys)
        let channelsJSON = channelIDs.map { "\"\($0)\"" }.joined(separator: ",")
        return (.ok, "{\"channels\":[\(channelsJSON)]}")
    }

    private func readChannel(channelID: String) -> (status: HTTPResponseStatus, body: String) {
        guard let channel = channels[channelID] else {
            return (.notFound, "{\"reason\":\"NotFound\"}")
        }

        let responseJSON = """
        {"channel-id":"\(channel.channelID)","message-storage-policy":\(channel.messageStoragePolicy)}
        """
        return (.ok, responseJSON)
    }

    private func deleteChannel(channelID: String) -> (status: HTTPResponseStatus, body: String) {
        guard channels.removeValue(forKey: channelID) != nil else {
            return (.notFound, "{\"reason\":\"NotFound\"}")
        }

        return (.ok, "{}")
    }
}

private final class BroadcastRequestHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private let server: APNSBroadcastTestServer
    private var method: HTTPMethod?
    private var uri: String?
    private var bodyBuffer: ByteBuffer?

    init(server: APNSBroadcastTestServer) {
        self.server = server
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = unwrapInboundIn(data)

        switch part {
        case .head(let head):
            self.method = head.method
            self.uri = head.uri
            self.bodyBuffer = nil

        case .body(var buffer):
            if self.bodyBuffer == nil {
                self.bodyBuffer = buffer
            } else {
                self.bodyBuffer?.writeBuffer(&buffer)
            }

        case .end:
            guard let method = self.method, let uri = self.uri else {
                return
            }

            let (status, body) = server.handleRequest(method: method, uri: uri, body: bodyBuffer)

            var headers = HTTPHeaders()
            headers.add(name: "content-type", value: "application/json")
            headers.add(name: "content-length", value: String(body.utf8.count))
            headers.add(name: "apns-request-id", value: UUID().uuidString)

            let responseHead = HTTPResponseHead(version: .http1_1, status: status, headers: headers)
            context.write(wrapOutboundOut(.head(responseHead)), promise: nil)

            var buffer = context.channel.allocator.buffer(capacity: body.utf8.count)
            buffer.writeString(body)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)

            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)

            self.method = nil
            self.uri = nil
            self.bodyBuffer = nil
        }
    }
}
