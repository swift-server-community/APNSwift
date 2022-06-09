// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "apnswift",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
    ],
    products: [
        .executable(name: "APNSwiftExample", targets: ["APNSwiftExample"]),
        .library(name: "APNSwift", targets: ["APNSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.10.0")
    ],
    targets: [
        .target(name: "APNSwiftExample", dependencies: [
            .target(name: "APNSwift"),
        ]),
        .testTarget(name: "APNSwiftTests", dependencies: [
            .target(name: "APNSwift"),
        ]),
        .target(name: "APNSwift", dependencies: [
            .product(name: "JWTKit", package: "jwt-kit"),
            .product(name: "Logging", package: "swift-log"),
            .product(name: "AsyncHTTPClient", package: "async-http-client")
        ]),
    ]
)
