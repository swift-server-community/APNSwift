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

import Foundation
import NIO
import NIOHTTP1
import NIOHTTP2

import XCTest
@testable import APNSwift


final class APNSwiftRequestTests: XCTestCase {

    func testAlertEncoding() throws {
        let alert = APNSwiftAlert(title: "title", subtitle: "subtitle", body: "body", titleLocKey: "titlelockey",
                          titleLocArgs: ["titlelocarg1"], actionLocKey: "actionkey", locKey: "lockey", locArgs: ["locarg1"], launchImage: "launchImage")

        let jsonData = try JSONEncoder().encode(alert)

        let jsonDic = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]

        let keys = jsonDic?.keys

        XCTAssertTrue(keys?.contains("title") ?? false)
        XCTAssertTrue(jsonDic?["title"] is String)

        XCTAssertTrue(keys?.contains("body") ?? false)
        XCTAssertTrue(jsonDic?["body"] is String)

        XCTAssertTrue(keys?.contains("subtitle") ?? false)
        XCTAssertTrue(jsonDic?["subtitle"] is String)

        XCTAssertTrue(keys?.contains("title-loc-key") ?? false)
        XCTAssertTrue(jsonDic?["title-loc-key"] is String)


        XCTAssertTrue(keys?.contains("title-loc-args") ?? false)
        XCTAssertTrue(jsonDic?["title-loc-args"] is [String])

        XCTAssertTrue(keys?.contains("action-loc-key") ?? false)
        XCTAssertTrue(jsonDic?["action-loc-key"] is String)

        XCTAssertTrue(keys?.contains("loc-key") ?? false)
        XCTAssertTrue(jsonDic?["loc-key"] is String)

        XCTAssertTrue(keys?.contains("loc-args") ?? false)
        XCTAssertTrue(jsonDic?["loc-args"] is [String])

