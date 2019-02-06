// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-nio-http2-apns",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(name: "NIOAPNSExample", targets: ["NIOAPNSExample"]),
        .library(name: "OpenSSL",targets: ["OpenSSL"]),
        .library(name: "NIOAPNS", targets: ["NIOAPNS"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-nio", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio-http2", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/apple/swift-nio-ssl-support.git", from: "1.0.0"),
    ],
    targets: [
        .systemLibrary(
            name: "OpenSSL",
            pkgConfig: "openssl",
            providers: [
                .apt(["openssl libssl-dev"]),
                .brew(["openssl"]),
                ]
        ),
        .target(name: "NIOAPNSExample",
            dependencies: ["NIOAPNS", "NIOOpenSSL"]),
        .target(name: "NIOAPNS",
            dependencies: ["NIO", "NIOOpenSSL", "NIOHTTP1", "NIOHTTP2"]),
    ]
)
