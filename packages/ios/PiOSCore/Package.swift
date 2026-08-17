// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PiOSCore",
    products: [
        .library(
            name: "PiOSCore",
            targets: ["PiOSCore"]
        )
    ],
    targets: [
        .target(name: "PiOSCore"),
        .testTarget(
            name: "PiOSCoreTests",
            dependencies: ["PiOSCore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
