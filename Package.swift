// swift-tools-version: 6.0.3
import PackageDescription

let package = Package(
    name: "UmbraCore",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "UmbraCore",
            type: .dynamic,
            targets: ["UmbraCore", "Errors", "UmbraLogging"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
        .package(url: "https://github.com/apple/swift-syntax.git", exact: "509.0.2"),
        .package(url: "https://github.com/mw99/DataCompression.git", from: "3.8.0"),
    ],
    targets: [
        .target(
            name: "UmbraLogging",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: [
                .define("SWIFT_STRICT_CONCURRENCY"),
                .define("SWIFT_DEPLOYMENT_TARGET=15.0"),
                .unsafeFlags(["-target", "arm64-apple-macosx15.0"])
            ]
        ),
        .target(
            name: "Errors",
            dependencies: [
                "UmbraLogging",
            ],
            swiftSettings: [
                .define("SWIFT_STRICT_CONCURRENCY"),
                .define("SWIFT_DEPLOYMENT_TARGET=15.0"),
                .unsafeFlags(["-target", "arm64-apple-macosx15.0"])
            ]
        ),
        .target(
            name: "UmbraCore",
            dependencies: [
                "Errors",
                "UmbraLogging",
                .product(name: "DataCompression", package: "DataCompression"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ],
            exclude: [
                "Services/Development/README.md"
            ],
            swiftSettings: [
                .define("SWIFT_STRICT_CONCURRENCY"),
                .define("SWIFT_DEPLOYMENT_TARGET=15.0"),
                .unsafeFlags(["-target", "arm64-apple-macosx15.0"])
            ]
        ),
        .testTarget(
            name: "UmbraCoreTests",
            dependencies: ["UmbraCore"],
            swiftSettings: [
                .define("SWIFT_STRICT_CONCURRENCY"),
                .define("SWIFT_DEPLOYMENT_TARGET=15.0"),
                .unsafeFlags(["-target", "arm64-apple-macosx15.0"])
            ]
        ),
    ]
)
