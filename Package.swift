// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "nio-apns",
    products: [
        .executable(name: "NIOAPNSExample", targets: ["NIOAPNSExample"]),
        .library(name: "NIOAPNSJWT", targets: ["NIOAPNSJWT"]),
        .library(name: "NIOAPNS", targets: ["NIOAPNS"]),        
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

        .target(name: "NIOAPNSExample", dependencies: ["NIOAPNS"]),

        .target(name: "NIOAPNSJWT", dependencies:["CAPNSOpenSSL"]),

        .testTarget(name: "NIOAPNSJWTTests", dependencies: ["NIOAPNSJWT"]),

        .target(name: "NIOAPNS", dependencies: ["NIOAPNSJWT",
                                                "NIO",
                                                "NIOSSL",
                                                "NIOHTTP1",
                                                "NIOHTTP2"]),

        .testTarget(name: "NIOAPNSTests", dependencies: ["NIOAPNS"]),
    ]
)
