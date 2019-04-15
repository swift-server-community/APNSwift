//
//  Data+Bas64URL.swift
//  Kyle Browning
//
//  Created by Kyle Browning on 1/10/19.
//

import Foundation

extension Data {
    func base64EncodedURLString() -> String {
        let result = self.base64EncodedString()
        return result.replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    init?(base64EncodedURL: String) {
        let paddingLength = 4 - base64EncodedURL.count % 4
        let padding = (paddingLength < 4) ? String(repeating: "=", count: paddingLength) : ""
        let base64EncodedString = base64EncodedURL
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            + padding
        self.init(base64Encoded: base64EncodedString)
    }

}
