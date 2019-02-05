import NIO
import NIOHTTP1
import NIOHTTP2
import NIOOpenSSL
import Foundation

let sslContext = try SSLContext(configuration: TLSConfiguration.forClient(applicationProtocols: ["h2"]))
let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
var verbose = true
var args = CommandLine.arguments.dropFirst(0)

func usage() {
    print("Usage: http2-client [-v] https://host:port/path")
    print()
    print("OPTIONS:")
    print("     -v: verbose operation (print response code, headers, etc.)")
}

if case .some(let arg) = args.dropFirst().first, arg.starts(with: "-") {
    switch arg {
    case "-v":
        verbose = true
        args = args.dropFirst()
    default:
        usage()
        exit(1)
    }
}

guard let url = URL.init(string: "https://api.development.push.apple.com/3/device/e4bcda99669b692a726b3912e8eca173bac937101c04b774fb053939e74c4f4d") else {
    usage()
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

let apns = try APNSConnection.connect(host: host, port: port, on: group.next()).wait()

if verbose {
    print("* Connected to \(host) (\(apns.channel.remoteAddress!)")
}

let alert = Alert(title: "Hey There", subtitle: "Subtitle", body: "Body")
let aps = Aps(badge: 1, category: nil, alert: alert)
let res = try apns.send(APNSRequest(aps: aps, custom: nil)).wait()
print("APNS response: \(res)")

try apns.close().wait()
try group.syncShutdownGracefully()
exit(0)
