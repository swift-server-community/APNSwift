// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "apnswift",
    products: [
        .executable(name: "APNSwiftExample", targets: ["APNSwiftExample"]),
        .library(name: "APNSwift", targets: ["APNSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.0.0"),
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
        .testTarget(name: "APNSwiftJWTTests", dependencies: ["APNSwift"]),
        .testTarget(name: "APNSwiftTests", dependencies: ["APNSwift"]),
        .target(name: "APNSwift", dependencies: ["NIO",
                                                "NIOSSL",
                                                "NIOHTTP1",
                                                "NIOHTTP2",
                                                "NIOFoundationCompat",
                                                "CAPNSOpenSSL"]),
    ]
)
