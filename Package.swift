// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-compositional-init",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
    ],
    products: [
        .library(
            name: "CompositionalInit",
            targets: ["CompositionalInit"]
        ),
    ],
    targets: [
        .target(
            name: "CompositionalInit"
        ),
        .testTarget(
            name: "CompositionalInitTests",
            dependencies: ["CompositionalInit"]
        ),
    ]
)
