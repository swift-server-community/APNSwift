//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2020 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

extension APNSwiftPayload {
    @available(*, deprecated, renamed: "APNSwiftAlert")
    public typealias APNSwiftAlert = APNSwift.APNSwiftAlert

    @available(*, deprecated, renamed: "APNSSoundDictionary")
    public typealias APNSSoundDictionary = APNSwift.APNSSoundDictionary

    @available(*, deprecated, renamed: "APNSwiftSoundType")
    public typealias APNSwiftSoundType = APNSwift.APNSwiftSoundType
}