        XCTAssertTrue(keys?.contains("launch-image") ?? false)
        XCTAssertTrue(jsonDic?["launch-image"] is String)
    }

    func testMinimalAlertEncoding() throws {
        let alert = APNSwiftAlert(title: "title", body: "body")

        let jsonData = try JSONEncoder().encode(alert)

        let jsonDic = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]

        let keys = jsonDic?.keys

        XCTAssertTrue(keys?.contains("title") ?? false)
        XCTAssertTrue(jsonDic?["title"] is String)

        XCTAssertTrue(keys?.contains("body") ?? false)
        XCTAssertTrue(jsonDic?["body"] is String)

        XCTAssertFalse(keys?.contains("subtitle") ?? false)
        XCTAssertFalse(keys?.contains("title-loc-key") ?? false)
        XCTAssertFalse(keys?.contains("title-loc-args") ?? false)
        XCTAssertFalse(keys?.contains("action-loc-key") ?? false)
        XCTAssertFalse(keys?.contains("loc-key") ?? false)
        XCTAssertFalse(keys?.contains("loc-args") ?? false)
        XCTAssertFalse(keys?.contains("launch-image") ?? false)
    }
  func testMinimalSwiftPayloadEncoding() throws {
      let payload = APNSwiftPayload(alert: nil, sound: .normal("pong.wav"))

      let jsonData = try JSONEncoder().encode(payload)

      let jsonDic = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]

      let keys = jsonDic?.keys

      XCTAssertTrue(keys?.contains("sound") ?? false)
      XCTAssertTrue(jsonDic?["sound"] is String)
      XCTAssertTrue(jsonDic?["sound"] as! String == "pong.wav")

      XCTAssertFalse(keys?.contains("title") ?? false)
      XCTAssertFalse(keys?.contains("body") ?? false)
      XCTAssertFalse(keys?.contains("subtitle") ?? false)
      XCTAssertFalse(keys?.contains("title-loc-key") ?? false)
      XCTAssertFalse(keys?.contains("title-loc-args") ?? false)
      XCTAssertFalse(keys?.contains("action-loc-key") ?? false)
      XCTAssertFalse(keys?.contains("loc-key") ?? false)
      XCTAssertFalse(keys?.contains("loc-args") ?? false)
      XCTAssertFalse(keys?.contains("launch-image") ?? false)
  }

  func testMinimalSwiftPayloadDecoding() throws {
      let payload = APNSwiftPayload(alert: APNSwiftAlert(title: "title", body: "body"), sound: .normal("pong.wav"))

      let jsonData = try JSONEncoder().encode(payload)
      let decodedPayload = try JSONDecoder().decode(APNSwiftPayload.self, from: jsonData)

      XCTAssertEqual(payload.alert?.title, decodedPayload.alert?.title)
      XCTAssertEqual(payload.alert?.body, decodedPayload.alert?.body)
      XCTAssertEqual(payload.sound, decodedPayload.sound)
  }

    func testResponseDecoderBasics() throws {
        let channel = EmbeddedChannel(handler: APNSwiftResponseDecoder())

        // pretend to connect the connect (nothing real will happen)
        XCTAssertNoThrow(try channel.connect(to: .init(ipAddress: "1.2.3.4", port: 5)).wait())

        // send a valid server response
        let resHead = HTTPResponseHead(version: .init(major: 2, minor: 0), status: .ok)
        XCTAssertNoThrow(try channel.writeInbound(HTTPClientResponsePart.head(resHead)))
        var buffer = channel.allocator.buffer(capacity: 16)
        buffer.writeString("foo bar")
        XCTAssertNoThrow(try channel.writeInbound(HTTPClientResponsePart.body(buffer)))
        XCTAssertNoThrow(try channel.writeInbound(HTTPClientResponsePart.end(nil)))

        // now, let's check that we read the response correctly
        let maybeResponse = try channel.readInbound(as: APNSwiftResponse.self)
        guard let response = maybeResponse else {
            XCTFail("no response produced")
            return
        }
        XCTAssertEqual(APNSwiftResponse(header: resHead, byteBuffer: buffer), response)

        // finally, let's check that there's no other stuff produced on the channel
        XCTAssertNoThrow(XCTAssertNil(try channel.readInbound(as: APNSwiftResponse.self)))
        XCTAssertNoThrow(XCTAssertTrue(try channel.finish().isClean))
    }

    func testResponseDecoderHappyWithReceivingTheBodyInMultipleChunks() throws {
        let channel = EmbeddedChannel(handler: APNSwiftResponseDecoder())

        // pretend to connect the connect (nothing real will happen)
        XCTAssertNoThrow(try channel.connect(to: .init(ipAddress: "1.2.3.4", port: 5)).wait())

        // send a valid server response
        let resHead = HTTPResponseHead(version: .init(major: 2, minor: 0), status: .ok)
        XCTAssertNoThrow(try channel.writeInbound(HTTPClientResponsePart.head(resHead)))
        var buffer = channel.allocator.buffer(capacity: 16)
        buffer.writeString("foo bar")
        XCTAssertNoThrow(try channel.writeInbound(HTTPClientResponsePart.body(buffer.getSlice(at: buffer.readerIndex,
                                                                                              length: 3)!)))
        XCTAssertNoThrow(try channel.writeInbound(HTTPClientResponsePart.body(buffer.getSlice(at: buffer.readerIndex + 3,
                                                                                              length: 4)!)))

        XCTAssertNoThrow(try channel.writeInbound(HTTPClientResponsePart.end(nil)))

        // now, let's check that we read the response correctly
        let maybeResponse = try channel.readInbound(as: APNSwiftResponse.self)
        guard let response = maybeResponse else {
            XCTFail("no response produced")
            return
        }
        XCTAssertEqual(APNSwiftResponse(header: resHead, byteBuffer: buffer), response)

        // finally, let's check that there's no other stuff produced on the channel
        XCTAssertNoThrow(XCTAssertNil(try channel.readInbound(as: APNSwiftResponse.self)))
        XCTAssertNoThrow(XCTAssertTrue(try channel.finish().isClean))
    }

    func testResponseDecoderAcceptsTrailers() throws {
        let channel = EmbeddedChannel(handler: APNSwiftResponseDecoder())

        // pretend to connect the connect (nothing real will happen)
        XCTAssertNoThrow(try channel.connect(to: .init(ipAddress: "1.2.3.4", port: 5)).wait())

        // send a valid server response
        let resHead = HTTPResponseHead(version: .init(major: 2, minor: 0), status: .ok)
        XCTAssertNoThrow(try channel.writeInbound(HTTPClientResponsePart.head(resHead)))
        var buffer = channel.allocator.buffer(capacity: 16)
        buffer.writeString("foo bar")
        XCTAssertNoThrow(try channel.writeInbound(HTTPClientResponsePart.body(buffer)))
        XCTAssertNoThrow(try channel.writeInbound(HTTPClientResponsePart.end(["foo": "bar"])))

        // now, let's check that we read the response correctly
        let maybeResponse = try channel.readInbound(as: APNSwiftResponse.self)
        guard let response = maybeResponse else {
          XCTFail("no response produced")
          return
        }
        XCTAssertEqual(APNSwiftResponse(header: resHead, byteBuffer: buffer), response)

        // finally, let's check that there's no other stuff produced on the channel
        XCTAssertNoThrow(XCTAssertNil(try channel.readInbound(as: APNSwiftResponse.self)))
        XCTAssertNoThrow(XCTAssertTrue(try channel.finish().isClean))
    }

    func testErrorsFromAPNS() throws {
        let error = APNSwiftError.ResponseStruct(reason: .unregistered)
        let encodedData = try JSONEncoder().encode(error)
        let allocator = ByteBufferAllocator()
        var errorBuffer = allocator.buffer(capacity: encodedData.count)
        errorBuffer.writeBytes(encodedData)
        
        let responsefromAPNS = APNSwiftResponse(header: .init(version: .init(major: 2, minor: 0), status: .badRequest), byteBuffer: errorBuffer)
        
        let channel = EmbeddedChannel(handler: APNSwiftStreamHandler())
        let responsePromise = channel.eventLoop.makePromise(of: Void.self)
        let context = APNSwiftRequestContext(
           request: errorBuffer,
           responsePromise: responsePromise
        )
        try channel.writeOutbound(context)
        try channel.writeInbound(responsefromAPNS)
        responsePromise.futureResult.whenComplete { temp in
            switch temp {
            case .failure(let error):
                let error = error as! APNSwiftError.ResponseError
                let expected = APNSwiftError.ResponseError.badRequest(.unregistered)
                if error != expected {
                    XCTFail("response is: \(error), should be: \(expected)")
                }
            default:
                XCTFail("response should not succeed")
            }
        }
        XCTAssertNoThrow(XCTAssertNotNil(try channel.readOutbound()))
        XCTAssertNoThrow(XCTAssertTrue(try channel.finish().isClean))

    }
    
    func testErrorsFromAPNSLeak() throws {
        let encodedData = try JSONEncoder().encode(["test string"])
        let allocator = ByteBufferAllocator()
        var errorBuffer = allocator.buffer(capacity: encodedData.count)
        errorBuffer.writeBytes(encodedData)
              
        let channel = EmbeddedChannel(handler: APNSwiftStreamHandler())
        let responsePromise = channel.eventLoop.makePromise(of: Void.self)
        let context = APNSwiftRequestContext(
           request: errorBuffer,
           responsePromise: responsePromise
        )
        try channel.writeOutbound(context)
        responsePromise.futureResult.whenComplete { temp in
            switch temp {
            case .failure(let error):
                let error = error as! NoResponseReceivedBeforeConnectionEnded
                let expected = NoResponseReceivedBeforeConnectionEnded()
                if error != expected {
                    XCTFail("response is: \(error), should be: \(expected)")
                }
            default:
                XCTFail("response should not succeed")
            }
        }
        XCTAssertNoThrow(XCTAssertNotNil(try channel.readOutbound()))
        XCTAssertNoThrow(XCTAssertTrue(try channel.finish().isClean))
    }
    
    func testTokenProviderUpdate() throws {
        let apnsConfig = try APNSwiftConfiguration(
            authenticationMethod: .jwt(
                key: .private(pem: Data(validAuthKey.utf8)),
                keyIdentifier: "9UC9ZLQ8YW",
                teamIdentifier: "ABBM6U9RM5"
            ),
            topic: "com.grasscove.Fern",
            environment: .sandbox
        )
        let loop = EmbeddedEventLoop()
        let bearerToken = apnsConfig.makeBearerTokenFactory(on: loop)!
        let cachedToken = bearerToken.currentBearerToken


        loop.advanceTime(by: .seconds(2))
        
        XCTAssertTrue(cachedToken == bearerToken.currentBearerToken)

        loop.advanceTime(by: .seconds(7))
        XCTAssertTrue(cachedToken == bearerToken.currentBearerToken)
        
        loop.advanceTime(by: .minutes(45))
        XCTAssertTrue(cachedToken == bearerToken.currentBearerToken)
        // Advanced past 55 minute mark.
        loop.advanceTime(by: .minutes(10))
        XCTAssertFalse(cachedToken == bearerToken.currentBearerToken)
        // should have changed
        let newCachedToken = bearerToken.currentBearerToken
        loop.advanceTime(by: .minutes(15))
        // Should not have changed
        XCTAssertTrue(newCachedToken == bearerToken.currentBearerToken)
        loop.advanceTime(by: .minutes(55))
        // Should have changed
        XCTAssertFalse(newCachedToken == bearerToken.currentBearerToken)
        bearerToken.cancel()
        
    }

    let validAuthKey = """
    -----BEGIN PRIVATE KEY-----
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg2sD+kukkA8GZUpmm
    jRa4fJ9Xa/JnIG4Hpi7tNO66+OGgCgYIKoZIzj0DAQehRANCAATZp0yt0btpR9kf
    ntp4oUUzTV0+eTELXxJxFvhnqmgwGAm1iVW132XLrdRG/ntlbQ1yzUuJkHtYBNve
    y+77Vzsd
    -----END PRIVATE KEY-----
    """
    let invalidAuthKey = ""
}
