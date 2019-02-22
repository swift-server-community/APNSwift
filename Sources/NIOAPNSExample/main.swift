import NIO
import NIOHTTP1
import NIOHTTP2
import NIOOpenSSL
import NIOAPNS
import Foundation

let sslContext = try SSLContext(configuration: TLSConfiguration.forClient(applicationProtocols: ["h2"]))
let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
var verbose = true

let apnsConfig = APNSConfig(keyId: "9UC9ZLQ8YW",
                            teamId: "ABBM6U9RM5",
                            signingMode: .file(path: "/Users/kylebrowning/Downloads/key.p8"),
                            topic: "com.grasscove.Fern",
                            env: .sandbox)

let apns = try APNSConnection.connect(apnsConfig: apnsConfig, on: group.next()).wait()

if verbose {
    print("* Connected to \(apnsConfig.getUrl().host!) (\(apns.channel.remoteAddress!)")
}

let alert = Alert(title: "Hey There", subtitle: "Subtitle", body: "Body")
let aps = Aps(alert: alert, category: nil, badge: 1)
let res = try apns.send(deviceToken: "223a86bdd22598fb3a76ce12eafd590c86592484539f9b8526d0e683ad10cf4f", APNSRequest(aps: aps, custom: nil)).wait()
print("APNS response: \(res)")

try apns.close().wait()
try group.syncShutdownGracefully()
exit(0)
