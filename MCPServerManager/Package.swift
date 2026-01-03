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
    ],
    targets: [
        .executableTarget(
            name: "MCPServerManager",
            dependencies: [
                // NO Sparkle dependency
            ],
            path: "MCPServerManager",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
