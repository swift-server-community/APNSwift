// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "apnswift",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
    ],
    products: [
        .executable(name: "APNSwiftExample", targets: ["APNSwiftExample"]),
        .library(name: "APNSwift", targets: ["APNSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0"..<"3.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.10.0"),
    ],
    targets: [
        .executableTarget(
            name: "APNSwiftExample",
            dependencies: [
                .target(name: "APNSwift")
            ]),
        .testTarget(
            name: "APNSwiftTests",
            dependencies: [
                .target(name: "APNSwift")
            ]),
        .target(
            name: "APNSwift",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ]),
    ]
)
