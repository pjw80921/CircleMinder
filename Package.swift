// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CircleMinder",
    platforms: [
        .macOS(.v14) // Target macOS 14 (Sonoma) or newer for best SwiftUI support
    ],
    products: [
        .executable(name: "CircleMinder", targets: ["CircleMinder"])
    ],
    targets: [
        .executableTarget(
            name: "CircleMinder",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
