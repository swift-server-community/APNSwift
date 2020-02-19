// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "apnswift",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .executable(name: "APNSwiftExample", targets: ["APNSwiftExample"]),
        .library(name: "APNSwift", targets: ["APNSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.10.1")),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", .upToNextMajor(from: "2.4.0")),
        .package(url: "https://github.com/apple/swift-nio-http2.git", .upToNextMajor(from: "1.6.0")),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "1.0.0")
    ],
    targets: [
        .systemLibrary(
            name: "CAPNSOpenSSL",
            pkgConfig: "openssl",
            providers: [
                .apt(["openssl libssl-dev"]),
                .brew(["openssl@1.1"]),
            ]
        ),

        .target(name: "APNSwiftExample", dependencies: ["APNSwift"]),
        .target(name: "APNSwiftPemExample", dependencies: ["APNSwift"]),
        .testTarget(name: "APNSwiftJWTTests", dependencies: ["APNSwift"]),
        .testTarget(name: "APNSwiftTests", dependencies: ["APNSwift"]),
        .target(name: "APNSwift", dependencies: ["Logging",
                                                "NIO",
                                                "NIOSSL",
                                                "NIOHTTP1",
                                                "NIOHTTP2",
                                                "NIOFoundationCompat",
                                                "CAPNSOpenSSL",
                                                "NIOTLS",
                                                "Crypto"]),
    ]
)
