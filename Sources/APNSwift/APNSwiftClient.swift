import Foundation
import Logging
import NIO

public protocol APNSwiftClient {
    var logger: Logger? { get }

    func send(rawBytes payload: ByteBuffer,
              pushType: APNSwiftConnection.PushType,
              to deviceToken: String,
              expiration: Date?,
              priority: Int?,
              collapseIdentifier: String?,
              topic: String?,
              logger: Logger?) -> EventLoopFuture<Void>
}

extension APNSwiftClient {
    /**
     APNSwiftConnection send method. Sends a notification to the desired deviceToken.
     - Parameter payload: the alert to send.
     - Parameter pushType: push type of the notification.
     - Parameter deviceToken: device token to send alert to.
     - Parameter encoder: customer JSON encoder if needed.
     - Parameter expiration: a date that the notificaiton expires.
     - Parameter priority: priority to send the notification with.
     - Parameter collapseIdentifier: a collapse identifier to use for grouping notifications
     - Parameter topic: the bundle identifier that this notification belongs to.

     For more information see:
     [Retrieve Your App's Device Token](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns#2942135)
     ### Usage Example: ###
     ```
     let apns = APNSwiftConnection.connect()
     let expiry = Date().addingTimeInterval(5)
     try apns.send(notification, pushType: .alert, to: "b27a07be2092c7fbb02ab5f62f3135c615e18acc0ddf39a30ffde34d41665276", with: JSONEncoder(), expiration: expiry, priority: 10, collapseIdentifier: "huro2").wait()
     ```
     */
    public func send(_ alert: APNSwiftPayload.APNSwiftAlert,
                     pushType: APNSwiftConnection.PushType = .alert,
                     to deviceToken: String,
                     with encoder: JSONEncoder = JSONEncoder(),
                     expiration: Date? = nil,
                     priority: Int? = nil,
                     collapseIdentifier: String? = nil,
                     topic: String? = nil,
                     logger: Logger? = nil) -> EventLoopFuture<Void> {
        return self.send(APNSwiftPayload(alert: alert),
                  pushType: pushType,
                  to: deviceToken,
                  with: encoder,
                  expiration: expiration,
                  priority: priority,
                  collapseIdentifier: collapseIdentifier,
                  topic: topic,
                  logger: logger ?? self.logger)
    }

    /**
     APNSwiftConnection send method. Sends a notification to the desired deviceToken.
     - Parameter payload: the payload to send.
     - Parameter pushType: push type of the notification.
     - Parameter deviceToken: device token to send alert to.
     - Parameter encoder: customer JSON encoder if needed.
     - Parameter expiration: a date that the notificaiton expires.
     - Parameter priority: priority to send the notification with.
     - Parameter collapseIdentifier: a collapse identifier to use for grouping notifications
     - Parameter topic: the bundle identifier that this notification belongs to.

     For more information see:
     [Retrieve Your App's Device Token](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns#2942135)
     ### Usage Example: ###
     ```
     let apns = APNSwiftConnection.connect()
     let expiry = Date().addingTimeInterval(5)
     try apns.send(notification, pushType: .alert, to: "b27a07be2092c7fbb02ab5f62f3135c615e18acc0ddf39a30ffde34d41665276", with: JSONEncoder(), expiration: expiry, priority: 10, collapseIdentifier: "huro2").wait()
     ```
     */
    public func send(_ payload: APNSwiftPayload,
                     pushType: APNSwiftConnection.PushType = .alert,
                     to deviceToken: String,
                     with encoder: JSONEncoder = JSONEncoder(),
                     expiration: Date? = nil,
                     priority: Int? = nil,
                     collapseIdentifier: String? = nil,
                     topic: String? = nil,
                     logger: Logger? = nil) -> EventLoopFuture<Void> {
        return self.send(BasicNotification(aps: payload),
                  pushType: pushType,
                  to: deviceToken,
                  with: encoder,
                  expiration: expiration,
                  priority: priority,
                  collapseIdentifier: collapseIdentifier,
                  topic: topic,
                  logger: logger ?? self.logger)
    }

    /**
     APNSwiftConnection send method. Sends a notification to the desired deviceToken.
     - Parameter notification: the notification meta data and alert to send.
     - Parameter pushType: push type of the notification.
     - Parameter deviceToken: device token to send alert to.
     - Parameter encoder: customer JSON encoder if needed.
     - Parameter expiration: a date that the notificaiton expires.
     - Parameter priority: priority to send the notification with.
     - Parameter collapseIdentifier: a collapse identifier to use for grouping notifications
     - Parameter topic: the bundle identifier that this notification belongs to.

     For more information see:
     [Retrieve Your App's Device Token](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns#2942135)
     ### Usage Example: ###
     ```
     let apns = APNSwiftConnection.connect()
     let expiry = Date().addingTimeInterval(5)
     try apns.send(notification, pushType: .alert, to: "b27a07be2092c7fbb02ab5f62f3135c615e18acc0ddf39a30ffde34d41665276", with: JSONEncoder(), expiration: expiry, priority: 10, collapseIdentifier: "huro2").wait()
     ```
     */
    public func send<Notification: APNSwiftNotification>(_ notification: Notification,
                                                         pushType: APNSwiftConnection.PushType,
                                                         to deviceToken: String,
                                                         with encoder: JSONEncoder = JSONEncoder(),
                                                         expiration: Date? = nil,
                                                         priority: Int? = nil,
                                                         collapseIdentifier: String? = nil,
                                                         topic: String? = nil,
                                                         logger: Logger? = nil) -> EventLoopFuture<Void> {
        let data: Data = try! encoder.encode(notification)
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)
        return send(rawBytes: buffer,
                    pushType: pushType,
                    to: deviceToken,
                    expiration: expiration,
                    priority: priority,
                    collapseIdentifier: collapseIdentifier,
                    topic: topic,
                    logger: logger ?? self.logger)
    }
}

private struct BasicNotification: APNSwiftNotification {
    let aps: APNSwiftPayload
}
