//
//  LiveActivityNotificationEvent.swift
//  PushSender
//
//  Created by csms on 20/09/2022.
//

import Foundation

public struct LiveActivityNotificationEvent: Hashable {
    
    /// The underlying raw value that is send to APNs.
    @usableFromInline
    internal let rawValue: String
    
    // Specifies that live activity should be updated
    public static let update = Self(rawValue: "update")
    
    // Specifies that live activity should be ended
    public static let end = Self(rawValue: "end")
}
