// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "apnswift",
    products: [
        .executable(name: "APNSwiftExample", targets: ["APNSwiftExample"]),
        .library(name: "APNSwift", targets: ["APNSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.10.1")),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", .upToNextMajor(from: "2.4.0")),
        .package(url: "https://github.com/apple/swift-nio-http2.git", .upToNextMajor(from: "1.6.0")),
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

        .target(name: "APNSwiftExample", dependencies: ["APNSwift"]),
        .target(name: "APNSwiftPemExample", dependencies: ["APNSwift"]),
        .testTarget(name: "APNSwiftJWTTests", dependencies: ["APNSwift"]),
        .testTarget(name: "APNSwiftTests", dependencies: ["APNSwift"]),
        .target(name: "APNSwift", dependencies: ["NIO",
                                                "NIOSSL",
                                                "NIOHTTP1",
                                                "NIOHTTP2",
                                                "NIOFoundationCompat",
                                                "CAPNSOpenSSL",
                                                "NIOTLS"]),
    ]
)
