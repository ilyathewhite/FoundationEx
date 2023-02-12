// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoundationEx",
    platforms: [
        .macOS(.v11), .iOS(.v14), .tvOS(.v13)
    ],
    products: [
        .library(
            name: "FoundationEx",
            targets: ["FoundationEx"]
        )
    ],
    dependencies: [
        .package(name: "swift-tagged", url: "https://github.com/pointfreeco/swift-tagged.git", from: "0.5.0")
    ],
    targets: [
        .target(
            name: "FoundationEx",
            dependencies: [.product(name: "Tagged", package: "swift-tagged")],
            swiftSettings: [.unsafeFlags([
                "-Xfrontend",
                "-warn-long-function-bodies=100",
                "-Xfrontend",
                "-warn-long-expression-type-checking=100"
            ])]
        )
    ]
)
