// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "apnswift",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "APNSwiftExample", targets: ["APNSwiftExample"]),
        .library(name: "APNSwift", targets: ["APNSwift"]),
        /* This target is used only for symbol mangling. It's added and removed automatically because it emits build warnings. MANGLE_START
        .library(name: "CAPNSwiftBoringSSL", type: .static, targets: ["CAPNSwiftBoringSSL"]),
        MANGLE_END */
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.10.1")),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", .upToNextMajor(from: "2.4.0")),
        .package(url: "https://github.com/apple/swift-nio-http2.git", .upToNextMajor(from: "1.6.0")),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "1.0.0")
    ],
    targets: [
        .target(name: "CAPNSwiftBoringSSL"),
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
                                                "CAPNSwiftBoringSSL",
                                                "NIOTLS",
                                                "Crypto"]),
    ],
    cxxLanguageStandard: .cxx11
)
