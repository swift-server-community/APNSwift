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

public protocol APNSLiveActivityNotificationEvent: Hashable, Encodable {
    var rawValue: String { get }
}

public struct APNSLiveActivityNotificationEventUpdate: APNSLiveActivityNotificationEvent {
    public let rawValue = "update"
}

public struct APNSLiveActivityNotificationEventEnd: APNSLiveActivityNotificationEvent {
    public let rawValue = "end"
}

public protocol APNSLiveActivityNotificationEventStartStateProtocol: Encodable & Hashable & Sendable
{
    associatedtype State: Encodable & Hashable & Sendable
}

public struct APNSLiveActivityNotificationEventStart<State: Encodable & Hashable & Sendable>:
    APNSLiveActivityNotificationEvent, APNSLiveActivityNotificationEventStartStateProtocol
{
    public struct Attributes: Encodable, Hashable, Sendable {
        public let type: String
        public let state: State

        public init(type: String, state: State) {
            self.type = type
            self.state = state
        }
    }

    public let rawValue = "start"
    public let attributes: Attributes
    public let alert: APNSAlertNotificationContent

    public init(attributes: Attributes, alert: APNSAlertNotificationContent) {
        self.attributes = attributes
        self.alert = alert
    }
}

extension APNSLiveActivityNotificationEvent where Self == APNSLiveActivityNotificationEventUpdate {
    public static var update: APNSLiveActivityNotificationEventUpdate {
        APNSLiveActivityNotificationEventUpdate()
    }
}

extension APNSLiveActivityNotificationEvent where Self == APNSLiveActivityNotificationEventEnd {
    public static var end: APNSLiveActivityNotificationEventEnd {
        APNSLiveActivityNotificationEventEnd()
    }
}

extension APNSLiveActivityNotificationEvent
where Self: APNSLiveActivityNotificationEventStartStateProtocol {
    public static func start(type: String, state: State, alert: APNSAlertNotificationContent)
        -> APNSLiveActivityNotificationEventStart<
            State
        >
    {
        .init(attributes: .init(type: type, state: state), alert: alert)
    }
}
