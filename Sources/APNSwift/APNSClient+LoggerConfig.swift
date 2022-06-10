//
//  APNSwiftClient+LoggerConfig.swift
//  
//
//  Created by Kyle Browning on 6/10/22.
//

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
