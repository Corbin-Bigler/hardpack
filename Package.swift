// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "hardpack",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "Hardpack", targets: ["Hardpack"])
    ],
    targets: [
        .target(name: "Hardpack"),
        .testTarget(
            name: "HardpackTest",
            dependencies: [
                "Hardpack",
            ]
        )
    ]
)
