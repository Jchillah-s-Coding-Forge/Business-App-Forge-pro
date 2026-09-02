// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AppForgeKit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "AppForgeCore", targets: ["AppForgeCore"]),
        .library(name: "AppForgeDomain", targets: ["AppForgeDomain"]),
        .library(name: "AppForgeApplication", targets: ["AppForgeApplication"]),
        .library(name: "AppForgeDesignSystem", targets: ["AppForgeDesignSystem"])
    ],
    targets: [
        .target(name: "AppForgeCore"),
        .target(
            name: "AppForgeDomain",
            dependencies: ["AppForgeCore"]
        ),
        .target(
            name: "AppForgeApplication",
            dependencies: ["AppForgeCore", "AppForgeDomain"]
        ),
        .target(name: "AppForgeDesignSystem"),
        .testTarget(
            name: "AppForgeCoreTests",
            dependencies: ["AppForgeCore"]
        ),
        .testTarget(
            name: "AppForgeDomainTests",
            dependencies: ["AppForgeDomain"]
        ),
        .testTarget(
            name: "AppForgeApplicationTests",
            dependencies: ["AppForgeApplication", "AppForgeDomain"]
        )
    ]
)
