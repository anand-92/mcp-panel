// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "MCPServerManager",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(
            name: "MCPServerManager",
            targets: ["MCPServerManager"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.5")
    ],
    targets: [
        .executableTarget(
            name: "MCPServerManager",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "MCPServerManager",
            exclude: ["Info.plist", "MCPServerManager.entitlements"],
            resources: [
                .process("Resources"),
                .process("Assets.xcassets")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
