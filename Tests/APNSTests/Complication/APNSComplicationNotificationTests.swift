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

final class APNSComplicationNotificationTests: XCTestCase {
    func testAppID() {
        struct Payload: Encodable {
            let foo = "bar"
        }
        let complicationNotification = APNSComplicationNotification(
            expiration: .immediately,
            priority: .immediately,
            appID: "com.example.app",
            payload: Payload()
        )

        XCTAssertEqual(complicationNotification.topic, "com.example.app.complication")
    }
}
