//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2019-2020 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging

extension APNSwiftClient {
    internal func logger(from loggerConfig: LoggerConfig) -> Logger? {
        switch loggerConfig {
        case .none:
            return nil
        case .clientLogger:
            return self.logger
        case .custom(let customLogger):
            return customLogger
        }
    }
}

public enum LoggerConfig {
    case none
    case clientLogger
    case custom(Logger)
}
