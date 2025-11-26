// swift-tools-version: 5.9
// Package.swift for App Store builds (NO Sparkle dependency)
import PackageDescription

let package = Package(
    name: "MCPServerManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MCPServerManager",
            targets: ["MCPServerManager"]
        )
    ],
    dependencies: [
        // NO Sparkle for App Store builds - Apple provides update mechanism
        .package(url: "https://github.com/LebJe/TOMLKit", from: "0.6.0")
    ],
    targets: [
        .executableTarget(
            name: "MCPServerManager",
            dependencies: [
                // NO Sparkle dependency
                .product(name: "TOMLKit", package: "TOMLKit")
            ],
            path: "MCPServerManager",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
