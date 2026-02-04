// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftVerificarWCAGAlgs",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SwiftVerificarWCAGAlgs",
            targets: ["SwiftVerificarWCAGAlgs"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftVerificarWCAGAlgs"
        ),
        .testTarget(
            name: "SwiftVerificarWCAGAlgsTests",
            dependencies: ["SwiftVerificarWCAGAlgs"]
        ),
    ]
)
