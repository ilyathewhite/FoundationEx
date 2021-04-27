// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoundationEx",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13)
    ],
    products: [
        .library(
            name: "FoundationEx",
            targets: ["FoundationEx"]
        )
    ],
    dependencies: [
        .package(name: "Tagged", url: "https://github.com/pointfreeco/swift-tagged.git", from: "0.5.0")
    ],
    targets: [
        .target(
            name: "FoundationEx",
            dependencies: ["Tagged"]
        )
    ]
)
