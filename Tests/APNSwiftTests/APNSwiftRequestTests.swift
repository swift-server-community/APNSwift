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
import XCTest
@testable import APNSwift


final class APNSwiftRequestTests: XCTestCase {

    func testAlertEncoding() throws {
        let alert = APNSwiftPayload.APNSwiftAlert(title: "title", subtitle: "subtitle", body: "body", titleLocKey: "titlelockey",
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
        let alert = APNSwiftPayload.APNSwiftAlert(title: "title", body: "body")

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

    static var allTests = [
        ("testAlertEncoding", testAlertEncoding),
        ("testMinimalAlertEncoding", testMinimalAlertEncoding)
    ]
}
