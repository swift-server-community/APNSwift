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

public protocol APNSLiveActivityNotificationEventStartStateProtocol: Encodable & Hashable & Sendable {
	associatedtype State: Encodable & Hashable & Sendable
}

public struct APNSLiveActivityNotificationEventStart<State: Encodable & Hashable & Sendable>: APNSLiveActivityNotificationEvent, APNSLiveActivityNotificationEventStartStateProtocol {
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

	public init(attributes: Attributes) {
		self.attributes = attributes
	}
}

public extension APNSLiveActivityNotificationEvent where Self == APNSLiveActivityNotificationEventUpdate {
	static var update: APNSLiveActivityNotificationEventUpdate { APNSLiveActivityNotificationEventUpdate() }
}

public extension APNSLiveActivityNotificationEvent where Self == APNSLiveActivityNotificationEventEnd {
	static var end: APNSLiveActivityNotificationEventEnd { APNSLiveActivityNotificationEventEnd() }
}

public extension APNSLiveActivityNotificationEvent where Self: APNSLiveActivityNotificationEventStartStateProtocol {
	static func start(type: String, state: State) -> APNSLiveActivityNotificationEventStart<State> {
		.init(attributes: .init(type: type, state: state))
	}
}
