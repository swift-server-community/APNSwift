import NIO
import NIOHTTP1
import NIOHTTP2
import NIOOpenSSL
import Foundation

let sslContext = try SSLContext(configuration: TLSConfiguration.forClient(applicationProtocols: ["h2"]))
let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
var verbose = true
let urlString = "https://api.development.push.apple.com"
guard let url = URL.init(string: urlString) else {
    print("ERROR: URL '\(urlString)' is not a real URL")
    exit(1)
}
guard let host = url.host else {
    print("ERROR: URL '\(url)' does not have a hostname which is required")
    exit(1)
}
guard url.scheme == "https" else {
    print("ERROR: URL '\(url)' is not https but that's required")
    exit(1)
}

let uri = url.absoluteURL.path == "" ? "/" : url.absoluteURL.path
let port = url.port ?? 443

let apnsConfig = APNSConfig.init(keyId: "9UC9ZLQ8YW", teamId: "ABBM6U9RM5", privateKeyPath: "/Users/kylebrowning/Downloads/key.p8", topic: "com.grasscove.Fern")
let apns = try APNSConnection.connect(host: host, port: port, apnsConfig: apnsConfig, on: group.next()).wait()

if verbose {
    print("* Connected to \(host) (\(apns.channel.remoteAddress!)")
}

let alert = Alert(title: "Hey There", subtitle: "Subtitle", body: "Body")
let aps = Aps(badge: 1, category: nil, alert: alert)
let res = try apns.send(deviceToken: "223a86bdd22598fb3a76ce12eafd590c86592484539f9b8526d0e683ad10cf4f", APNSRequest(aps: aps, custom: nil)).wait()
print("APNS response: \(res)")

try apns.close().wait()
try group.syncShutdownGracefully()
exit(0)
