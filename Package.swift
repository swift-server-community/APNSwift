// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "apnswift",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .executable(name: "APNSwiftExample", targets: ["APNSwiftExample"]),
        .library(name: "APNSwiftCore", targets: ["APNSwiftCore"]),
        .library(name: "APNSwiftAHC", targets: ["APNSwiftAHC"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0"..<"3.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.10.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "APNSwiftExample",
            dependencies: [
                .target(name: "APNSwiftCore"),
                .target(name: "APNSwiftAHC")
            ]),
        .testTarget(
            name: "APNSwiftTests",
            dependencies: [
                .target(name: "APNSwiftCore"),
                .target(name: "APNSwiftAHC")
            ]),
        .target(
            name: "APNSwiftCore",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Crypto", package: "swift-crypto"),
            ]
        ),
        .target(
            name: "APNSwiftAHC",
            dependencies: [
                .target(name: "APNSwiftCore"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ]
        ),
    ]
)
