// swift-tools-version: 6.0
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
            targets: ["UmbraCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/mw99/DataCompression.git", from: "3.8.0"),
        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.54.0"),
        .package(url: "https://github.com/apple/swift-format.git", branch: "main")
    ],
    targets: [
        .target(
            name: "UmbraCore",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "DataCompression", package: "DataCompression")
            ],
            exclude: ["Services/Development/README.md"],
            swiftSettings: [
                .define("SWIFT_STRICT_CONCURRENCY"),
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableExperimentalFeature("StrictConcurrency"),
                .unsafeFlags(["-swift-version", "6.0.3"])
            ]
        ),
        .testTarget(
            name: "UmbraCoreTests",
            dependencies: ["UmbraCore"]
        )
    ]
)
