import NIO
import NIOHTTP1
import NIOHTTP2
import NIOOpenSSL
import NIOAPNS
import Foundation

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
var verbose = true

let apnsConfig = APNSConfiguration(keyIdentifier: "2M7SG2MR8K",
                                   teamIdentifier: "ABBM6U9RM5",
                                   signingMode: try .file(path: "/Users/kylebrowning/Downloads/key.p8"),
                                   topic: "com.grasscove.Fern",
                                   environment: .sandbox)

let apns = try APNSConnection.connect(configuration: apnsConfig, on: group.next()).wait()

if verbose {
    print("* Connected to \(apnsConfig.url.host!) (\(apns.channel.remoteAddress!)")
}

struct AcmeNotification: APNSNotificationProtocol {
    let acme2: [String]
    let aps: APSPayload
    
    init(acme2: [String], aps: APSPayload) {
        self.acme2 = acme2
        self.aps = aps
    }
}


let alert = Alert(title: "Hey There", subtitle: "Subtitle", body: "Body")
let aps = APSPayload(alert: alert, category: nil, badge: 1)
let notification = AcmeNotification(acme2: ["bang", "whiz"], aps: aps)

let res = try apns.send(notification, to: "223a86bdd22598fb3a76ce12eafd590c86592484539f9b8526d0e683ad10cf4f").wait()
print("APNS response: \(res)")

try apns.close().wait()
try group.syncShutdownGracefully()
exit(0)
