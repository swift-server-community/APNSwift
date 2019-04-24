import NIO
import NIOHTTP1
import NIOHTTP2
import NIOSSL
import NIOAPNS
import Foundation

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
var verbose = true
let apnsConfig = try APNSConfiguration(keyIdentifier: "9UC9ZLQ8YW",
                                   teamIdentifier: "ABBM6U9RM5",
                                   signingMode: .file(path: "/Users/kylebrowning/Downloads/AuthKey_9UC9ZLQ8YW.p8"),
                                   topic: "com.grasscove.Fern",
                                   environment: .sandbox)

let apns = try APNSConnection.connect(configuration: apnsConfig, on: group.next()).wait()

if verbose {
    print("* Connected to \(apnsConfig.url.host!) (\(apns.channel.remoteAddress!)")
}

struct AcmeNotification: APNSNotification {
    let acme2: [String]
    let aps: APSPayload
    
    init(acme2: [String], aps: APSPayload) {
        self.acme2 = acme2
        self.aps = aps
    }
}


let alert = Alert(title: "Hey There", subtitle: "Subtitle", body: "Body")
let aps = APSPayload(alert: alert, badge: 1)
let notification = AcmeNotification(acme2: ["bang", "whiz"], aps: aps)

do {
    try apns.send(notification, to: "de1d666223de85db0186f654852cc960551125ee841ca044fdf5ef6a4756a77e").wait()
} catch (let error) {
    print(error)
}

try apns.close().wait()
try group.syncShutdownGracefully()
exit(0)
