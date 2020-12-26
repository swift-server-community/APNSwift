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

public struct APNSSoundDictionary: Codable, Equatable {
    public let critical: Int
    public let name: String
    public let volume: Double

    /**
     Initialize an APNSSoundDictionary
     - Parameter critical: The critical alert flag. Set to true to enable the critical alert.
     - Parameter sound: The apps path to a sound file.
     - Parameter volume: The volume for the critical alert’s sound. Set this to a value between 0.0 (silent) and 1.0 (full volume).

     For more information see:
     [Payload Key Reference](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html#)
     ### Usage Example: ###
     ````
     let apsSound = APNSSoundDictionary(isCritical: true, name: "cow.wav", volume: 0.8)
     let aps = APNSwiftPayload(alert: alert, badge: 1, sound: .dictionary(apsSound))
     ````
     */
    public init(isCritical: Bool, name: String, volume: Double) {
        self.critical = isCritical ? 1 : 0
        self.name = name
        self.volume = volume
    }
}
/**
 An enum to define how to use sound.
 - Parameter string: use this for a normal alert sound
 - Parameter critical: use for a critical alert type
 */
public enum APNSwiftSoundType: Codable, Equatable {
    case normal(String)
    case critical(APNSSoundDictionary)
}

extension APNSwiftSoundType {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .normal(let string):
            try container.encode(string)
        case .critical(let dict):
            try container.encode(dict)
        }
    }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let critical = try? container.decode(APNSSoundDictionary.self) {
      self = .critical(critical)
    } else {
      self = .normal(try container.decode(String.self))
    }
  }
}
