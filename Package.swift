// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "nio-apns",
    products: [
        .executable(name: "NIOAPNSExample", targets: ["NIOAPNSExample"]),
        .library(name: "NIOAPNS", targets: ["NIOAPNS"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-nio", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio-http2", .upToNextMinor(from: "0.1.0")),
    ],
    targets: [
        .systemLibrary(
            name: "CAPNSOpenSSL",
            pkgConfig: "openssl",
            providers: [
                .apt(["openssl libssl-dev"]),
                .brew(["openssl"]),
            ]
        ),
        .target(name: "NIOAPNSExample", dependencies: ["NIOAPNS", "NIOOpenSSL"]),
        .target(name: "NIOAPNS", dependencies: ["CAPNSOpenSSL", "NIO", "NIOOpenSSL", "NIOHTTP1", "NIOHTTP2"]),
    ]
)
