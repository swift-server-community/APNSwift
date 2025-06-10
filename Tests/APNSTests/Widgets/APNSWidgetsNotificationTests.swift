//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2022 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import APNSCore
import XCTest

final class APNSWidgetsNotificationTests: XCTestCase {
    func testAppID() {
        let widgetsNotification = APNSWidgetsNotification(
            expiration: .none,
            priority: .immediately,
            appID: "com.example.app"
        )

        XCTAssertEqual(widgetsNotification.topic, "com.example.app.push-type.widgets")
    }

    func testEncode() throws {
        let widgetsNotification = APNSWidgetsNotification(
            expiration: .none,
            priority: .immediately,
            appID: "com.example.app"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(widgetsNotification)

        let expectedJSONString = """
        {"aps":{"content-changed":true}}
        """
        let jsonObject1 = try JSONSerialization.jsonObject(with: data) as! NSDictionary
        let jsonObject2 = try JSONSerialization.jsonObject(with: expectedJSONString.data(using: .utf8)!) as! NSDictionary
        XCTAssertEqual(jsonObject1, jsonObject2)
    }

}
